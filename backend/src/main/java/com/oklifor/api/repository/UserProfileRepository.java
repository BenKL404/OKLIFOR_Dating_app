package com.oklifor.api.repository;

import com.oklifor.api.domain.UserProfile;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.Optional;

public interface UserProfileRepository extends MongoRepository<UserProfile, String> {

    Optional<UserProfile> findByUserId(String userId);
}
