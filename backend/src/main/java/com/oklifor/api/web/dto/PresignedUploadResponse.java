package com.oklifor.api.web.dto;

public record PresignedUploadResponse(
        String putUrl,
        String fileUrl,
        String mediaKind
) {}
