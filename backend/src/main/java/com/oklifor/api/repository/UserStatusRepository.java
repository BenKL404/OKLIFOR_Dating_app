package com.oklifor.api.repository;

import com.oklifor.api.domain.UserStatus;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.Optional;

public interface UserStatusRepository extends MongoRepository<UserStatus, String> {

    Optional<UserStatus> findByUserId(String userId);

    void deleteByUserId(String userId);
}
