package com.oklifor.api.web;

import com.oklifor.api.repository.UserProfileRepository;
import com.oklifor.api.web.dto.PublicProfileResponse;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/v1/users")
public class UserController {

    private final UserProfileRepository profiles;

    public UserController(UserProfileRepository profiles) {
        this.profiles = profiles;
    }

    @GetMapping("/{userId}")
    public PublicProfileResponse getProfile(@PathVariable String userId) {
        return profiles.findByUserId(userId)
                .map(PublicProfileResponse::from)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "utilisateur_introuvable"));
    }
}
