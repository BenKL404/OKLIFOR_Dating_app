package com.oklifor.api.repository;

import com.oklifor.api.domain.UserAccount;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.Optional;

public interface UserAccountRepository extends MongoRepository<UserAccount, String> {

    Optional<UserAccount> findByPhoneE164(String phoneE164);
}
