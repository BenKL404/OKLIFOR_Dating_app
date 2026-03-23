package com.oklifor.api.service;

import com.oklifor.api.domain.UserAccount;
import com.oklifor.api.domain.UserProfile;
import com.oklifor.api.domain.UserSettingsDoc;
import com.oklifor.api.repository.UserAccountRepository;
import com.oklifor.api.repository.UserProfileRepository;
import com.oklifor.api.repository.UserSettingsRepository;
import com.oklifor.api.web.dto.MeResponse;
import com.oklifor.api.web.dto.ProfileResponse;
import com.oklifor.api.web.dto.ProfileUpdateRequest;
import com.oklifor.api.web.dto.SettingsPatchRequest;
import com.oklifor.api.web.dto.SettingsResponse;
import com.oklifor.api.web.dto.SubscriptionStateResponse;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.io.IOException;

@Service
public class MeService {

    private final UserAccountRepository users;
    private final UserProfileRepository profiles;
    private final UserSettingsRepository settings;
    private final SubscriptionService subscriptionService;
    private final ProfileMediaService profileMediaService;

    public MeService(
            UserAccountRepository users,
            UserProfileRepository profiles,
            UserSettingsRepository settings,
            SubscriptionService subscriptionService,
            ProfileMediaService profileMediaService) {
        this.users = users;
        this.profiles = profiles;
        this.settings = settings;
        this.subscriptionService = subscriptionService;
        this.profileMediaService = profileMediaService;
    }

    public MeResponse me(String userId) {
        UserAccount u =
                users.findById(userId)
                        .orElseThrow(
                                () ->
                                        new ResponseStatusException(
                                                HttpStatus.NOT_FOUND, "utilisateur_introuvable"));
        UserProfile p =
                profiles.findByUserId(userId)
                        .orElseThrow(
                                () -> new ResponseStatusException(HttpStatus.NOT_FOUND, "profil_manquant"));
        UserSettingsDoc s =
                settings.findByUserId(userId)
                        .orElseThrow(
                                () ->
                                        new ResponseStatusException(
                                                HttpStatus.NOT_FOUND, "reglages_manquants"));
        SubscriptionStateResponse sub = subscriptionService.currentStateForUser(userId);
        return new MeResponse(
                u.getId(), u.getPhoneE164(), ProfileResponse.from(p), SettingsResponse.from(s), sub);
    }

    public ProfileResponse patchProfile(String userId, ProfileUpdateRequest req) {
        UserProfile p =
                profiles.findByUserId(userId)
                        .orElseThrow(
                                () -> new ResponseStatusException(HttpStatus.NOT_FOUND, "profil_manquant"));
        if (req.displayName() != null) {
            p.setDisplayName(req.displayName());
        }
        if (req.city() != null) {
            p.setCity(req.city());
        }
        if (req.bio() != null) {
            p.setBio(req.bio());
        }
        if (req.relationGoal() != null) {
            p.setRelationGoal(req.relationGoal());
        }
        if (req.languages() != null) {
            p.setLanguages(req.languages());
        }
        if (req.ethnicity() != null) {
            p.setEthnicity(req.ethnicity());
        }
        if (req.lifestyle() != null) {
            p.setLifestyle(req.lifestyle());
        }
        if (req.profession() != null) {
            p.setProfession(req.profession());
        }
        if (req.education() != null) {
            p.setEducation(req.education());
        }
        if (req.coverUrl() != null) {
            p.setCoverUrl(req.coverUrl());
        }
        if (req.avatarUrl() != null) {
            p.setAvatarUrl(req.avatarUrl());
        }
        return ProfileResponse.from(profiles.save(p));
    }

    /**
     * Mise à jour texte + fichiers optionnels (avatar, couverture). Les champs texte {@code null} sont
     * ignorés ; un fichier vide / absent ne modifie pas l’URL existante.
     */
    public ProfileResponse updateProfileWithMedia(
            String userId,
            String displayName,
            String city,
            String bio,
            String relationGoal,
            String languages,
            String ethnicity,
            String lifestyle,
            String profession,
            String education,
            MultipartFile avatar,
            MultipartFile cover) {
        UserProfile p =
                profiles.findByUserId(userId)
                        .orElseThrow(
                                () -> new ResponseStatusException(HttpStatus.NOT_FOUND, "profil_manquant"));
        if (displayName != null) {
            if (displayName.length() > 120) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "displayName_trop_long");
            }
            p.setDisplayName(displayName);
        }
        if (city != null) {
            if (city.length() > 120) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "city_trop_longue");
            }
            p.setCity(city);
        }
        if (bio != null) {
            if (bio.length() > 2000) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "bio_trop_longue");
            }
            p.setBio(bio);
        }
        if (relationGoal != null) {
            if (relationGoal.length() > 200) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "relationGoal_trop_long");
            }
            p.setRelationGoal(relationGoal);
        }
        if (languages != null) {
            if (languages.length() > 500) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "languages_trop_long");
            }
            p.setLanguages(languages);
        }
        if (ethnicity != null) {
            if (ethnicity.length() > 120) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "ethnicity_trop_long");
            }
            p.setEthnicity(ethnicity);
        }
        if (lifestyle != null) {
            if (lifestyle.length() > 200) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "lifestyle_trop_long");
            }
            p.setLifestyle(lifestyle);
        }
        if (profession != null) {
            if (profession.length() > 120) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "profession_trop_longue");
            }
            p.setProfession(profession);
        }
        if (education != null) {
            if (education.length() > 120) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "education_trop_longue");
            }
            p.setEducation(education);
        }
        try {
            if (avatar != null && !avatar.isEmpty()) {
                p.setAvatarUrl(profileMediaService.storeProfileImage(userId, avatar, "avatar"));
            }
            if (cover != null && !cover.isEmpty()) {
                p.setCoverUrl(profileMediaService.storeProfileImage(userId, cover, "cover"));
            }
        } catch (IOException e) {
            throw new ResponseStatusException(
                    HttpStatus.INTERNAL_SERVER_ERROR, "ecriture_media_profil");
        }
        return ProfileResponse.from(profiles.save(p));
    }

    public SettingsResponse patchSettings(String userId, SettingsPatchRequest req) {
        UserSettingsDoc s =
                settings.findByUserId(userId)
                        .orElseThrow(
                                () ->
                                        new ResponseStatusException(
                                                HttpStatus.NOT_FOUND, "reglages_manquants"));
        if (req.protectDirectory() != null) {
            s.setProtectDirectory(req.protectDirectory());
        }
        if (req.neighborhoodMode() != null) {
            s.setNeighborhoodMode(req.neighborhoodMode());
        }
        if (req.incognito() != null) {
            s.setIncognito(req.incognito());
        }
        if (req.notifyMessages() != null) {
            s.setNotifyMessages(req.notifyMessages());
        }
        if (req.notifyLikes() != null) {
            s.setNotifyLikes(req.notifyLikes());
        }
        if (req.notifyMatches() != null) {
            s.setNotifyMatches(req.notifyMatches());
        }
        if (req.notifyLive() != null) {
            s.setNotifyLive(req.notifyLive());
        }
        if (req.notifyEmail() != null) {
            s.setNotifyEmail(req.notifyEmail());
        }
        if (req.notifySound() != null) {
            s.setNotifySound(req.notifySound());
        }
        if (req.privacyShowOnline() != null) {
            s.setPrivacyShowOnline(req.privacyShowOnline());
        }
        if (req.privacyShowDistance() != null) {
            s.setPrivacyShowDistance(req.privacyShowDistance());
        }
        if (req.privacyReadReceipts() != null) {
            s.setPrivacyReadReceipts(req.privacyReadReceipts());
        }
        if (req.privacyAllowRequests() != null) {
            s.setPrivacyAllowRequests(req.privacyAllowRequests());
        }
        if (req.securityTwoFactor() != null) {
            s.setSecurityTwoFactor(req.securityTwoFactor());
        }
        if (req.securityBiometric() != null) {
            s.setSecurityBiometric(req.securityBiometric());
        }
        if (req.securityScreenLock() != null) {
            s.setSecurityScreenLock(req.securityScreenLock());
        }
        if (req.appLanguage() != null) {
            s.setAppLanguage(req.appLanguage());
        }
        if (req.appAutoPlayMedia() != null) {
            s.setAppAutoPlayMedia(req.appAutoPlayMedia());
        }
        if (req.appDataSaver() != null) {
            s.setAppDataSaver(req.appDataSaver());
        }
        if (req.appVibrate() != null) {
            s.setAppVibrate(req.appVibrate());
        }
        return SettingsResponse.from(settings.save(s));
    }
}
