package com.oklifor.api.bootstrap;

import com.oklifor.api.domain.ContactRelation;
import com.oklifor.api.domain.UserAccount;
import com.oklifor.api.domain.UserProfile;
import com.oklifor.api.repository.ContactRelationRepository;
import com.oklifor.api.repository.UserAccountRepository;
import com.oklifor.api.repository.UserProfileRepository;
import com.oklifor.api.service.AccountProvisioningService;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Set;

@Component
public class DefaultContactsSeeder implements ApplicationRunner {

    private static final List<SeedProfile> DEFAULT_CONTACTS =
            List.of(
                    new SeedProfile(
                            "+22890010001",
                            "Ama Mensah",
                            "Lomé",
                            "Photographe lifestyle, sorties plage et concerts.",
                            "Relation sérieuse",
                            "Français, Ewe",
                            "Ewe",
                            "Créative & active",
                            "Photographe",
                            "Licence communication",
                            "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&q=80&auto=format&fit=crop"),
                    new SeedProfile(
                            "+22890010002",
                            "Kossi Lawson",
                            "Kara",
                            "Ingénieur logiciel, passionné de voyages et randonnées.",
                            "Rencontres",
                            "Français, Anglais",
                            "Kabye",
                            "Sport & tech",
                            "Ingénieur logiciel",
                            "Master informatique",
                            "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&q=80&auto=format&fit=crop"),
                    new SeedProfile(
                            "+22890010003",
                            "Yawa Gbéto",
                            "Aného",
                            "Entrepreneure, aime la cuisine locale et les discussions profondes.",
                            "Amitié et plus",
                            "Français, Mina",
                            "Mina",
                            "Calme & sociable",
                            "Entrepreneure",
                            "BTS Gestion",
                            "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400&q=80&auto=format&fit=crop"));

    private final AccountProvisioningService provisioning;
    private final UserAccountRepository users;
    private final UserProfileRepository profiles;
    private final ContactRelationRepository contacts;

    public DefaultContactsSeeder(
            AccountProvisioningService provisioning,
            UserAccountRepository users,
            UserProfileRepository profiles,
            ContactRelationRepository contacts) {
        this.provisioning = provisioning;
        this.users = users;
        this.profiles = profiles;
        this.contacts = contacts;
    }

    @Override
    public void run(ApplicationArguments args) {
        List<UserAccount> defaults = DEFAULT_CONTACTS.stream().map(this::upsertDefaultContact).toList();
        Set<String> defaultIds = defaults.stream().map(UserAccount::getId).collect(java.util.stream.Collectors.toSet());

        for (UserAccount owner : users.findAll()) {
            for (UserAccount c : defaults) {
                if (owner.getId().equals(c.getId())) {
                    continue;
                }
                if (!contacts.existsByOwnerUserIdAndContactUserId(owner.getId(), c.getId())) {
                    ContactRelation rel = new ContactRelation();
                    rel.setOwnerUserId(owner.getId());
                    rel.setContactUserId(c.getId());
                    rel.setCreatedVia(defaultIds.contains(owner.getId()) ? "seed" : "seed-default");
                    contacts.save(rel);
                }
            }
        }
    }

    private UserAccount upsertDefaultContact(SeedProfile seed) {
        UserAccount account = provisioning.findOrCreateByPhone(seed.phoneE164());
        UserProfile profile = profiles.findByUserId(account.getId()).orElseGet(() -> createMissingProfile(account.getId()));
        profile.setDisplayName(seed.displayName());
        profile.setCity(seed.city());
        profile.setBio(seed.bio());
        profile.setRelationGoal(seed.relationGoal());
        profile.setLanguages(seed.languages());
        profile.setEthnicity(seed.ethnicity());
        profile.setLifestyle(seed.lifestyle());
        profile.setProfession(seed.profession());
        profile.setEducation(seed.education());
        profile.setAvatarUrl(seed.avatarUrl());
        profile.setCoverUrl("");
        profile.setPhoneVerified(true);
        profile.setProfileOnboardingCompleted(true);
        profiles.save(profile);
        return account;
    }

    private UserProfile createMissingProfile(String userId) {
        UserProfile p = new UserProfile();
        p.setUserId(userId);
        p.setDisplayName("Profil Oklifor");
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
        p.setProfileOnboardingCompleted(true);
        return p;
    }

    private record SeedProfile(
            String phoneE164,
            String displayName,
            String city,
            String bio,
            String relationGoal,
            String languages,
            String ethnicity,
            String lifestyle,
            String profession,
            String education,
            String avatarUrl) {}
}
