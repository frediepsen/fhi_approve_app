package com.fhi.approve.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

import java.util.List;

@ConfigurationProperties(prefix = "app")
public record AppProperties(Jwt jwt, List<String> corsOrigins) {
    public record Jwt(String secret, long expirationHours) {
    }
}
