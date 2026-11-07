package app.qesma.service;

import app.qesma.api.ApiException;
import app.qesma.domain.User;
import app.qesma.persistence.UserRepository;
import app.qesma.security.GoogleIdentity;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserService {

    private final UserRepository users;

    public UserService(UserRepository users) {
        this.users = users;
    }

    /**
     * Finds the user for a verified Google identity, creating it on first sign-in. Safe under concurrent
     * first logins: the unique constraint on (auth_provider, auth_subject) decides, exactly one row results.
     */
    @Transactional
    public User upsertGoogleUser(GoogleIdentity identity) {
        users.insertIfAbsent(UUID.randomUUID(), User.PROVIDER_GOOGLE, identity.subject(), identity.email(),
                DisplayNames.forNewUser(identity.displayName(), identity.email()));
        return users.findByAuthProviderAndAuthSubject(User.PROVIDER_GOOGLE, identity.subject())
                .orElseThrow(() -> new IllegalStateException("User missing right after upsert"));
    }

    @Transactional(readOnly = true)
    public User get(UUID userId) {
        // A valid token for a user that no longer exists is treated as unauthenticated.
        return users.findById(userId).orElseThrow(ApiException::unauthorized);
    }

    @Transactional
    public User updateDisplayName(UUID userId, String rawDisplayName) {
        String name = DisplayNames.validated(rawDisplayName);
        User user = users.findById(userId).orElseThrow(ApiException::unauthorized);
        user.setDisplayName(name);
        return user;
    }
}
