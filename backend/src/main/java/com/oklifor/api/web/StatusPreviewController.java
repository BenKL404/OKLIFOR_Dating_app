package com.oklifor.api.web;

import com.oklifor.api.service.UserStatusService;
import com.oklifor.api.web.dto.StatusPreviewResponse;
import com.oklifor.api.web.dto.StatusPreviewsRequest;
import jakarta.validation.Valid;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/status")
public class StatusPreviewController {

    private final UserStatusService userStatusService;

    public StatusPreviewController(UserStatusService userStatusService) {
        this.userStatusService = userStatusService;
    }

    @PostMapping("/previews")
    public List<StatusPreviewResponse> previews(
            Authentication auth, @Valid @RequestBody StatusPreviewsRequest body) {
        return userStatusService.previewsFor(auth.getName(), body.userIds());
    }
}
