package com.oklifor.api.web.dto;

import com.oklifor.api.domain.ChatMessageKind;

public record ChatMediaUploadResponse(ChatMessageKind mediaKind, String signedUrl) {}
