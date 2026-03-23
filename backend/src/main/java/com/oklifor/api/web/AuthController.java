package com.oklifor.api.web;

import com.oklifor.api.service.AuthService;
import com.oklifor.api.web.dto.FirebaseIdTokenRequest;
import com.oklifor.api.web.dto.OtpRequest;
import com.oklifor.api.web.dto.OtpVerifyRequest;
import com.oklifor.api.web.dto.TokenResponse;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/otp/request")
    public ResponseEntity<Void> requestOtp(@Valid @RequestBody OtpRequest body) {
        authService.requestOtp(body.phone());
        return ResponseEntity.accepted().build();
    }

    @PostMapping("/otp/verify")
    public TokenResponse verify(@Valid @RequestBody OtpVerifyRequest body) {
        return authService.verifyOtp(body.phone(), body.code());
    }

    @PostMapping("/firebase")
    public TokenResponse firebase(@Valid @RequestBody FirebaseIdTokenRequest body) {
        return authService.loginWithFirebaseIdToken(body.idToken());
    }
}
