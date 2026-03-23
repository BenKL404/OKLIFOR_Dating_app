package com.oklifor.api.repository;

import com.oklifor.api.domain.ChatThread;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.data.mongodb.repository.Query;

import java.util.List;
import java.util.Optional;

public interface ChatThreadRepository extends MongoRepository<ChatThread, String> {

    List<ChatThread> findByParticipantUserIdsContainingOrderByLastMessageAtDesc(String userId);

    @Query(
            "{ $and: [ { 'type': 'DIRECT' }, { 'participantUserIds': { $all: [?0, ?1] } }, { 'participantUserIds': { $size: 2 } } ] }")
    Optional<ChatThread> findDirectBetweenSortedParticipants(String userIdMin, String userIdMax);
}
