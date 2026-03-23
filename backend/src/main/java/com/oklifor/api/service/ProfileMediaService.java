package com.oklifor.api.service;

import com.oklifor.api.config.OkliforProperties;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.time.Instant;
import java.util.Locale;
import java.util.Set;
import java.util.regex.Pattern;

@Service
public class ProfileMediaService {

    private static final Pattern SAFE_NAME =
            Pattern.compile("^(avatar|cover)_\\d+\\.(?i)(jpg|jpeg|png|webp)$");
    private static final Pattern USER_ID = Pattern.compile("^[a-fA-F0-9\\-]{36}$");

    private static final Set<String> ALLOWED_CT =
            Set.of("image/jpeg", "image/png", "image/webp");

    private final OkliforProperties props;

    public ProfileMediaService(OkliforProperties props) {
        this.props = props;
    }

    public boolean isSafePublicFile(String userId, String filename) {
        return USER_ID.matcher(userId).matches() && SAFE_NAME.matcher(filename).matches();
    }

    public Path resolveExistingFile(String userId, String filename) {
        if (!isSafePublicFile(userId, filename)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "fichier_invalide");
        }
        Path base = Path.of(props.getProfileMedia().getUploadDir()).resolve(userId).normalize();
        Path file = base.resolve(filename).normalize();
        if (!file.startsWith(base)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "fichier_introuvable");
        }
        if (!Files.isRegularFile(file)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "fichier_introuvable");
        }
        return file;
    }

    /**
     * Enregistre une image profil ; retourne le chemin URL public (relatif, sans host), ex.
     * {@code /api/v1/public/profile-media/{userId}/avatar_123.jpg}.
     */
    public String storeProfileImage(String userId, MultipartFile file, String kind)
            throws IOException {
        if (file == null || file.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "fichier_vide");
        }
        if (!USER_ID.matcher(userId).matches()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "utilisateur_invalide");
        }
        if (!"avatar".equals(kind) && !"cover".equals(kind)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "type_media_invalide");
        }
        String ct = normalizeContentType(file);
        if (ct == null || !ALLOWED_CT.contains(ct)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "type_image_non_supporte");
        }

        String ext = extension(file, ".jpg");
        ext = normalizeImageExt(ext);
        long ts = Instant.now().getEpochSecond();
        String filename = kind + "_" + ts + ext;

        Path userDir = Path.of(props.getProfileMedia().getUploadDir()).resolve(userId);
        Files.createDirectories(userDir);
        Path target = userDir.resolve(filename).normalize();
        if (!target.startsWith(userDir.normalize())) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "chemin_invalide");
        }

        try (InputStream in = file.getInputStream()) {
            Files.copy(in, target, StandardCopyOption.REPLACE_EXISTING);
        }

        return "/api/v1/public/profile-media/" + userId + "/" + filename;
    }

    private static String normalizeContentType(MultipartFile file) {
        String raw = file.getContentType();
        if (raw != null) {
            raw = raw.toLowerCase(Locale.ROOT).trim();
            if (ALLOWED_CT.contains(raw)) {
                return raw;
            }
            if (raw.contains("octet-stream") || raw.equals("application/binary")) {
                return inferFromFilename(file.getOriginalFilename());
            }
        }
        return inferFromFilename(file.getOriginalFilename());
    }

    private static String inferFromFilename(String name) {
        if (name == null) {
            return null;
        }
        String n = name.toLowerCase(Locale.ROOT);
        if (n.endsWith(".png")) {
            return "image/png";
        }
        if (n.endsWith(".webp")) {
            return "image/webp";
        }
        if (n.endsWith(".jpg") || n.endsWith(".jpeg")) {
            return "image/jpeg";
        }
        return null;
    }

    private static String normalizeImageExt(String ext) {
        String e = ext.toLowerCase(Locale.ROOT);
        if (e.endsWith("jpeg") || e.endsWith("jpg")) {
            return ".jpg";
        }
        if (e.endsWith("png")) {
            return ".png";
        }
        if (e.endsWith("webp")) {
            return ".webp";
        }
        return ".jpg";
    }

    private static String extension(MultipartFile f, String fallback) {
        String n = f.getOriginalFilename();
        if (n == null || !n.contains(".")) {
            return fallback;
        }
        return n.substring(n.lastIndexOf('.'));
    }
}
