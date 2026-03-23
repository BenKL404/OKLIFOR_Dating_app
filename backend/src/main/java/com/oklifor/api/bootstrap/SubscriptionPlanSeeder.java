package com.oklifor.api.bootstrap;

import com.oklifor.api.domain.SubscriptionPlan;
import com.oklifor.api.repository.SubscriptionPlanRepository;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

@Component
public class SubscriptionPlanSeeder implements ApplicationRunner {

    private final SubscriptionPlanRepository plans;

    public SubscriptionPlanSeeder(SubscriptionPlanRepository plans) {
        this.plans = plans;
    }

    @Override
    public void run(ApplicationArguments args) {
        if (plans.count() > 0) {
            return;
        }
        SubscriptionPlan monthly = new SubscriptionPlan();
        monthly.setCode("monthly");
        monthly.setTitle("Pass VIP mensuel");
        monthly.setPriceFcfa(2500);
        monthly.setDurationDays(30);
        monthly.setActive(true);
        monthly.setBadge(null);
        plans.save(monthly);

        SubscriptionPlan yearly = new SubscriptionPlan();
        yearly.setCode("yearly");
        yearly.setTitle("Pass VIP annuel");
        yearly.setPriceFcfa(24000);
        yearly.setDurationDays(365);
        yearly.setActive(true);
        yearly.setBadge("Économise ~20 %");
        plans.save(yearly);
    }
}
