package com.oklifor.api.repository;

import com.oklifor.api.domain.SubscriptionPlan;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.List;
import java.util.Optional;

public interface SubscriptionPlanRepository extends MongoRepository<SubscriptionPlan, String> {

    Optional<SubscriptionPlan> findByCodeAndActiveIsTrue(String code);

    List<SubscriptionPlan> findAllByActiveIsTrueOrderByPriceFcfaAsc();
}
