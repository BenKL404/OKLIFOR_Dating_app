package com.oklifor.api.web.dto;

import com.oklifor.api.domain.UserProfile;

public record ProfileResponse(
        String id,
        String userId,
        String displayName,
        String city,
        String bio,
        String relationGoal,
        String languages,
        String ethnicity,
        String lifestyle,
        String profession,
        String education,
        String coverUrl,
        String avatarUrl,
        boolean phoneVerified,
        boolean emailVerified,
        boolean idVerified,
        boolean idPendingReview,
        boolean hasOkliforCertificate) {

    public static ProfileResponse from(UserProfile p) {
        boolean cert = p.isPhoneVerified() && p.isEmailVerified() && p.isIdVerified();
        return new ProfileResponse(
                p.getId(),
                p.getUserId(),
                p.getDisplayName(),
                p.getCity(),
                p.getBio(),
                p.getRelationGoal(),
                p.getLanguages(),
                p.getEthnicity() != null ? p.getEthnicity() : "",
                p.getLifestyle() != null ? p.getLifestyle() : "",
                p.getProfession() != null ? p.getProfession() : "",
                p.getEducation() != null ? p.getEducation() : "",
                p.getCoverUrl(),
                p.getAvatarUrl(),
                p.isPhoneVerified(),
                p.isEmailVerified(),
                p.isIdVerified(),
                p.isIdPendingReview(),
                cert);
    }
}
