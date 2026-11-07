package app.qesma.service;

import app.qesma.api.ApiException;

/** Display-name rules: trimmed, 1 to 60 characters (Unicode code points, so Arabic and emoji count once). */
final class DisplayNames {

    static final int MAX_LENGTH = 60;
    static final String FALLBACK = "Qesma user";

    private DisplayNames() {
    }

    /** Name for a first-time Google user: Google's name, else the verified email's local part, else a placeholder. */
    static String forNewUser(String googleName, String verifiedEmail) {
        String name = clean(googleName);
        if (name.isEmpty() && verifiedEmail != null) {
            int at = verifiedEmail.indexOf('@');
            name = clean(at > 0 ? verifiedEmail.substring(0, at) : verifiedEmail);
        }
        return name.isEmpty() ? FALLBACK : name;
    }

    /** User-supplied name for PATCH /me: rejects blank or over-long input instead of silently cutting it. */
    static String validated(String raw) {
        String name = raw == null ? "" : raw.strip();
        if (name.isEmpty()) {
            throw ApiException.validation("displayName must not be blank");
        }
        if (name.codePointCount(0, name.length()) > MAX_LENGTH) {
            throw ApiException.validation("displayName must be at most " + MAX_LENGTH + " characters");
        }
        return name;
    }

    /** Strips, then cuts to the maximum length on a code point boundary. */
    private static String clean(String raw) {
        if (raw == null) {
            return "";
        }
        String s = raw.strip();
        if (s.codePointCount(0, s.length()) > MAX_LENGTH) {
            s = s.substring(0, s.offsetByCodePoints(0, MAX_LENGTH)).strip();
        }
        return s;
    }
}
