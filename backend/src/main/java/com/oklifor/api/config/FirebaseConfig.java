package com.oklifor.api.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import jakarta.annotation.PostConstruct;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

/**
 * Initialise l’Admin SDK Firebase pour vérifier les jetons Phone Auth côté serveur.
 * <p>Active avec {@code oklifor.firebase.enabled=true} et un fichier JSON compte de service
 * ({@code oklifor.firebase.credentials-json-path} ou {@code GOOGLE_APPLICATION_CREDENTIALS}).
 */
@Component
@ConditionalOnProperty(name = "oklifor.firebase.enabled", havingValue = "true")
public class FirebaseConfig {

    private final OkliforProperties props;

    public FirebaseConfig(OkliforProperties props) {
        this.props = props;
    }

    @PostConstruct
    public void init() throws IOException {
        if (!FirebaseApp.getApps().isEmpty()) {
            return;
        }
        Path credentialsPath = resolveCredentialsPath();
        try (InputStream in = Files.newInputStream(credentialsPath)) {
            FirebaseOptions options =
                    FirebaseOptions.builder()
                            .setCredentials(GoogleCredentials.fromStream(in))
                            .build();
            FirebaseApp.initializeApp(options);
        }
    }

    private Path resolveCredentialsPath() {
        String configured = props.getFirebase().getCredentialsJsonPath();
        if (configured != null && !configured.isBlank()) {
            Path p = Path.of(configured);
            if (Files.isRegularFile(p)) {
                return p;
            }
        }
        String env = System.getenv("GOOGLE_APPLICATION_CREDENTIALS");
        if (env != null && !env.isBlank()) {
            Path p = Path.of(env);
            if (Files.isRegularFile(p)) {
                return p;
            }
        }
        throw new IllegalStateException(
                "Firebase activé : fichier JSON compte de service introuvable. "
                        + "Définis oklifor.firebase.credentials-json-path ou GOOGLE_APPLICATION_CREDENTIALS.");
    }
}
