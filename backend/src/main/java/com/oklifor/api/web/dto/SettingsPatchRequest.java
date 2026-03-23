package com.oklifor.api.web.dto;

public record SettingsPatchRequest(
        Boolean protectDirectory,
        Boolean neighborhoodMode,
        Boolean incognito,
        Boolean notifyMessages,
        Boolean notifyLikes,
        Boolean notifyMatches,
        Boolean notifyLive,
        Boolean notifyEmail,
        Boolean notifySound,
        Boolean privacyShowOnline,
        Boolean privacyShowDistance,
        Boolean privacyReadReceipts,
        Boolean privacyAllowRequests,
        Boolean securityTwoFactor,
        Boolean securityBiometric,
        Boolean securityScreenLock,
        String appLanguage,
        Boolean appAutoPlayMedia,
        Boolean appDataSaver,
        Boolean appVibrate) {}
