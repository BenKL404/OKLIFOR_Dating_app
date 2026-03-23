package com.oklifor.api.web.dto;

import jakarta.validation.constraints.NotBlank;

public record OtpRequest(@NotBlank String phone) {}
