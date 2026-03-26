package com.oklifor.api.web.dto;

import com.oklifor.api.domain.ChatMessageKind;
import jakarta.validation.constraints.NotNull;

public record SendMessageRequest(
        @NotNull ChatMessageKind kind,
        String text,
        String imageUrl,
        String videoUrl,
        String audioUrl,
        Integer voiceSeconds,
        String locationLabel,
        String fileUrl) {}
