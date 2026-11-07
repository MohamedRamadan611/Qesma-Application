package app.qesma.security;

import app.qesma.api.ErrorCode;
import io.micrometer.core.instrument.MeterRegistry;
import java.time.Clock;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.server.resource.web.authentication.BearerTokenAuthenticationFilter;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.security.web.SecurityFilterChain;

/**
 * Stateless API security: auth endpoints, health/info and (local only) API docs are public; everything else
 * needs a valid access token. CORS is disabled (the only client is the mobile app). Every authentication
 * failure produces the same generic 401 problem+json.
 */
@Configuration
public class SecurityConfig {

    @Bean
    SecurityFilterChain securityFilterChain(HttpSecurity http, AuthenticationEntryPoint entryPoint,
            JwtDecoder accessTokenDecoder, AuthProperties props, Clock clock, ProblemJsonWriter problems,
            MeterRegistry metrics) throws Exception {
        http
            .csrf(AbstractHttpConfigurer::disable)
            .cors(AbstractHttpConfigurer::disable)
            .httpBasic(AbstractHttpConfigurer::disable)
            .formLogin(AbstractHttpConfigurer::disable)
            .logout(AbstractHttpConfigurer::disable)
            .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(a -> a
                .requestMatchers(HttpMethod.POST,
                        "/api/v1/auth/google", "/api/v1/auth/refresh", "/api/v1/auth/logout").permitAll()
                .requestMatchers("/actuator/health", "/actuator/health/**", "/actuator/info").permitAll()
                // springdoc endpoints only exist in the local profile; otherwise they 404 anyway.
                .requestMatchers("/v3/api-docs/**", "/swagger-ui/**", "/swagger-ui.html").permitAll()
                .anyRequest().authenticated())
            .oauth2ResourceServer(o -> o
                .jwt(j -> j.decoder(accessTokenDecoder))
                .authenticationEntryPoint(entryPoint))
            .exceptionHandling(e -> e.authenticationEntryPoint(entryPoint))
            // Built here (not a bean) so it is only part of the security chain, never registered twice.
            .addFilterBefore(new AuthRateLimitFilter(props.rateLimit(), clock, problems, metrics),
                    BearerTokenAuthenticationFilter.class);
        return http.build();
    }

    @Bean
    AuthenticationEntryPoint problemJsonEntryPoint(ProblemJsonWriter problems) {
        return (request, response, ex) ->
                problems.write(response, HttpStatus.UNAUTHORIZED, ErrorCode.UNAUTHORIZED, "Authentication required");
    }
}
