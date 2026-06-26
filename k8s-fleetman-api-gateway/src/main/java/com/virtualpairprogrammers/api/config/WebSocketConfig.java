package com.virtualpairprogrammers.api.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer
{
    // Allowed origins for the WebSocket/SockJS handshake. Comes from the
    // ALLOWED_ORIGINS env var (comma-separated) so it matches the REST CORS config.
    // Defaults to "*" when not set.
    @Value("${ALLOWED_ORIGINS:*}")
    private String allowedOrigins;

    @Override
    public void configureMessageBroker(MessageBrokerRegistry config)
    {
        config.enableSimpleBroker("/vehiclepositions");
        config.setApplicationDestinationPrefixes("/app");
    }

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry)
    {
        String[] origins = allowedOrigins.split(",");
        registry.addEndpoint("/updates").setAllowedOriginPatterns(origins).withSockJS();
        registry.addEndpoint("/updates").setAllowedOriginPatterns(origins);
    }
}
