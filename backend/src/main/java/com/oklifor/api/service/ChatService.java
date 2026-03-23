package com.oklifor.api.service;

import com.oklifor.api.domain.ChatMessage;
import com.oklifor.api.domain.ChatMessageKind;
import com.oklifor.api.domain.ChatThread;
import com.oklifor.api.domain.ChatThreadType;
import com.oklifor.api.repository.ChatMessageRepository;
import com.oklifor.api.repository.ChatThreadRepository;
import com.oklifor.api.web.dto.ChatMessageResponse;
import com.oklifor.api.web.dto.ChatThreadResponse;
import com.oklifor.api.web.dto.SendMessageRequest;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

@Service
public class ChatService {

    private final ChatThreadRepository threads;
    private final ChatMessageRepository messages;

    public ChatService(ChatThreadRepository threads, ChatMessageRepository messages) {
        this.threads = threads;
        this.messages = messages;
    }

    public List<ChatThreadResponse> listThreads(String userId) {
        return threads.findByParticipantUserIdsContainingOrderByLastMessageAtDesc(userId).stream()
                .map(ChatThreadResponse::from)
                .toList();
    }

    public ChatThreadResponse getOrCreateDirect(String meUserId, String peerUserId) {
        if (meUserId.equals(peerUserId)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "peer_invalide");
        }
        String u1 = meUserId.compareTo(peerUserId) < 0 ? meUserId : peerUserId;
        String u2 = meUserId.compareTo(peerUserId) < 0 ? peerUserId : meUserId;
        ChatThread t =
                threads.findDirectBetweenSortedParticipants(u1, u2)
                        .orElseGet(
                                () -> {
                                    ChatThread n = new ChatThread();
                                    n.setType(ChatThreadType.DIRECT);
                                    n.setParticipantUserIds(new ArrayList<>(List.of(u1, u2)));
                                    return threads.save(n);
                                });
        return ChatThreadResponse.from(t);
    }

    public List<ChatMessageResponse> listMessages(String userId, String threadId, int size) {
        ensureParticipant(userId, threadId);
        var page = PageRequest.of(0, Math.min(size, 100));
        return messages.findByThreadIdOrderByCreatedAtDesc(threadId, page).stream()
                .map(ChatMessageResponse::from)
                .toList();
    }

    public ChatMessageResponse sendMessage(String userId, String threadId, SendMessageRequest req) {
        ChatThread t = ensureParticipant(userId, threadId);
        ChatMessage m = new ChatMessage();
        m.setThreadId(threadId);
        m.setSenderUserId(userId);
        m.setKind(req.kind() != null ? req.kind() : ChatMessageKind.TEXT);
        m.setText(req.text());
        m.setImageUrl(req.imageUrl());
        m.setVoiceSeconds(req.voiceSeconds());
        m.setLocationLabel(req.locationLabel());
        m = messages.save(m);
        t.setLastMessagePreview(preview(req));
        t.setLastMessageAt(m.getCreatedAt() != null ? m.getCreatedAt() : Instant.now());
        threads.save(t);
        return ChatMessageResponse.from(m);
    }

    private ChatThread ensureParticipant(String userId, String threadId) {
        ChatThread t =
                threads.findById(threadId)
                        .orElseThrow(
                                () ->
                                        new ResponseStatusException(
                                                HttpStatus.NOT_FOUND, "fil_introuvable"));
        if (!t.getParticipantUserIds().contains(userId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "acces_refuse");
        }
        return t;
    }

    private static String preview(SendMessageRequest req) {
        if (req.text() != null && !req.text().isBlank()) {
            String t = req.text().trim();
            return t.length() > 140 ? t.substring(0, 137) + "…" : t;
        }
        return switch (req.kind()) {
            case IMAGE -> "📷 Photo";
            case VOICE -> "🎤 Message vocal";
            case LOCATION -> "📍 Position";
            case SYSTEM -> "· · ·";
            default -> "Message";
        };
    }
}
