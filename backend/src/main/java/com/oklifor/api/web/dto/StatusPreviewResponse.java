package com.oklifor.api.web.dto;

import com.oklifor.api.domain.UserStatusKind;

import java.time.Instant;

public record StatusPreviewResponse(
        String userId,
        boolean hasStory,
        UserStatusKind kind,
        String text,
        String backgroundColorHex,
        String caption,
        String mediaUrl,
        Instant createdAt) {}
