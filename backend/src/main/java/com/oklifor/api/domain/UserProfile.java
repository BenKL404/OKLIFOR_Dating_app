package com.oklifor.api.domain;

import lombok.Getter;
import lombok.Setter;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

@Document(collection = "profiles")
@Getter
@Setter
public class UserProfile extends UuidMongoDocument {

    @Indexed(unique = true)
    private String userId;

    private String displayName;
    private String city;
    private String bio;
    private String relationGoal;
    private String languages;
    /** Origines / communautés (texte libre court). */
    private String ethnicity;
    /** Mode de vie (rythme, sorties, etc.). */
    private String lifestyle;
    private String profession;
    private String education;
    private String coverUrl;
    private String avatarUrl;

    private boolean phoneVerified;
    private boolean emailVerified;
    private boolean idVerified;
    private boolean idPendingReview;

    /** Chemin relatif au répertoire d’upload (admin / audit), non exposé au client. */
    private String verificationSelfieRelativePath;

    /** Rétrocompat / référence principale : PDF ou recto selon le mode d’envoi. */
    private String verificationDocumentRelativePath;

    private String verificationIdPdfRelativePath;
    private String verificationIdRectoRelativePath;
    private String verificationIdVersoRelativePath;
}
