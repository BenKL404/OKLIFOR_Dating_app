package com.oklifor.api.web.dto;

import jakarta.validation.constraints.NotBlank;

public record OtpVerifyRequest(@NotBlank String phone, @NotBlank String code) {}
