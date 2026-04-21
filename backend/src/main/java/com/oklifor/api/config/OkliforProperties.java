package com.oklifor.api.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Getter
@Setter
@Component
@ConfigurationProperties(prefix = "oklifor")
public class OkliforProperties {

    private final Jwt jwt = new Jwt();
    private final Auth auth = new Auth();
    private final FirebaseAdmin firebase = new FirebaseAdmin();
    private final Verification verification = new Verification();
    private final ProfileMedia profileMedia = new ProfileMedia();
    private final ChatMedia chatMedia = new ChatMedia();
    private final StatusMedia statusMedia = new StatusMedia();
    private final Storage storage = new Storage();

    @Getter
    @Setter
    public static class Jwt {
        private String secret = "dev-change-me";
        private long accessTokenMinutes = 60;
        private long refreshTokenDays = 30;
    }

    @Getter
    @Setter
    public static class Auth {
        private boolean otpDevMode = true;
    }

    @Getter
    @Setter
    public static class FirebaseAdmin {
        /** Si vrai, l’Admin SDK Firebase est initialisé au démarrage. */
        private boolean enabled = false;

        /** Chemin optionnel vers le JSON compte de service (sinon {@code GOOGLE_APPLICATION_CREDENTIALS}). */
        private String credentialsJsonPath = "";
    }

    @Getter
    @Setter
    public static class Verification {
        /** Dossier racine pour les fichiers selfie + pièce (sous-dossiers par userId). */
        private String uploadDir = "data/verification-uploads";

        /**
         * Si vrai, {@code POST /api/v1/me/verification/simulate-approve} peut valider l’identité (démo /
         * recette uniquement).
         */
        private boolean demoApproveEnabled = true;
    }

    @Getter
    @Setter
    public static class ProfileMedia {
        /** Dossier racine : sous-dossiers par {@code userId}. */
        private String uploadDir = "data/profile-media";
    }

    @Getter
    @Setter
    public static class ChatMedia {
        /** Dossier racine : sous-dossiers par threadId. */
        private String uploadDir = "data/chat-media";
        /** Durée de validité de l'URL signée en secondes. */
        private long signedUrlTtlSeconds = 3600;
        /** TTL du cache Redis pour la résolution d'URL signée. */
        private long resolveCacheSeconds = 20;
    }

    @Getter
    @Setter
    public static class StatusMedia {
        private String uploadDir = "data/status-media";
        private long signedUrlTtlSeconds = 3600;
    }

    @Getter
    @Setter
    public static class Storage {
        private String endpoint = "http://localhost:9000";
        private String accessKey = "minioadmin";
        private String secretKey = "minioadmin";
        private String bucketChat = "oklifor-chat";
        private String bucketStatus = "oklifor-status";
        /** TTL for presigned PUT URLs in seconds (default 15 min). */
        private long presignedPutTtlSeconds = 900;
    }
}
