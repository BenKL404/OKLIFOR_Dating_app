package com.oklifor.api.web.dto;

import com.oklifor.api.domain.ChatThread;
import com.oklifor.api.domain.ChatThreadType;

import java.time.Instant;
import java.util.List;

public record ChatThreadResponse(
        String id,
        ChatThreadType type,
        List<String> participantUserIds,
        String name,
        String lastMessagePreview,
        Instant lastMessageAt) {

    public static ChatThreadResponse from(ChatThread t) {
        return new ChatThreadResponse(
                t.getId(),
                t.getType(),
                t.getParticipantUserIds(),
                t.getName(),
                t.getLastMessagePreview(),
                t.getLastMessageAt());
    }
}
