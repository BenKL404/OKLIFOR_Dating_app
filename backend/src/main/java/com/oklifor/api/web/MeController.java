package com.oklifor.api.web;

import com.oklifor.api.service.MeService;
import com.oklifor.api.service.SubscriptionService;
import com.oklifor.api.web.dto.ActivateSubscriptionRequest;
import com.oklifor.api.web.dto.MeResponse;
import com.oklifor.api.web.dto.ProfileResponse;
import com.oklifor.api.web.dto.ProfileUpdateRequest;
import com.oklifor.api.web.dto.SettingsPatchRequest;
import com.oklifor.api.web.dto.SettingsResponse;
import com.oklifor.api.web.dto.SubscriptionStateResponse;
import jakarta.validation.Valid;
import org.springframework.http.MediaType;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/v1/me")
public class MeController {

    private final MeService meService;
    private final SubscriptionService subscriptionService;

    public MeController(MeService meService, SubscriptionService subscriptionService) {
        this.meService = meService;
        this.subscriptionService = subscriptionService;
    }

    @GetMapping
    public MeResponse me(Authentication auth) {
        return meService.me(auth.getName());
    }

    @PatchMapping("/profile")
    public ProfileResponse patchProfile(Authentication auth, @Valid @RequestBody ProfileUpdateRequest body) {
        return meService.patchProfile(auth.getName(), body);
    }

    /**
     * Profil complet : texte (paramètres de formulaire) + fichiers optionnels {@code avatar} et {@code
     * cover} (JPEG, PNG, WebP).
     */
    @PostMapping(value = "/profile/upload-full", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ProfileResponse uploadProfileFull(
            Authentication auth,
            @RequestPart(value = "avatar", required = false) MultipartFile avatar,
            @RequestPart(value = "cover", required = false) MultipartFile cover,
            @RequestParam(value = "displayName", required = false) String displayName,
            @RequestParam(value = "city", required = false) String city,
            @RequestParam(value = "bio", required = false) String bio,
            @RequestParam(value = "relationGoal", required = false) String relationGoal,
            @RequestParam(value = "languages", required = false) String languages,
            @RequestParam(value = "ethnicity", required = false) String ethnicity,
            @RequestParam(value = "lifestyle", required = false) String lifestyle,
            @RequestParam(value = "profession", required = false) String profession,
            @RequestParam(value = "education", required = false) String education) {
        return meService.updateProfileWithMedia(
                auth.getName(),
                displayName,
                city,
                bio,
                relationGoal,
                languages,
                ethnicity,
                lifestyle,
                profession,
                education,
                avatar,
                cover);
    }

    @PatchMapping("/settings")
    public SettingsResponse patchSettings(Authentication auth, @Valid @RequestBody SettingsPatchRequest body) {
        return meService.patchSettings(auth.getName(), body);
    }

    @PostMapping("/subscription/activate")
    public SubscriptionStateResponse activateSubscription(
            Authentication auth, @Valid @RequestBody ActivateSubscriptionRequest body) {
        subscriptionService.activateForUser(
                auth.getName(),
                body.planCode(),
                body.paymentProvider(),
                body.externalPaymentReference());
        return subscriptionService.currentStateForUser(auth.getName());
    }
}
