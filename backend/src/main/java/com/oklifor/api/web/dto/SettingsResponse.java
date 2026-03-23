package com.oklifor.api.web.dto;

import com.oklifor.api.domain.UserSettingsDoc;

public record SettingsResponse(
        String id,
        String userId,
        boolean protectDirectory,
        boolean neighborhoodMode,
        boolean incognito,
        boolean notifyMessages,
        boolean notifyLikes,
        boolean notifyMatches,
        boolean notifyLive,
        boolean notifyEmail,
        boolean notifySound,
        boolean privacyShowOnline,
        boolean privacyShowDistance,
        boolean privacyReadReceipts,
        boolean privacyAllowRequests,
        boolean securityTwoFactor,
        boolean securityBiometric,
        boolean securityScreenLock,
        String appLanguage,
        boolean appAutoPlayMedia,
        boolean appDataSaver,
        boolean appVibrate) {

    public static SettingsResponse from(UserSettingsDoc s) {
        return new SettingsResponse(
                s.getId(),
                s.getUserId(),
                s.isProtectDirectory(),
                s.isNeighborhoodMode(),
                s.isIncognito(),
                s.isNotifyMessages(),
                s.isNotifyLikes(),
                s.isNotifyMatches(),
                s.isNotifyLive(),
                s.isNotifyEmail(),
                s.isNotifySound(),
                s.isPrivacyShowOnline(),
                s.isPrivacyShowDistance(),
                s.isPrivacyReadReceipts(),
                s.isPrivacyAllowRequests(),
                s.isSecurityTwoFactor(),
                s.isSecurityBiometric(),
                s.isSecurityScreenLock(),
                s.getAppLanguage(),
                s.isAppAutoPlayMedia(),
                s.isAppDataSaver(),
                s.isAppVibrate());
    }
}
