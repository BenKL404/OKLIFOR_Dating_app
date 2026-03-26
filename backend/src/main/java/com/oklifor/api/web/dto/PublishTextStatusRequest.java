package com.oklifor.api.web.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record PublishTextStatusRequest(
        @NotBlank @Size(max = 600) String text,
        /** Optionnel, ex. #6B2D5C ou #FF6B2D5C */
        String backgroundColorHex) {}
