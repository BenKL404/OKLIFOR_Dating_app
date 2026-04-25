package com.oklifor.api.websocket.event;

import com.oklifor.api.web.dto.ChatMessageResponse;
import org.springframework.context.ApplicationEvent;

public class NewChatMessageEvent extends ApplicationEvent {
    private final ChatMessageResponse message;

    public NewChatMessageEvent(Object source, ChatMessageResponse message) {
        super(source);
        this.message = message;
    }

    public ChatMessageResponse getMessage() {
        return message;
    }
}
