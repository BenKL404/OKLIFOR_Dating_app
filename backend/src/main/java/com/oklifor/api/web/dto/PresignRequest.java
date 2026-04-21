package com.oklifor.api.web.dto;

import jakarta.validation.constraints.NotBlank;

public record PresignRequest(
        @NotBlank String filename,
        @NotBlank String contentType
) {}
