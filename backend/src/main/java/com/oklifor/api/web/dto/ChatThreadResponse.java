package com.oklifor.api.web.dto;

import com.oklifor.api.domain.ChatThread;
import com.oklifor.api.domain.ChatThreadType;

import java.time.Instant;
import java.util.List;
import java.util.Map;

public record ChatThreadResponse(
        String id,
        ChatThreadType type,
        List<String> participantUserIds,
        String name,
        String lastMessagePreview,
        Instant lastMessageAt,
        boolean hasUnread) {

    public static ChatThreadResponse from(ChatThread t, String userId) {
        boolean hasUnread = false;
        if (t.getLastMessageAt() != null) {
            Map<String, Instant> readMap = t.getLastReadAtByUserId();
            Instant readAt = readMap != null ? readMap.get(userId) : null;
            hasUnread = readAt == null || readAt.isBefore(t.getLastMessageAt());
        }
        return new ChatThreadResponse(
                t.getId(),
                t.getType(),
                t.getParticipantUserIds(),
                t.getName(),
                t.getLastMessagePreview(),
                t.getLastMessageAt(),
                hasUnread);
    }
}
