package com.oklifor.api.web.dto;

import com.oklifor.api.domain.UserStatusKind;

import java.time.Instant;

public record MyUserStatusResponse(
        UserStatusKind kind,
        String text,
        String backgroundColorHex,
        String caption,
        /** URL signée relative ou absolue rafraîchie (média). */
        String mediaUrl,
        Instant createdAt,
        Instant expiresAt) {}
