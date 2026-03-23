package com.oklifor.api.repository;

import com.oklifor.api.domain.UserSubscription;
import com.oklifor.api.domain.UserSubscriptionStatus;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.List;
import java.util.Optional;

public interface UserSubscriptionRepository extends MongoRepository<UserSubscription, String> {

    List<UserSubscription> findByUserIdAndStatus(String userId, UserSubscriptionStatus status);

    Optional<UserSubscription> findFirstByUserIdAndStatusOrderByValidUntilDesc(
            String userId, UserSubscriptionStatus status);
}
