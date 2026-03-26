package com.oklifor.api.web;

import com.oklifor.api.service.StatusMediaService;
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
@RequestMapping("/api/v1/public/status-media")
public class PublicStatusMediaController {

    private final StatusMediaService statusMediaService;

    public PublicStatusMediaController(StatusMediaService statusMediaService) {
        this.statusMediaService = statusMediaService;
    }

    @GetMapping("/{userId}/{filename}")
    public ResponseEntity<Resource> get(
            @PathVariable String userId,
            @PathVariable String filename,
            @RequestParam long exp,
            @RequestParam String sig) {
        Path path = statusMediaService.resolveSigned(userId, filename, exp, sig);
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
            if (name.endsWith(".jpg") || name.endsWith(".jpeg")) {
                mt = MediaType.IMAGE_JPEG;
            } else if (name.endsWith(".png")) {
                mt = MediaType.IMAGE_PNG;
            } else if (name.endsWith(".webp")) {
                mt = MediaType.parseMediaType("image/webp");
            } else if (name.endsWith(".mp4")) {
                mt = MediaType.parseMediaType("video/mp4");
            } else if (name.endsWith(".webm")) {
                mt = MediaType.parseMediaType("video/webm");
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
