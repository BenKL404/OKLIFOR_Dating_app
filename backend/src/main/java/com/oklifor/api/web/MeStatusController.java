package com.oklifor.api.web;

import com.oklifor.api.service.UserStatusService;
import com.oklifor.api.web.dto.MyUserStatusResponse;
import com.oklifor.api.web.dto.PublishTextStatusRequest;
import jakarta.validation.Valid;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/v1/me/status")
public class MeStatusController {

    private final UserStatusService userStatusService;

    public MeStatusController(UserStatusService userStatusService) {
        this.userStatusService = userStatusService;
    }

    @GetMapping
    public ResponseEntity<MyUserStatusResponse> get(Authentication auth) {
        return userStatusService
                .getMyStatus(auth.getName())
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.noContent().build());
    }

    @DeleteMapping
    public void delete(Authentication auth) {
        userStatusService.clear(auth.getName());
    }

    @PostMapping(value = "/text", consumes = MediaType.APPLICATION_JSON_VALUE)
    public MyUserStatusResponse publishText(
            Authentication auth, @Valid @RequestBody PublishTextStatusRequest body) {
        return userStatusService.publishText(auth.getName(), body);
    }

    @PostMapping(value = "/media", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public MyUserStatusResponse publishMedia(
            Authentication auth,
            @RequestPart("file") MultipartFile file,
            @RequestParam(value = "caption", required = false) String caption) {
        return userStatusService.publishMedia(auth.getName(), file, caption);
    }
}
