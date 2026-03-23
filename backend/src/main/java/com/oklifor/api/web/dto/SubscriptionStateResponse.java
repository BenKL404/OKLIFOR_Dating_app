package com.oklifor.api.web.dto;

import java.time.Instant;

public record SubscriptionStateResponse(
        boolean active, Instant validUntil, String planCode, String planUuid) {

    public static SubscriptionStateResponse inactive() {
        return new SubscriptionStateResponse(false, null, "", null);
    }
}
