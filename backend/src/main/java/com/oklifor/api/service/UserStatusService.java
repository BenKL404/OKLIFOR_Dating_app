package com.oklifor.api.service;

import com.oklifor.api.domain.UserStatus;
import com.oklifor.api.domain.UserStatusKind;
import com.oklifor.api.repository.UserStatusRepository;
import com.oklifor.api.web.dto.MyUserStatusResponse;
import com.oklifor.api.web.dto.PublishTextStatusRequest;
import com.oklifor.api.web.dto.StatusMediaUploadResponse;
import com.oklifor.api.web.dto.StatusPreviewResponse;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Optional;

@Service
public class UserStatusService {

    private static final long STATUS_TTL_HOURS = 24;

    private final UserStatusRepository repo;
    private final StatusMediaService statusMediaService;

    public UserStatusService(UserStatusRepository repo, StatusMediaService statusMediaService) {
        this.repo = repo;
        this.statusMediaService = statusMediaService;
    }

    public Optional<MyUserStatusResponse> getMyStatus(String userId) {
        return loadValid(userId).map(this::toMyResponse);
    }

    public MyUserStatusResponse publishText(String userId, PublishTextStatusRequest req) {
        String text = req.text() != null ? req.text().trim() : "";
        if (text.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "texte_vide");
        }
        Optional<UserStatus> existingOpt = repo.findByUserId(userId);
        existingOpt.ifPresent(this::deleteOldMediaIfAny);

        UserStatus s = existingOpt.orElseGet(UserStatus::new);
        s.setUserId(userId);
        s.setKind(UserStatusKind.TEXT);
        s.setText(text);
        s.setBackgroundColorHex(normalizeHex(req.backgroundColorHex()));
        s.setCaption(null);
        s.setMediaFilename(null);
        s.setExpiresAt(Instant.now().plus(STATUS_TTL_HOURS, ChronoUnit.HOURS));
        s = repo.save(s);
        return toMyResponse(s);
    }

    public MyUserStatusResponse publishMedia(String userId, MultipartFile file, String caption) {
        Optional<UserStatus> existingOpt = repo.findByUserId(userId);
        existingOpt.ifPresent(this::deleteOldMediaIfAny);

        StatusMediaUploadResponse up = statusMediaService.upload(userId, file);
        UserStatus s = existingOpt.orElseGet(UserStatus::new);
        s.setUserId(userId);
        s.setKind(up.mediaKind());
        s.setText(null);
        s.setBackgroundColorHex(null);
        s.setCaption(caption != null && !caption.isBlank() ? caption.trim() : null);
        String fn = extractFilenameFromSignedPath(up.signedUrl());
        s.setMediaFilename(fn);
        s.setExpiresAt(Instant.now().plus(STATUS_TTL_HOURS, ChronoUnit.HOURS));
        s = repo.save(s);
        return toMyResponse(s);
    }

    public void clear(String userId) {
        repo.findByUserId(userId).ifPresent(this::deleteOldMediaIfAny);
        repo.deleteByUserId(userId);
    }

    public List<StatusPreviewResponse> previewsFor(String viewerUserId, List<String> userIds) {
        if (userIds == null || userIds.isEmpty()) {
            return List.of();
        }
        LinkedHashSet<String> unique = new LinkedHashSet<>();
        for (String uid : userIds) {
            if (uid != null && !uid.isBlank()) {
                unique.add(uid.trim());
            }
        }
        List<StatusPreviewResponse> out = new ArrayList<>();
        for (String uid : unique) {
            if (uid.equals(viewerUserId)) {
                continue;
            }
            Optional<UserStatus> opt = loadValid(uid);
            if (opt.isEmpty()) {
                out.add(new StatusPreviewResponse(uid, false, null, null, null, null, null, null));
            } else {
                UserStatus s = opt.get();
                out.add(toPreview(s));
            }
        }
        return out;
    }

    private Optional<UserStatus> loadValid(String userId) {
        Optional<UserStatus> opt = repo.findByUserId(userId);
        if (opt.isEmpty()) {
            return Optional.empty();
        }
        UserStatus s = opt.get();
        if (s.getExpiresAt() != null && Instant.now().isAfter(s.getExpiresAt())) {
            deleteOldMediaIfAny(s);
            repo.deleteByUserId(userId);
            return Optional.empty();
        }
        return Optional.of(s);
    }

    private void deleteOldMediaIfAny(UserStatus s) {
        if (s.getKind() != UserStatusKind.TEXT
                && s.getMediaFilename() != null
                && !s.getMediaFilename().isBlank()
                && s.getUserId() != null) {
            statusMediaService.deleteMediaFile(s.getUserId(), s.getMediaFilename());
        }
    }

    private MyUserStatusResponse toMyResponse(UserStatus s) {
        String mediaUrl = null;
        if (s.getKind() != UserStatusKind.TEXT && s.getMediaFilename() != null) {
            mediaUrl = refreshMediaUrl(s.getUserId(), s.getMediaFilename());
        }
        return new MyUserStatusResponse(
                s.getKind(),
                s.getText(),
                s.getBackgroundColorHex(),
                s.getCaption(),
                mediaUrl,
                s.getCreatedAt(),
                s.getExpiresAt());
    }

    private StatusPreviewResponse toPreview(UserStatus s) {
        String mediaUrl = null;
        if (s.getKind() != UserStatusKind.TEXT && s.getMediaFilename() != null) {
            mediaUrl = refreshMediaUrl(s.getUserId(), s.getMediaFilename());
        }
        return new StatusPreviewResponse(
                s.getUserId(),
                true,
                s.getKind(),
                s.getText(),
                s.getBackgroundColorHex(),
                s.getCaption(),
                mediaUrl,
                s.getCreatedAt());
    }

    private String refreshMediaUrl(String userId, String filename) {
        String path =
                "/api/v1/public/status-media/"
                        + java.net.URLEncoder.encode(
                                userId.replaceAll("[^a-zA-Z0-9\\-]", ""), java.nio.charset.StandardCharsets.UTF_8)
                        + "/"
                        + java.net.URLEncoder.encode(filename, java.nio.charset.StandardCharsets.UTF_8);
        return statusMediaService.refreshSignedMediaUrl(path);
    }

    private static String extractFilenameFromSignedPath(String signedUrl) {
        if (signedUrl == null || signedUrl.isBlank()) {
            return "";
        }
        String path = signedUrl;
        int q = path.indexOf('?');
        if (q >= 0) {
            path = path.substring(0, q);
        }
        int slash = path.lastIndexOf('/');
        if (slash < 0 || slash >= path.length() - 1) {
            return "";
        }
        try {
            return java.net.URLDecoder.decode(path.substring(slash + 1), java.nio.charset.StandardCharsets.UTF_8);
        } catch (Exception e) {
            return path.substring(slash + 1);
        }
    }

    private static String normalizeHex(String raw) {
        if (raw == null || raw.isBlank()) {
            return null;
        }
        String t = raw.trim();
        if (!t.startsWith("#")) {
            t = "#" + t;
        }
        if (t.length() != 7 && t.length() != 9) {
            return t;
        }
        return t;
    }
}