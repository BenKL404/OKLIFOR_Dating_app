package com.oklifor.api.websocket;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.oklifor.api.domain.ChatMessageKind;
import com.oklifor.api.service.ChatPresenceService;
import com.oklifor.api.service.ChatService;
import com.oklifor.api.web.dto.ChatMessageResponse;
import com.oklifor.api.web.dto.SendMessageRequest;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import java.io.IOException;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class ChatWebSocketHandler extends TextWebSocketHandler {

    private final ChatService chatService;
    private final ChatPresenceService presenceService;
    private final ObjectMapper objectMapper;
    private final Map<String, Set<WebSocketSession>> threadSessions = new ConcurrentHashMap<>();
    private final Map<String, Set<String>> sessionThreads = new ConcurrentHashMap<>();
    private final Map<String, String> sessionUsers = new ConcurrentHashMap<>();
    private final Map<String, Set<WebSocketSession>> userSessions = new ConcurrentHashMap<>();

    public ChatWebSocketHandler(
            ChatService chatService,
            ChatPresenceService presenceService,
            ObjectMapper objectMapper) {
        this.chatService = chatService;
        this.presenceService = presenceService;
        this.objectMapper = objectMapper;
    }

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws IOException {
        sessionThreads.put(session.getId(), ConcurrentHashMap.newKeySet());
        String userId = currentUserId(session);
        if (userId == null) {
            session.close(CloseStatus.NOT_ACCEPTABLE.withReason("auth_required"));
            return;
        }
        sessionUsers.put(session.getId(), userId);
        userSessions.computeIfAbsent(userId, k -> ConcurrentHashMap.newKeySet()).add(session);
        presenceService.markOnline(userId);
        broadcastPresenceToUserThreads(userId, true, 0);
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) throws IOException {
        String userId = currentUserId(session);
        if (userId == null) {
            session.close(CloseStatus.NOT_ACCEPTABLE.withReason("auth_required"));
            return;
        }
        JsonNode root = objectMapper.readTree(message.getPayload());
        String action = root.path("action").asText("");
        switch (action) {
            case "subscribe" -> handleSubscribe(session, userId, root);
            case "send" -> handleSend(session, userId, root);
            case "typing" -> handleTyping(session, userId, root);
            case "markRead" -> handleMarkRead(session, userId, root);
            default -> sendError(session, "action_invalide");
        }
    }

    private void handleSubscribe(WebSocketSession session, String userId, JsonNode root) throws IOException {
        String threadId = root.path("threadId").asText("").trim();
        if (threadId.isEmpty()) {
            sendError(session, "thread_invalide");
            return;
        }
        try {
            chatService.assertParticipant(userId, threadId);
        } catch (Exception e) {
            sendError(session, "acces_refuse");
            return;
        }
        threadSessions.computeIfAbsent(threadId, k -> ConcurrentHashMap.newKeySet()).add(session);
        sessionThreads.computeIfAbsent(session.getId(), k -> ConcurrentHashMap.newKeySet()).add(threadId);
        session.sendMessage(new TextMessage("{\"type\":\"subscribed\",\"threadId\":\"" + threadId + "\"}"));
        sendPresenceSnapshot(session, userId, threadId);
    }

    private void sendPresenceSnapshot(WebSocketSession session, String userId, String threadId) throws IOException {
        List<String> participants = chatService.participantIds(userId, threadId);
        for (String pid : participants) {
            if (pid.equals(userId)) continue;
            boolean online = presenceService.isOnline(pid);
            long lastSeen = online ? 0 : presenceService.lastSeenEpoch(pid);
            boolean typing = presenceService.isTyping(threadId, pid);
            String payload =
                    objectMapper.writeValueAsString(
                            Map.of(
                                    "type", "presence",
                                    "threadId", threadId,
                                    "userId", pid,
                                    "online", online,
                                    "lastSeenEpoch", lastSeen));
            session.sendMessage(new TextMessage(payload));
            if (typing) {
                String typingPayload =
                        objectMapper.writeValueAsString(
                                Map.of(
                                        "type", "typing",
                                        "threadId", threadId,
                                        "userId", pid,
                                        "typing", true));
                session.sendMessage(new TextMessage(typingPayload));
            }
        }
    }

    private void handleSend(WebSocketSession session, String userId, JsonNode root) throws IOException {
        String threadId = root.path("threadId").asText("").trim();
        if (threadId.isEmpty()) {
            sendError(session, "thread_invalide");
            return;
        }
        try {
            ChatMessageKind kind = ChatMessageKind.valueOf(root.path("kind").asText("TEXT").toUpperCase());
            SendMessageRequest req =
                    new SendMessageRequest(
                            kind,
                            nullableText(root, "text"),
                            nullableText(root, "imageUrl"),
                            nullableText(root, "videoUrl"),
                            nullableText(root, "audioUrl"),
                            root.path("voiceSeconds").isNumber() ? root.path("voiceSeconds").asInt() : null,
                            nullableText(root, "locationLabel"),
                            nullableText(root, "fileUrl"));
            ChatMessageResponse saved = chatService.sendMessage(userId, threadId, req);
            String payload =
                    objectMapper.writeValueAsString(
                            Map.of("type", "message", "message", saved));
            broadcastToThread(threadId, payload);
        } catch (IllegalArgumentException e) {
            sendError(session, "kind_invalide");
        } catch (Exception e) {
            sendError(session, "envoi_impossible");
        }
    }

    private void handleMarkRead(WebSocketSession session, String userId, JsonNode root) throws IOException {
        String threadId = root.path("threadId").asText("").trim();
        if (threadId.isEmpty()) {
            sendError(session, "thread_invalide");
            return;
        }
        try {
            long readAtEpoch = chatService.markThreadRead(userId, threadId);
            String payload =
                    objectMapper.writeValueAsString(
                            Map.of(
                                    "type", "read_receipt",
                                    "threadId", threadId,
                                    "userId", userId,
                                    "readAtEpoch", readAtEpoch));
            broadcastToThread(threadId, payload);
        } catch (Exception e) {
            sendError(session, "lecture_impossible");
        }
    }

    private void handleTyping(WebSocketSession session, String userId, JsonNode root) throws IOException {
        String threadId = root.path("threadId").asText("").trim();
        if (threadId.isEmpty()) {
            sendError(session, "thread_invalide");
            return;
        }
        boolean typing = root.path("typing").asBoolean(false);
        try {
            chatService.assertParticipant(userId, threadId);
            presenceService.markTyping(threadId, userId, typing);
            String payload =
                    objectMapper.writeValueAsString(
                            Map.of(
                                    "type", "typing",
                                    "threadId", threadId,
                                    "userId", userId,
                                    "typing", typing));
            broadcastToThread(threadId, payload);
        } catch (Exception e) {
            sendError(session, "typing_impossible");
        }
    }

    private void broadcastToThread(String threadId, String payload) {
        Set<WebSocketSession> sessions = threadSessions.get(threadId);
        if (sessions == null || sessions.isEmpty()) {
            return;
        }
        TextMessage out = new TextMessage(payload);
        sessions.removeIf(s -> !s.isOpen());
        for (WebSocketSession s : sessions) {
            try {
                s.sendMessage(out);
            } catch (IOException ignored) {
            }
        }
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) {
        String userId = sessionUsers.remove(session.getId());
        if (userId != null) {
            Set<WebSocketSession> ownSessions = userSessions.get(userId);
            if (ownSessions != null) {
                ownSessions.remove(session);
                if (ownSessions.isEmpty()) {
                    userSessions.remove(userId);
                    long lastSeen = presenceService.markOffline(userId);
                    broadcastPresenceToUserThreads(userId, false, lastSeen);
                }
            }
        }
        Set<String> threads = sessionThreads.remove(session.getId());
        if (threads == null) {
            return;
        }
        for (String threadId : threads) {
            Set<WebSocketSession> set = threadSessions.get(threadId);
            if (set == null) {
                continue;
            }
            set.remove(session);
            if (set.isEmpty()) {
                threadSessions.remove(threadId);
            }
        }
    }

    private void broadcastPresenceToUserThreads(String userId, boolean online, long lastSeenEpoch) {
        List<String> threadIds = chatService.threadIdsForUser(userId);
        for (String threadId : threadIds) {
            try {
                String payload =
                        objectMapper.writeValueAsString(
                                Map.of(
                                        "type", "presence",
                                        "threadId", threadId,
                                        "userId", userId,
                                        "online", online,
                                        "lastSeenEpoch", lastSeenEpoch > 0 ? lastSeenEpoch : 0,
                                        "atEpoch", Instant.now().getEpochSecond()));
                broadcastToThread(threadId, payload);
            } catch (Exception ignored) {
            }
        }
    }

    private String currentUserId(WebSocketSession session) {
        Object raw = session.getAttributes().get(ChatAuthHandshakeInterceptor.USER_ID_ATTR);
        return raw instanceof String ? (String) raw : null;
    }

    private static String nullableText(JsonNode root, String key) {
        JsonNode node = root.get(key);
        if (node == null || node.isNull()) {
            return null;
        }
        String value = node.asText("");
        return value.isBlank() ? null : value;
    }

    private void sendError(WebSocketSession session, String code) throws IOException {
        session.sendMessage(new TextMessage("{\"type\":\"error\",\"code\":\"" + code + "\"}"));
    }
}
