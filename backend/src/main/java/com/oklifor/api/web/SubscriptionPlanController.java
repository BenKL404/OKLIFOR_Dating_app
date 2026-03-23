package com.oklifor.api.web;

import com.oklifor.api.service.SubscriptionService;
import com.oklifor.api.web.dto.SubscriptionPlanResponse;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/subscription-plans")
public class SubscriptionPlanController {

    private final SubscriptionService subscriptionService;

    public SubscriptionPlanController(SubscriptionService subscriptionService) {
        this.subscriptionService = subscriptionService;
    }

    @GetMapping
    public List<SubscriptionPlanResponse> list() {
        return subscriptionService.listActivePlans();
    }
}
