package com.oklifor.api.web.dto;

public record MeResponse(
        String userId,
        String phoneE164,
        ProfileResponse profile,
        SettingsResponse settings,
        SubscriptionStateResponse subscription) {}
