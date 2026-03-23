package com.oklifor.api.domain;

import lombok.Getter;
import lombok.Setter;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

@Document(collection = "chat_threads")
@Getter
@Setter
public class ChatThread extends UuidMongoDocument {

    private ChatThreadType type = ChatThreadType.DIRECT;

    /** Utilisateurs participants (UUID). */
    private List<String> participantUserIds = new ArrayList<>();

    private String name;

    private String lastMessagePreview;

    @Indexed
    private Instant lastMessageAt;
}
