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
}
