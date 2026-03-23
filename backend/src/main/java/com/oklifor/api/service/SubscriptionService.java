package com.oklifor.api.service;

import com.oklifor.api.domain.SubscriptionPlan;
import com.oklifor.api.domain.UserSubscription;
import com.oklifor.api.domain.UserSubscriptionStatus;
import com.oklifor.api.repository.SubscriptionPlanRepository;
import com.oklifor.api.repository.UserSubscriptionRepository;
import com.oklifor.api.web.dto.SubscriptionPlanResponse;
import com.oklifor.api.web.dto.SubscriptionStateResponse;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.concurrent.TimeUnit;

@Service
public class SubscriptionService {

    private static final String CACHE_PREFIX = "okl:sub:active:";

    private final SubscriptionPlanRepository plans;
    private final UserSubscriptionRepository subscriptions;
    private final StringRedisTemplate redis;

    public SubscriptionService(
            SubscriptionPlanRepository plans,
            UserSubscriptionRepository subscriptions,
            StringRedisTemplate redis) {
        this.plans = plans;
        this.subscriptions = subscriptions;
        this.redis = redis;
    }

    public List<SubscriptionPlanResponse> listActivePlans() {
        return plans.findAllByActiveIsTrueOrderByPriceFcfaAsc().stream()
                .map(SubscriptionPlanResponse::from)
                .toList();
    }

    public SubscriptionStateResponse currentStateForUser(String userId) {
        String cacheKey = CACHE_PREFIX + userId;
        String cached = redis.opsForValue().get(cacheKey);
        if (cached != null && !cached.isBlank()) {
            return parseCached(cached);
        }
        SubscriptionStateResponse computed = computeFromDb(userId);
        redis.opsForValue()
                .set(
                        cacheKey,
                        serialize(computed),
                        Duration.ofSeconds(45).toMillis(),
                        TimeUnit.MILLISECONDS);
        return computed;
    }

    public UserSubscription activateForUser(
            String userId, String planCode, String paymentProvider, String externalRef) {
        SubscriptionPlan plan =
                plans.findByCodeAndActiveIsTrue(planCode)
                        .orElseThrow(
                                () ->
                                        new ResponseStatusException(
                                                HttpStatus.NOT_FOUND, "plan_introuvable"));

        Instant now = Instant.now();
        Instant until = now.plus(Duration.ofDays(plan.getDurationDays()));

        UserSubscription sub = new UserSubscription();
        sub.setUserId(userId);
        sub.setPlanId(plan.getId());
        sub.setStatus(UserSubscriptionStatus.ACTIVE);
        sub.setValidFrom(now);
        sub.setValidUntil(until);
        sub.setPaymentProvider(paymentProvider != null ? paymentProvider : "demo");
        sub.setExternalPaymentReference(externalRef);
        UserSubscription saved = subscriptions.save(sub);
        redis.delete(CACHE_PREFIX + userId);
        return saved;
    }

    private SubscriptionStateResponse computeFromDb(String userId) {
        Optional<UserSubscription> opt =
                subscriptions.findFirstByUserIdAndStatusOrderByValidUntilDesc(
                        userId, UserSubscriptionStatus.ACTIVE);
        if (opt.isEmpty()) {
            return SubscriptionStateResponse.inactive();
        }
        UserSubscription s = opt.get();
        if (s.getValidUntil() != null && s.getValidUntil().isBefore(Instant.now())) {
            return SubscriptionStateResponse.inactive();
        }
        SubscriptionPlan plan = plans.findById(s.getPlanId()).orElse(null);
        String code = plan != null ? plan.getCode() : "";
        return new SubscriptionStateResponse(
                true, s.getValidUntil(), code, s.getPlanId());
    }

    private static String serialize(SubscriptionStateResponse s) {
        if (!s.active()) {
            return "false|||";
        }
        return "true|"
                + (s.validUntil() != null ? s.validUntil().toEpochMilli() : "")
                + "|"
                + s.planCode()
                + "|"
                + (s.planUuid() != null ? s.planUuid() : "");
    }

    private static SubscriptionStateResponse parseCached(String raw) {
        String[] p = raw.split("\\|", -1);
        boolean active = Boolean.parseBoolean(p[0]);
        if (!active || p.length < 4) {
            return SubscriptionStateResponse.inactive();
        }
        Instant until =
                p[1].isEmpty() ? null : Instant.ofEpochMilli(Long.parseLong(p[1]));
        return new SubscriptionStateResponse(active, until, p[2], p[3].isEmpty() ? null : p[3]);
    }
}
