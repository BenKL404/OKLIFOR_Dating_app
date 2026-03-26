package com.oklifor.api.web.dto;

import com.oklifor.api.domain.ChatMessage;
import com.oklifor.api.domain.ChatMessageKind;

import java.time.Instant;

public record ChatMessageResponse(
        String id,
        String threadId,
        String senderUserId,
        ChatMessageKind kind,
        String text,
        String imageUrl,
        String videoUrl,
        String audioUrl,
        Integer voiceSeconds,
        String locationLabel,
        String fileUrl,
        Instant createdAt,
        boolean readByRecipient) {

    public static ChatMessageResponse from(ChatMessage m) {
        return new ChatMessageResponse(
                m.getId(),
                m.getThreadId(),
                m.getSenderUserId(),
                m.getKind(),
                m.getText(),
                m.getImageUrl(),
                m.getVideoUrl(),
                m.getAudioUrl(),
                m.getVoiceSeconds(),
                m.getLocationLabel(),
                m.getFileUrl(),
                m.getCreatedAt(),
                false);
    }
}
