package com.oklifor.api.service;

import com.oklifor.api.config.OkliforProperties;
import com.oklifor.api.domain.ChatMessageKind;
import com.oklifor.api.web.dto.ChatMediaUploadResponse;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.data.redis.core.StringRedisTemplate;
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
import java.util.concurrent.TimeUnit;

@Service
public class ChatMediaService {

    private static final Set<String> IMAGE_CT = Set.of("image/jpeg", "image/png", "image/webp");
    private static final Set<String> VIDEO_CT = Set.of("video/mp4", "video/webm", "video/quicktime");
    private static final Set<String> AUDIO_CT = Set.of("audio/mpeg", "audio/mp4", "audio/aac", "audio/wav", "audio/webm", "audio/ogg");
    private static final String RESOLVE_CACHE_PREFIX = "okl:chat-media:resolve:";

    private final OkliforProperties props;
    private final StringRedisTemplate redis;

    public ChatMediaService(
            OkliforProperties props,
            ObjectProvider<StringRedisTemplate> redisProvider) {
        this.props = props;
        this.redis = redisProvider.getIfAvailable();
    }

    public ChatMediaUploadResponse upload(String threadId, MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "fichier_vide");
        }
        if (threadId == null || threadId.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "thread_invalide");
        }
        String ct = normalizeContentType(file);
        ChatMessageKind kind = kindFromContentType(ct);
        String ext = extensionFor(kind, file.getOriginalFilename());
        String safeThreadId = threadId.replaceAll("[^a-zA-Z0-9\\-]", "");
        String filename = kind.name().toLowerCase(Locale.ROOT) + "_" + Instant.now().toEpochMilli() + ext;
        try {
            Path base = Path.of(props.getChatMedia().getUploadDir()).resolve(safeThreadId).normalize();
            Files.createDirectories(base);
            Path target = base.resolve(filename).normalize();
            if (!target.startsWith(base)) {
                throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "chemin_invalide");
            }
            try (InputStream in = file.getInputStream()) {
                Files.copy(in, target, StandardCopyOption.REPLACE_EXISTING);
            }
            long exp = Instant.now().getEpochSecond() + props.getChatMedia().getSignedUrlTtlSeconds();
            String sig = sign(safeThreadId + "|" + filename + "|" + exp);
            String signedUrl =
                    "/api/v1/public/chat-media/"
                            + URLEncoder.encode(safeThreadId, StandardCharsets.UTF_8)
                            + "/"
                            + URLEncoder.encode(filename, StandardCharsets.UTF_8)
                            + "?exp="
                            + exp
                            + "&sig="
                            + sig;
            return new ChatMediaUploadResponse(kind, signedUrl);
        } catch (ResponseStatusException ex) {
            throw ex;
        } catch (Exception e) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "upload_chat_media_echec");
        }
    }

    public Path resolveSigned(String threadId, String filename, long exp, String sig) {
        long now = Instant.now().getEpochSecond();
        if (exp < now) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "url_expiree");
        }
        String cacheKey = cacheKeyForResolve(threadId, filename, exp, sig);
        String cachedPath = readResolveCache(cacheKey);
        if (cachedPath != null && !cachedPath.isBlank()) {
            Path cached = Path.of(cachedPath).normalize();
            if (Files.isRegularFile(cached)) {
                return cached;
            }
        }
        String expected = sign(threadId + "|" + filename + "|" + exp);
        if (!expected.equalsIgnoreCase(sig)) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "signature_invalide");
        }
        Path base = Path.of(props.getChatMedia().getUploadDir()).resolve(threadId).normalize();
        Path file = base.resolve(filename).normalize();
        if (!file.startsWith(base) || !Files.isRegularFile(file)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "fichier_introuvable");
        }
        writeResolveCache(cacheKey, file, exp, now);
        return file;
    }

    /**
     * Regénère une URL signée valide à partir d’une URL stockée en base (souvent expirée).
     * Extrait threadId + nom de fichier du chemin ; ne fait confiance qu’aux fichiers présents sur disque.
     */
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
            final String marker = "/api/v1/public/chat-media/";
            int idx = pathPart.indexOf(marker);
            if (idx < 0) {
                return stored;
            }
            String tail = pathPart.substring(idx + marker.length());
            int slash = tail.indexOf('/');
            if (slash <= 0 || slash >= tail.length() - 1) {
                return stored;
            }
            String rawThread =
                    URLDecoder.decode(tail.substring(0, slash), StandardCharsets.UTF_8);
            String rawFile =
                    URLDecoder.decode(tail.substring(slash + 1), StandardCharsets.UTF_8);
            String safeThread = rawThread.replaceAll("[^a-zA-Z0-9\\-]", "");
            if (safeThread.isEmpty() || rawFile.isBlank()) {
                return stored;
            }
            Path base = Path.of(props.getChatMedia().getUploadDir()).resolve(safeThread).normalize();
            Path file = base.resolve(rawFile).normalize();
            if (!file.startsWith(base) || !Files.isRegularFile(file)) {
                return stored;
            }
            long exp = Instant.now().getEpochSecond() + props.getChatMedia().getSignedUrlTtlSeconds();
            String sig = sign(safeThread + "|" + rawFile + "|" + exp);
            return "/api/v1/public/chat-media/"
                    + URLEncoder.encode(safeThread, StandardCharsets.UTF_8)
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

    private String cacheKeyForResolve(String threadId, String filename, long exp, String sig) {
        return RESOLVE_CACHE_PREFIX + threadId + "|" + filename + "|" + exp + "|" + sig;
    }

    private String readResolveCache(String cacheKey) {
        if (redis == null) return null;
        try {
            return redis.opsForValue().get(cacheKey);
        } catch (Exception ignored) {
            return null;
        }
    }

    private void writeResolveCache(String cacheKey, Path file, long exp, long now) {
        if (redis == null) return;
        try {
            long cfg = Math.max(1, props.getChatMedia().getResolveCacheSeconds());
            long untilExpiry = Math.max(1, exp - now);
            long ttlSec = Math.min(cfg, untilExpiry);
            redis.opsForValue().set(cacheKey, file.toString(), ttlSec, TimeUnit.SECONDS);
        } catch (Exception ignored) {
            // Ne jamais bloquer la lecture média si Redis est indisponible.
        }
    }

    private ChatMessageKind kindFromContentType(String ct) {
        if (IMAGE_CT.contains(ct)) return ChatMessageKind.IMAGE;
        if (VIDEO_CT.contains(ct)) return ChatMessageKind.VIDEO;
        if (AUDIO_CT.contains(ct)) return ChatMessageKind.VOICE;
        throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "type_media_non_supporte");
    }

    private static String normalizeContentType(MultipartFile file) {
        String raw = file.getContentType();
        if (raw == null) return "";
        return raw.toLowerCase(Locale.ROOT).trim();
    }

    private static String extensionFor(ChatMessageKind kind, String filename) {
        String n = filename != null ? filename.toLowerCase(Locale.ROOT) : "";
        return switch (kind) {
            case IMAGE -> n.endsWith(".png") ? ".png" : n.endsWith(".webp") ? ".webp" : ".jpg";
            case VIDEO -> n.endsWith(".webm") ? ".webm" : n.endsWith(".mov") ? ".mov" : ".mp4";
            case VOICE -> n.endsWith(".wav") ? ".wav" : n.endsWith(".ogg") ? ".ogg" : n.endsWith(".webm") ? ".webm" : ".m4a";
            default -> ".bin";
        };
    }

    private String sign(String payload) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(props.getJwt().getSecret().getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
            byte[] out = mac.doFinal(payload.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(out);
        } catch (Exception e) {
            throw new IllegalStateException("signature_impossible");
        }
    }
}
