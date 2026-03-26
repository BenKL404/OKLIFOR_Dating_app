package com.oklifor.api.domain;

import lombok.Getter;
import lombok.Setter;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.Instant;

@Document(collection = "user_statuses")
@Getter
@Setter
public class UserStatus extends UuidMongoDocument {

    @Indexed(unique = true)
    private String userId;

    private UserStatusKind kind = UserStatusKind.TEXT;

    /** Statut texte (obligatoire si kind == TEXT). */
    private String text;

    /** Fond statut texte, ex. #FF6B2D5C ou #6B2D5C */
    private String backgroundColorHex;

    private String caption;

    /** Nom fichier sur disque (kind IMAGE / VIDEO), sous dossier userId. */
    private String mediaFilename;

    private Instant expiresAt;
}
