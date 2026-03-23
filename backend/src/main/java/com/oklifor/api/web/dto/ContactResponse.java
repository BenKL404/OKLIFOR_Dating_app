package com.oklifor.api.web.dto;

import java.time.Instant;

public record ContactResponse(
        String userId, String displayName, String avatarUrl, Instant addedAt) {}
