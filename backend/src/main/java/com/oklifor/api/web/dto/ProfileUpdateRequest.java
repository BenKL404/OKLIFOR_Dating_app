package com.oklifor.api.web.dto;

import jakarta.validation.constraints.Size;

public record ProfileUpdateRequest(
        @Size(max = 120) String displayName,
        @Size(max = 120) String city,
        @Size(max = 2000) String bio,
        @Size(max = 200) String relationGoal,
        @Size(max = 500) String languages,
        @Size(max = 120) String ethnicity,
        @Size(max = 200) String lifestyle,
        @Size(max = 120) String profession,
        @Size(max = 120) String education,
        @Size(max = 2000) String coverUrl,
        @Size(max = 2000) String avatarUrl,
        Boolean profileOnboardingCompleted) {}
