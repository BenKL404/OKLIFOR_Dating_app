package com.oklifor.api.domain;

import lombok.Getter;
import lombok.Setter;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.Instant;

@Document(collection = "user_subscriptions")
@Getter
@Setter
public class UserSubscription extends UuidMongoDocument {

    @Indexed
    private String userId;

    /** Référence {@link SubscriptionPlan#getId()} (UUID). */
    private String planId;

    private UserSubscriptionStatus status = UserSubscriptionStatus.ACTIVE;

    private Instant validFrom;
    private Instant validUntil;

    private String paymentProvider;
    private String externalPaymentReference;
}
