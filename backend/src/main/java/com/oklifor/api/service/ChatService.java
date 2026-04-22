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
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class ChatService {

    private final ChatThreadRepository threads;
    private final ChatMessageRepository messages;
    private final ChatMediaService chatMediaService;

    public ChatService(
            ChatThreadRepository threads,
            ChatMessageRepository messages,
            ChatMediaService chatMediaService) {
        this.threads = threads;
        this.messages = messages;
        this.chatMediaService = chatMediaService;
    }

    public List<ChatThreadResponse> listThreads(String userId) {
        return threads.findByParticipantUserIdsContainingOrderByLastMessageAtDesc(userId).stream()
                .map(t -> ChatThreadResponse.from(t, userId))
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
        return ChatThreadResponse.from(t, meUserId);
    }

    public List<ChatMessageResponse> listMessages(String userId, String threadId, int size, int page) {
        ChatThread t = ensureParticipant(userId, threadId);
        var pageable = PageRequest.of(page, Math.min(size, 100));
        return messages.findByThreadIdOrderByCreatedAtDesc(threadId, pageable).stream()
                .map(m -> toMessageResponse(m, userId, t))
                .toList();
    }

    public ChatMessageResponse sendMessage(String userId, String threadId, SendMessageRequest req) {
        ChatThread t = ensureParticipant(userId, threadId);
        ChatMessage m = new ChatMessage();
        m.setThreadId(threadId);
        m.setSenderUserId(userId);
        m.setKind(req.kind() != null ? req.kind() : ChatMessageKind.TEXT);
        m.setText(req.text());
        // Normaliser les médias hébergés sur notre bucket signé : URL relative + nouvelle signature,
        // pour éviter d’enregistrer des hôtes spécifiques au client (10.0.2.2, LAN, etc.).
        m.setImageUrl(refreshChatMediaUrlIfApplicable(req.imageUrl()));
        m.setVideoUrl(refreshChatMediaUrlIfApplicable(req.videoUrl()));
        m.setAudioUrl(refreshChatMediaUrlIfApplicable(req.audioUrl()));
        m.setVoiceSeconds(req.voiceSeconds());
        m.setFileUrl(refreshChatMediaUrlIfApplicable(req.fileUrl()));
        m.setLocationLabel(req.locationLabel());
        m = messages.save(m);
        t.setLastMessagePreview(preview(req));
        t.setLastMessageAt(m.getCreatedAt() != null ? m.getCreatedAt() : Instant.now());
        threads.save(t);
        return toMessageResponse(m, userId, t);
    }

    /**
     * Marque la conversation comme lue par {@code userId} jusqu’à l’instant courant (filigrane 1:1).
     *
     * @return epoch secondes du curseur de lecture enregistré
     */
    public long markThreadRead(String userId, String threadId) {
        ChatThread t = ensureParticipant(userId, threadId);
        Instant now = Instant.now();
        Map<String, Instant> map = t.getLastReadAtByUserId();
        if (map == null) {
            map = new HashMap<>();
            t.setLastReadAtByUserId(map);
        }
        Instant prev = map.get(userId);
        if (prev == null || now.isAfter(prev)) {
            map.put(userId, now);
            threads.save(t);
            return now.getEpochSecond();
        }
        return prev.getEpochSecond();
    }

    private ChatMessageResponse toMessageResponse(ChatMessage m, String viewerUserId, ChatThread thread) {
        boolean readByRecipient = false;
        if (viewerUserId.equals(m.getSenderUserId()) && thread.getType() == ChatThreadType.DIRECT) {
            readByRecipient = isDirectMessageReadByPeer(thread, m.getSenderUserId(), m.getCreatedAt());
        }
        return new ChatMessageResponse(
                m.getId(),
                m.getThreadId(),
                m.getSenderUserId(),
                m.getKind(),
                m.getText(),
                refreshChatMediaUrlIfApplicable(m.getImageUrl()),
                refreshChatMediaUrlIfApplicable(m.getVideoUrl()),
                refreshChatMediaUrlIfApplicable(m.getAudioUrl()),
                m.getVoiceSeconds(),
                m.getLocationLabel(),
                refreshChatMediaUrlIfApplicable(m.getFileUrl()),
                m.getCreatedAt(),
                readByRecipient);
    }

    private String refreshChatMediaUrlIfApplicable(String url) {
        if (url == null || url.isBlank()) {
            return url;
        }
        if (url.contains("/api/v1/public/chat-media/")) {
            return chatMediaService.refreshSignedMediaUrl(url);
        }
        return url;
    }

    private static boolean isDirectMessageReadByPeer(
            ChatThread thread, String senderUserId, Instant messageCreatedAt) {
        if (messageCreatedAt == null) {
            return false;
        }
        List<String> parts = thread.getParticipantUserIds();
        if (parts == null || parts.size() != 2) {
            return false;
        }
        String peer = null;
        for (String p : parts) {
            if (!p.equals(senderUserId)) {
                peer = p;
                break;
            }
        }
        if (peer == null) {
            return false;
        }
        Map<String, Instant> map = thread.getLastReadAtByUserId();
        if (map == null) {
            return false;
        }
        Instant peerRead = map.get(peer);
        if (peerRead == null) {
            return false;
        }
        return !peerRead.isBefore(messageCreatedAt);
    }

    public void deleteMessage(String userId, String threadId, String messageId) {
        ensureParticipant(userId, threadId);
        ChatMessage m = messages.findById(messageId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "message_introuvable"));
        if (!m.getThreadId().equals(threadId)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "invalide");
        }
        if (!m.getSenderUserId().equals(userId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "seul_lexpediteur_peut_supprimer");
        }
        messages.delete(m);
    }

    public void deleteThread(String userId, String threadId) {
        ChatThread t = ensureParticipant(userId, threadId);
        messages.deleteByThreadId(threadId);
        threads.delete(t);
    }

    public void assertParticipant(String userId, String threadId) {
        ensureParticipant(userId, threadId);
    }

    public List<String> participantIds(String userId, String threadId) {
        return List.copyOf(ensureParticipant(userId, threadId).getParticipantUserIds());
    }

    public List<String> threadIdsForUser(String userId) {
        return threads.findByParticipantUserIdsContainingOrderByLastMessageAtDesc(userId).stream()
                .map(ChatThread::getId)
                .toList();
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
            case VIDEO -> "🎬 Vidéo";
            case VOICE -> "🎤 Message vocal";
            case FILE -> "📄 Fichier";
            case LOCATION -> "📍 Position";
            case SYSTEM -> "· · ·";
            default -> "Message";
        };
    }
}
