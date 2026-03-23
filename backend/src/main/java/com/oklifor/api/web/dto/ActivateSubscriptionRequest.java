package com.oklifor.api.web.dto;

import jakarta.validation.constraints.NotBlank;

public record ActivateSubscriptionRequest(
        @NotBlank String planCode,
        String paymentProvider,
        String externalPaymentReference) {}
