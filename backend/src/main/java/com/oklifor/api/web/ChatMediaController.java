package com.oklifor.api.web;

import com.oklifor.api.service.ChatMediaService;
import com.oklifor.api.service.ChatService;
import com.oklifor.api.web.dto.ChatMediaUploadResponse;
import com.oklifor.api.web.dto.PresignRequest;
import com.oklifor.api.web.dto.PresignedUploadResponse;
import jakarta.validation.Valid;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/v1/chat/threads")
public class ChatMediaController {

    private final ChatService chatService;
    private final ChatMediaService chatMediaService;

    public ChatMediaController(ChatService chatService, ChatMediaService chatMediaService) {
        this.chatService = chatService;
        this.chatMediaService = chatMediaService;
    }

    @PostMapping("/{threadId}/media")
    public ChatMediaUploadResponse upload(
            Authentication auth, @PathVariable String threadId, @RequestPart("file") MultipartFile file) {
        chatService.assertParticipant(auth.getName(), threadId);
        return chatMediaService.upload(threadId, file);
    }

    @PostMapping("/{threadId}/media/presign")
    public PresignedUploadResponse presign(
            Authentication auth,
            @PathVariable String threadId,
            @RequestBody @Valid PresignRequest request) {
        chatService.assertParticipant(auth.getName(), threadId);
        return chatMediaService.presign(threadId, request.filename(), request.contentType());
    }
}
