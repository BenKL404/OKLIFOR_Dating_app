package com.oklifor.api.service;

import com.oklifor.api.domain.UserAccount;
import com.oklifor.api.domain.UserProfile;
import com.oklifor.api.domain.UserSettingsDoc;
import com.oklifor.api.repository.UserAccountRepository;
import com.oklifor.api.repository.UserProfileRepository;
import com.oklifor.api.repository.UserSettingsRepository;
import org.springframework.stereotype.Service;

@Service
public class AccountProvisioningService {

    private final UserAccountRepository users;
    private final UserProfileRepository profiles;
    private final UserSettingsRepository settings;

    public AccountProvisioningService(
            UserAccountRepository users,
            UserProfileRepository profiles,
            UserSettingsRepository settings) {
        this.users = users;
        this.profiles = profiles;
        this.settings = settings;
    }

    public UserAccount findOrCreateByPhone(String phoneE164) {
        return users.findByPhoneE164(phoneE164)
                .orElseGet(() -> createFreshAccount(phoneE164));
    }

    private UserAccount createFreshAccount(String phoneE164) {
        UserAccount u = new UserAccount();
        u.setPhoneE164(phoneE164);
        u = users.save(u);

        UserProfile p = new UserProfile();
        p.setUserId(u.getId());
        p.setDisplayName("Moi");
        p.setCity("Lomé");
        p.setBio("");
        p.setRelationGoal("");
        p.setLanguages("");
        p.setEthnicity("");
        p.setLifestyle("");
        p.setProfession("");
        p.setEducation("");
        p.setCoverUrl("");
        p.setAvatarUrl("");
        p.setPhoneVerified(true);
        profiles.save(p);

        UserSettingsDoc s = new UserSettingsDoc();
        s.setUserId(u.getId());
        settings.save(s);

        return u;
    }
}
