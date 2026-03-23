package com.oklifor.api.web;

import com.oklifor.api.service.ChatMediaService;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.nio.file.Files;
import java.nio.file.Path;

@RestController
@RequestMapping("/api/v1/public/chat-media")
public class PublicChatMediaController {

    private final ChatMediaService chatMediaService;

    public PublicChatMediaController(ChatMediaService chatMediaService) {
        this.chatMediaService = chatMediaService;
    }

    @GetMapping("/{threadId}/{filename}")
    public ResponseEntity<Resource> get(
            @PathVariable String threadId,
            @PathVariable String filename,
            @RequestParam long exp,
            @RequestParam String sig) {
        Path path = chatMediaService.resolveSigned(threadId, filename, exp, sig);
        Resource resource = new FileSystemResource(path);
        String probe = null;
        try {
            probe = Files.probeContentType(path);
        } catch (Exception ignored) {
        }
        MediaType mt =
                probe != null ? MediaType.parseMediaType(probe) : MediaType.APPLICATION_OCTET_STREAM;
        if (MediaType.APPLICATION_OCTET_STREAM.equalsTypeAndSubtype(mt)) {
            String name = path.getFileName().toString().toLowerCase();
            if (name.endsWith(".m4a") || name.endsWith(".f4a") || name.endsWith(".mp4") || name.endsWith(".m4v")) {
                mt = MediaType.parseMediaType("audio/mp4");
            } else if (name.endsWith(".mp3")) {
                mt = MediaType.parseMediaType("audio/mpeg");
            } else if (name.endsWith(".wav")) {
                mt = MediaType.parseMediaType("audio/wav");
            } else if (name.endsWith(".ogg") || name.endsWith(".oga")) {
                mt = MediaType.parseMediaType("audio/ogg");
            } else if (name.endsWith(".webm")) {
                mt = MediaType.parseMediaType("audio/webm");
            } else if (name.endsWith(".aac")) {
                mt = MediaType.parseMediaType("audio/aac");
            } else if (name.endsWith(".jpg") || name.endsWith(".jpeg")) {
                mt = MediaType.IMAGE_JPEG;
            } else if (name.endsWith(".png")) {
                mt = MediaType.IMAGE_PNG;
            } else if (name.endsWith(".webp")) {
                mt = MediaType.parseMediaType("image/webp");
            } else if (name.endsWith(".mov")) {
                mt = MediaType.parseMediaType("video/quicktime");
            }
        }
        return ResponseEntity.ok()
                .header(HttpHeaders.CACHE_CONTROL, "private, max-age=300")
                .contentType(mt)
                .body(resource);
    }
}
