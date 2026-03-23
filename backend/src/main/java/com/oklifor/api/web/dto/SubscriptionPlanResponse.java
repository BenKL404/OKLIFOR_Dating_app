package com.oklifor.api.web.dto;

import com.oklifor.api.domain.SubscriptionPlan;

public record SubscriptionPlanResponse(
        String id,
        String code,
        String title,
        long priceFcfa,
        int durationDays,
        String badge) {

    public static SubscriptionPlanResponse from(SubscriptionPlan p) {
        return new SubscriptionPlanResponse(
                p.getId(),
                p.getCode(),
                p.getTitle(),
                p.getPriceFcfa(),
                p.getDurationDays(),
                p.getBadge());
    }
}
