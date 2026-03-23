package com.oklifor.api.repository;

import com.oklifor.api.domain.ContactRelation;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.List;

public interface ContactRelationRepository extends MongoRepository<ContactRelation, String> {

    List<ContactRelation> findByOwnerUserIdOrderByCreatedAtDesc(String ownerUserId);

    boolean existsByOwnerUserIdAndContactUserId(String ownerUserId, String contactUserId);

    void deleteByOwnerUserIdAndContactUserId(String ownerUserId, String contactUserId);
}
