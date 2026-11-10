package app.qesma.service;

import app.qesma.api.ApiException;
import java.util.Locale;
import java.util.regex.Pattern;

/** Email addresses of password accounts: trimmed and lower-cased, so "Ali@X.com " and "ali@x.com" are one account. */
final class EmailRules {

    static final int MAX_LENGTH = 254;
    private static final int MAX_LOCAL_PART = 64;
    // local part, one @, then a dotted domain; no whitespace anywhere (the double backslashes are Java string escapes)
    private static final Pattern SHAPE = Pattern.compile("^[^@\\s]+@[^@\\s.]+(\\.[^@\\s.]+)+$");

    private EmailRules() {
    }

    /** Normalized address, or a 422 when it is not an address. */
    static String normalize(String raw) {
        String email = raw == null ? "" : raw.strip().toLowerCase(Locale.ROOT);
        if (!looksValid(email)) {
            throw ApiException.validation("email is not a valid address");
        }
        return email;
    }

    /** Normalized address, or null when the text cannot be an address (used where a failure must look like "no such account"). */
    static String normalizeOrNull(String raw) {
        String email = raw == null ? "" : raw.strip().toLowerCase(Locale.ROOT);
        return looksValid(email) ? email : null;
    }

    private static boolean looksValid(String email) {
        if (email.isEmpty() || email.length() > MAX_LENGTH || !SHAPE.matcher(email).matches()) {
            return false;
        }
        return email.indexOf('@') <= MAX_LOCAL_PART;
    }
}
