package com.oklifor.api.websocket.event;

import org.springframework.context.ApplicationEvent;

public class ChatReadReceiptEvent extends ApplicationEvent {
    private final String threadId;
    private final String userId;
    private final long readAtEpoch;

    public ChatReadReceiptEvent(Object source, String threadId, String userId, long readAtEpoch) {
        super(source);
        this.threadId = threadId;
        this.userId = userId;
        this.readAtEpoch = readAtEpoch;
    }

    public String getThreadId() { return threadId; }
    public String getUserId() { return userId; }
    public long getReadAtEpoch() { return readAtEpoch; }
}
