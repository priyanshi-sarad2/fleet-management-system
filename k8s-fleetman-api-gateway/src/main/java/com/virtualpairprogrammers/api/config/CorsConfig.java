package com.virtualpairprogrammers.api.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * Global CORS configuration for the REST endpoints.
 *
 * The webapp is served from a different origin (CloudFront/S3) than this API,
 * so the browser needs an Access-Control-Allow-Origin response. The allowed
 * origin(s) come from the ALLOWED_ORIGINS env var (comma-separated), supplied
 * via the api-gateway ConfigMap, so the same image works in any environment.
 * Defaults to "*" when the env var is not set.
 */
@Configuration
public class CorsConfig implements WebMvcConfigurer
{
    @Value("${ALLOWED_ORIGINS:*}")
    private String allowedOrigins;

    @Override
    public void addCorsMappings(CorsRegistry registry)
    {
        registry.addMapping("/**")
                .allowedOriginPatterns(allowedOrigins.split(","))
                .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                .allowedHeaders("*");
    }
}
