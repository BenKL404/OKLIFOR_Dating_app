package com.oklifor.api.websocket;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;

@Configuration
@EnableWebSocket
public class WebSocketConfig implements WebSocketConfigurer {

    private final ChatWebSocketHandler chatWebSocketHandler;
    private final ChatAuthHandshakeInterceptor chatAuthHandshakeInterceptor;

    public WebSocketConfig(
            ChatWebSocketHandler chatWebSocketHandler,
            ChatAuthHandshakeInterceptor chatAuthHandshakeInterceptor) {
        this.chatWebSocketHandler = chatWebSocketHandler;
        this.chatAuthHandshakeInterceptor = chatAuthHandshakeInterceptor;
    }

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        registry.addHandler(chatWebSocketHandler, "/ws/chat")
                .addInterceptors(chatAuthHandshakeInterceptor)
                .setAllowedOriginPatterns("*");
    }
}
