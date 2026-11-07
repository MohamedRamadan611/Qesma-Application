package app.qesma.security;

import app.qesma.api.ApiException;
import java.util.UUID;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.stereotype.Component;

/**
 * The single place that turns the authenticated request into a user id. Later authorization checks
 * (group ownership, Phase 2 roles) hang off this so controllers never read tokens themselves.
 */
@Component
public class CurrentUser {

    public UUID id() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (!(auth instanceof JwtAuthenticationToken jwtAuth)) {
            throw ApiException.unauthorized();
        }
        try {
            return UUID.fromString(jwtAuth.getToken().getSubject());
        } catch (IllegalArgumentException | NullPointerException e) {
            throw ApiException.unauthorized();
        }
    }
}
