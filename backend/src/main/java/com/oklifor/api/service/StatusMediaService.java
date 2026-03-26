package com.oklifor.api.service;

import com.oklifor.api.config.OkliforProperties;
import com.oklifor.api.domain.UserStatusKind;
import com.oklifor.api.web.dto.StatusMediaUploadResponse;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.io.InputStream;
import java.net.URI;
import java.net.URLDecoder;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.time.Instant;
import java.util.HexFormat;
import java.util.Locale;
import java.util.Set;

@Service
public class StatusMediaService {

    private static final Set<String> IMAGE_CT = Set.of("image/jpeg", "image/png", "image/webp");
    private static final Set<String> VIDEO_CT = Set.of("video/mp4", "video/webm", "video/quicktime");

    private final OkliforProperties props;

    public StatusMediaService(OkliforProperties props) {
        this.props = props;
    }

    public StatusMediaUploadResponse upload(String userId, MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "fichier_vide");
        }
        if (userId == null || userId.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "utilisateur_invalide");
        }
        String ct = normalizeContentType(file);
        if (ct.isEmpty() || "application/octet-stream".equals(ct)) {
            ct = inferFromFilename(file.getOriginalFilename());
        }
        UserStatusKind kind = kindFromContentType(ct);
        String ext = extensionFor(kind, file.getOriginalFilename());
        String safeUser = userId.replaceAll("[^a-zA-Z0-9\\-]", "");
        if (safeUser.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "utilisateur_invalide");
        }
        String filename = "status_" + Instant.now().toEpochMilli() + ext;
        try {
            Path base = Path.of(props.getStatusMedia().getUploadDir()).resolve(safeUser).normalize();
            Files.createDirectories(base);
            Path target = base.resolve(filename).normalize();
            if (!target.startsWith(base)) {
                throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "chemin_invalide");
            }
            try (InputStream in = file.getInputStream()) {
                Files.copy(in, target, StandardCopyOption.REPLACE_EXISTING);
            }
            long exp = Instant.now().getEpochSecond() + props.getStatusMedia().getSignedUrlTtlSeconds();
            String sig = sign(safeUser + "|" + filename + "|" + exp);
            String signedUrl =
                    "/api/v1/public/status-media/"
                            + URLEncoder.encode(safeUser, StandardCharsets.UTF_8)
                            + "/"
                            + URLEncoder.encode(filename, StandardCharsets.UTF_8)
                            + "?exp="
                            + exp
                            + "&sig="
                            + sig;
            return new StatusMediaUploadResponse(kind, signedUrl);
        } catch (ResponseStatusException ex) {
            throw ex;
        } catch (Exception e) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "upload_status_media_echec");
        }
    }

    public Path resolveSigned(String userId, String filename, long exp, String sig) {
        long now = Instant.now().getEpochSecond();
        if (exp < now) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "url_expiree");
        }
        String expected = sign(userId + "|" + filename + "|" + exp);
        if (!expected.equalsIgnoreCase(sig)) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "signature_invalide");
        }
        Path base = Path.of(props.getStatusMedia().getUploadDir()).resolve(userId).normalize();
        Path file = base.resolve(filename).normalize();
        if (!file.startsWith(base) || !Files.isRegularFile(file)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "fichier_introuvable");
        }
        return file;
    }

    public String refreshSignedMediaUrl(String stored) {
        if (stored == null || stored.isBlank()) {
            return stored;
        }
        String s = stored.trim();
        try {
            String pathPart = s;
            int q = s.indexOf('?');
            if (q >= 0) {
                pathPart = s.substring(0, q);
            }
            if (pathPart.startsWith("http://") || pathPart.startsWith("https://")) {
                URI u = URI.create(pathPart);
                pathPart = u.getPath();
                if (pathPart == null) {
                    return stored;
                }
            }
            final String marker = "/api/v1/public/status-media/";
            int idx = pathPart.indexOf(marker);
            if (idx < 0) {
                return stored;
            }
            String tail = pathPart.substring(idx + marker.length());
            int slash = tail.indexOf('/');
            if (slash <= 0 || slash >= tail.length() - 1) {
                return stored;
            }
            String rawUser = URLDecoder.decode(tail.substring(0, slash), StandardCharsets.UTF_8);
            String rawFile = URLDecoder.decode(tail.substring(slash + 1), StandardCharsets.UTF_8);
            String safeUser = rawUser.replaceAll("[^a-zA-Z0-9\\-]", "");
            if (safeUser.isEmpty() || rawFile.isBlank()) {
                return stored;
            }
            Path base = Path.of(props.getStatusMedia().getUploadDir()).resolve(safeUser).normalize();
            Path f = base.resolve(rawFile).normalize();
            if (!f.startsWith(base) || !Files.isRegularFile(f)) {
                return stored;
            }
            long exp = Instant.now().getEpochSecond() + props.getStatusMedia().getSignedUrlTtlSeconds();
            String sig = sign(safeUser + "|" + rawFile + "|" + exp);
            return "/api/v1/public/status-media/"
                    + URLEncoder.encode(safeUser, StandardCharsets.UTF_8)
                    + "/"
                    + URLEncoder.encode(rawFile, StandardCharsets.UTF_8)
                    + "?exp="
                    + exp
                    + "&sig="
                    + sig;
        } catch (Exception e) {
            return stored;
        }
    }

    public void deleteMediaFile(String userId, String filename) {
        if (userId == null || filename == null || filename.isBlank()) {
            return;
        }
        try {
            String safeUser = userId.replaceAll("[^a-zA-Z0-9\\-]", "");
            Path base = Path.of(props.getStatusMedia().getUploadDir()).resolve(safeUser).normalize();
            Path f = base.resolve(filename).normalize();
            if (f.startsWith(base) && Files.isRegularFile(f)) {
                Files.deleteIfExists(f);
            }
        } catch (Exception ignored) {
        }
    }

    private UserStatusKind kindFromContentType(String ct) {
        if (IMAGE_CT.contains(ct)) {
            return UserStatusKind.IMAGE;
        }
        if (VIDEO_CT.contains(ct)) {
            return UserStatusKind.VIDEO;
        }
        throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "type_media_non_supporte");
    }

    private static String inferFromFilename(String originalFilename) {
        if (originalFilename == null || originalFilename.isBlank()) {
            return "";
        }
        String n = originalFilename.toLowerCase(Locale.ROOT);
        if (n.endsWith(".png")) {
            return "image/png";
        }
        if (n.endsWith(".webp")) {
            return "image/webp";
        }
        if (n.endsWith(".jpg") || n.endsWith(".jpeg")) {
            return "image/jpeg";
        }
        if (n.endsWith(".webm")) {
            return "video/webm";
        }
        if (n.endsWith(".mov")) {
            return "video/quicktime";
        }
        if (n.endsWith(".mp4")) {
            return "video/mp4";
        }
        return "";
    }

    private static String extensionFor(UserStatusKind kind, String filename) {
        String n = filename != null ? filename.toLowerCase(Locale.ROOT) : "";
        return switch (kind) {
            case IMAGE -> n.endsWith(".png") ? ".png" : n.endsWith(".webp") ? ".webp" : ".jpg";
            case VIDEO -> n.endsWith(".webm") ? ".webm" : n.endsWith(".mov") ? ".mov" : ".mp4";
            default -> ".bin";
        };
    }

    private static String normalizeContentType(MultipartFile file) {
        String raw = file.getContentType();
        if (raw == null) {
            return "";
        }
        return raw.toLowerCase(Locale.ROOT).trim();
    }

    private String sign(String payload) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(
                    new SecretKeySpec(
                            props.getJwt().getSecret().getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
            byte[] out = mac.doFinal(payload.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(out);
        } catch (Exception e) {
            throw new IllegalStateException("signature_impossible");
        }
    }
}
