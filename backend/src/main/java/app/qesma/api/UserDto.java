package app.qesma.api;

import app.qesma.domain.User;
import java.util.UUID;

/** {@code username}: the sign-in name of a password account, else null. {@code hasPassword}: a password account (can change its password). {@code emailVerified}: Google, or the link was used. {@code notificationsEnabled}: the global notification switch (B16, A106). */
public record UserDto(UUID id, String displayName, String email, String username, boolean hasPassword,
                      boolean emailVerified, boolean notificationsEnabled) {

    public static UserDto from(User user, boolean notificationsEnabled) {
        return new UserDto(user.getId(), user.getDisplayName(), user.getEmail(), user.getUsername(), user.hasPassword(), user.isEmailVerified(), notificationsEnabled);
    }
}
