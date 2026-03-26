package com.oklifor.api.web.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.List;

public record StatusPreviewsRequest(
        @NotNull @Size(max = 200) List<@NotNull String> userIds) {}
