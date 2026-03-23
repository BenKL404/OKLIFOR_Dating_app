package com.oklifor.api.repository;

import com.oklifor.api.domain.UserSettingsDoc;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.Optional;

public interface UserSettingsRepository extends MongoRepository<UserSettingsDoc, String> {

    Optional<UserSettingsDoc> findByUserId(String userId);
}
