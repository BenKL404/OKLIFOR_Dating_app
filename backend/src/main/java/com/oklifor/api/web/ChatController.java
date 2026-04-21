package com.oklifor.api.web;

import com.oklifor.api.service.ChatService;
import com.oklifor.api.web.dto.ChatMessageResponse;
import com.oklifor.api.web.dto.ChatThreadResponse;
import com.oklifor.api.web.dto.CreateDirectThreadRequest;
import com.oklifor.api.web.dto.SendMessageRequest;
import jakarta.validation.Valid;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/chat")
public class ChatController {

    private final ChatService chatService;

    public ChatController(ChatService chatService) {
        this.chatService = chatService;
    }

    @GetMapping("/threads")
    public List<ChatThreadResponse> threads(Authentication auth) {
        return chatService.listThreads(auth.getName());
    }

    @PostMapping("/threads/direct")
    public ChatThreadResponse createDirect(Authentication auth, @Valid @RequestBody CreateDirectThreadRequest body) {
        return chatService.getOrCreateDirect(auth.getName(), body.peerUserId());
    }

    @GetMapping("/threads/{threadId}/messages")
    public List<ChatMessageResponse> messages(
            Authentication auth,
            @PathVariable String threadId,
            @RequestParam(defaultValue = "50") int size,
            @RequestParam(defaultValue = "0") int page) {
        return chatService.listMessages(auth.getName(), threadId, size, page);
    }

    @PostMapping("/threads/{threadId}/messages")
    public ChatMessageResponse send(
            Authentication auth,
            @PathVariable String threadId,
            @Valid @RequestBody SendMessageRequest body) {
        return chatService.sendMessage(auth.getName(), threadId, body);
    }

    @PostMapping("/threads/{threadId}/read")
    public Map<String, Long> markRead(Authentication auth, @PathVariable String threadId) {
        long epoch = chatService.markThreadRead(auth.getName(), threadId);
        return Map.of("readAtEpoch", epoch);
    }
}
