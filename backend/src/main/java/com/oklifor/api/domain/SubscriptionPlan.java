package com.oklifor.api.domain;

import lombok.Getter;
import lombok.Setter;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

@Document(collection = "subscription_plans")
@Getter
@Setter
public class SubscriptionPlan extends UuidMongoDocument {

    /** Code métier stable : {@code monthly}, {@code yearly}, etc. */
    @Indexed(unique = true)
    private String code;

    private String title;
    private long priceFcfa;
    private int durationDays;
    private boolean active = true;
    private String badge;
}
