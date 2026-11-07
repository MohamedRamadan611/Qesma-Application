package app.qesma.api;

import app.qesma.domain.User;
import java.util.UUID;

public record UserDto(UUID id, String displayName, String email) {

    public static UserDto from(User user) {
        return new UserDto(user.getId(), user.getDisplayName(), user.getEmail());
    }
}
