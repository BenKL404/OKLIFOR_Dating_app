package com.oklifor.api.web.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public record OtpRequest(
        @NotBlank
        @Pattern(regexp = "^\\+[1-9]\\d{7,14}$", message = "Numéro de téléphone invalide (format E.164 requis)")
        String phone) {}
