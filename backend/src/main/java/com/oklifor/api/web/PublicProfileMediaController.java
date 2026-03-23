package com.oklifor.api.web;

import com.oklifor.api.service.ProfileMediaService;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.nio.file.Files;
import java.nio.file.Path;

@RestController
@RequestMapping("/api/v1/public/profile-media")
public class PublicProfileMediaController {

    private final ProfileMediaService profileMediaService;

    public PublicProfileMediaController(ProfileMediaService profileMediaService) {
        this.profileMediaService = profileMediaService;
    }

    @GetMapping("/{userId}/{filename}")
    public ResponseEntity<Resource> get(
            @PathVariable("userId") String userId, @PathVariable("filename") String filename) {
        Path path = profileMediaService.resolveExistingFile(userId, filename);
        Resource resource = new FileSystemResource(path);
        String probe = null;
        try {
            probe = Files.probeContentType(path);
        } catch (Exception ignored) {
        }
        MediaType mt =
                probe != null
                        ? MediaType.parseMediaType(probe)
                        : MediaType.APPLICATION_OCTET_STREAM;
        return ResponseEntity.ok()
                .header(HttpHeaders.CACHE_CONTROL, "public, max-age=86400")
                .contentType(mt)
                .body(resource);
    }
}
