package com.oklifor.api.web.dto;

import com.oklifor.api.domain.UserStatusKind;

public record StatusMediaUploadResponse(UserStatusKind mediaKind, String signedUrl) {}
