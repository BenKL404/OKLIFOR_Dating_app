package com.oklifor.api.domain;

import lombok.Getter;
import lombok.Setter;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

/**
 * Préférences alignées sur l’app Flutter (paramètres / confidentialité / notifications).
 */
@Document(collection = "user_settings")
@Getter
@Setter
public class UserSettingsDoc extends UuidMongoDocument {

    @Indexed(unique = true)
    private String userId;

    private boolean protectDirectory = true;
    private boolean neighborhoodMode = true;
    private boolean incognito;

    private boolean notifyMessages = true;
    private boolean notifyLikes = true;
    private boolean notifyMatches = true;
    private boolean notifyLive;
    private boolean notifyEmail;
    private boolean notifySound = true;

    private boolean privacyShowOnline = true;
    private boolean privacyShowDistance = true;
    private boolean privacyReadReceipts = true;
    private boolean privacyAllowRequests = true;

    private boolean securityTwoFactor;
    private boolean securityBiometric;
    private boolean securityScreenLock = true;

    private String appLanguage = "fr";
    private boolean appAutoPlayMedia = true;
    private boolean appDataSaver;
    private boolean appVibrate = true;
}
