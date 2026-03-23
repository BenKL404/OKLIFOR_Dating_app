package com.oklifor.api.web.dto;

import jakarta.validation.constraints.NotBlank;

public record AddContactRequest(@NotBlank String peerUserId) {}
