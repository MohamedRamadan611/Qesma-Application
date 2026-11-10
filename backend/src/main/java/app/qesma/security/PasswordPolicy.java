package app.qesma.security;

import app.qesma.api.ApiException;
import java.nio.charset.StandardCharsets;
import java.util.Locale;
import java.util.Set;

/**
 * What a password must look like (ADR-007). Length is counted in characters at the low end and in UTF-8 bytes at the
 * high end, because BCrypt only reads the first 72 bytes (an Arabic letter is 2 bytes). Rules that make people
 * choose worse passwords (symbol and case mixing) are deliberately absent; the most common passwords are refused.
 */
public final class PasswordPolicy {

    public static final int MIN_CHARACTERS = 8;
    public static final int MAX_BYTES = 72;

    /** The most used passwords (lower case). A short list on purpose: a screen, not a database. */
    private static final Set<String> COMMON = Set.of(
            "password", "password1", "password12", "password123", "12345678", "123456789", "1234567890", "qwertyui",
            "qwerty123", "qwertyuiop", "11111111", "00000000", "iloveyou", "abc12345", "abcd1234", "admin123",
            "welcome1", "letmein123", "monkey123", "dragon123", "football1", "baseball1", "sunshine1", "princess1",
            "master123", "login1234", "passw0rd", "p@ssw0rd", "p@ssword", "123123123", "987654321", "1q2w3e4r",
            "1qaz2wsx", "zaq12wsx", "qazwsxedc", "asdfghjk", "asdf1234", "12341234", "123456789a", "a1234567",
            "aa123456", "qesma123", "qesma1234", "mohamed123", "ahmed123", "mahmoud123", "egypt123", "cairo123");

    private PasswordPolicy() {
    }

    /** Throws a client-visible validation error (never echoing the password) when [password] is not acceptable. */
    public static void check(String password, String email) {
        if (password == null || password.isBlank()) {
            throw ApiException.validation("password must not be blank");
        }
        if (password.codePointCount(0, password.length()) < MIN_CHARACTERS) {
            throw ApiException.validation("password must be at least " + MIN_CHARACTERS + " characters");
        }
        if (password.getBytes(StandardCharsets.UTF_8).length > MAX_BYTES) {
            throw ApiException.validation("password must be at most " + MAX_BYTES
                    + " bytes (about 72 Latin or 36 Arabic characters)");
        }
        String lower = password.toLowerCase(Locale.ROOT);
        if (email != null && lower.equals(email.toLowerCase(Locale.ROOT))) {
            throw ApiException.validation("password must not be your email address");
        }
        if (COMMON.contains(lower)) {
            throw ApiException.validation("password is too common, choose another one");
        }
    }
}
