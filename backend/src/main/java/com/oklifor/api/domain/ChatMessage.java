package com.oklifor.api.domain;

import lombok.Getter;
import lombok.Setter;
import org.springframework.data.mongodb.core.index.CompoundIndex;
import org.springframework.data.mongodb.core.index.CompoundIndexes;
import org.springframework.data.mongodb.core.mapping.Document;

@Document(collection = "chat_messages")
@CompoundIndexes({
        @CompoundIndex(name = "thread_created", def = "{'threadId': 1, 'createdAt': -1}")
})
@Getter
@Setter
public class ChatMessage extends UuidMongoDocument {

    private String threadId;
    private String senderUserId;
    private ChatMessageKind kind = ChatMessageKind.TEXT;

    private String text;
    private String imageUrl;
    private String videoUrl;
    private String audioUrl;
    private Integer voiceSeconds;
    private String fileUrl;
    private String locationLabel;
}
