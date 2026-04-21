package com.oklifor.api.web.dto;

import com.oklifor.api.domain.UserProfile;

public record PublicProfileResponse(
        String userId,
        String displayName,
        String city,
        String bio,
        String avatarUrl,
        String coverUrl,
        boolean idVerified) {

    public static PublicProfileResponse from(UserProfile p) {
        return new PublicProfileResponse(
                p.getUserId(),
                p.getDisplayName(),
                p.getCity(),
                p.getBio(),
                p.getAvatarUrl(),
                p.getCoverUrl(),
                p.isIdVerified());
    }
}
