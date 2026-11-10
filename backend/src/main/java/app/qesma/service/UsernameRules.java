package app.qesma.service;

import app.qesma.api.ApiException;
import java.util.Locale;
import java.util.Set;
import java.util.regex.Pattern;

/**
 * Sign-in names of password accounts (ADR-008): 3 to 30 characters, letters (any script, so Arabic works) and digits, with
 * dots, hyphens and underscores inside; trimmed and lower-cased, so "Ali.H" and "ali.h" are one account. No "@", so a
 * username can never be mistaken for an email address. A few names that look official are reserved.
 */
final class UsernameRules {

    static final int MIN_LENGTH = 3;
    static final int MAX_LENGTH = 30;
    private static final Pattern SHAPE = Pattern.compile("^[\\p{L}\\p{N}][\\p{L}\\p{N}._-]*$");
    private static final Set<String> RESERVED = Set.of("admin", "administrator", "root", "support", "qesma", "system",
            "moderator", "owner", "staff", "help", "null", "undefined");

    private UsernameRules() {
    }

    /** Normalized username, or a 422 when the name is not acceptable. */
    static String normalize(String raw) {
        String name = raw == null ? "" : raw.strip().toLowerCase(Locale.ROOT);
        int length = name.codePointCount(0, name.length());
        if (length < MIN_LENGTH || length > MAX_LENGTH || !SHAPE.matcher(name).matches() || name.endsWith(".")) {
            throw ApiException.validation("username must be " + MIN_LENGTH + " to " + MAX_LENGTH
                    + " characters: letters, digits, dots, hyphens and underscores, starting with a letter or digit");
        }
        if (RESERVED.contains(name)) {
            throw ApiException.validation("this username is reserved");
        }
        return name;
    }

    /**
     * The form of what someone typed at sign-in (trimmed, lower-case), or null when it cannot be a sign-in name. Lenient on
     * purpose: it must also find the few accounts made with an email address before usernames existed.
     */
    static String lookupKey(String raw) {
        String name = raw == null ? "" : raw.strip().toLowerCase(Locale.ROOT);
        return name.isEmpty() || name.length() > 254 || name.chars().anyMatch(Character::isWhitespace) ? null : name;
    }
}
