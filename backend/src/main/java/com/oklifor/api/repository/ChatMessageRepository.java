package com.oklifor.api.repository;

import com.oklifor.api.domain.ChatMessage;
import org.springframework.data.domain.Pageable;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.List;

public interface ChatMessageRepository extends MongoRepository<ChatMessage, String> {

    List<ChatMessage> findByThreadIdOrderByCreatedAtDesc(String threadId, Pageable pageable);
}
