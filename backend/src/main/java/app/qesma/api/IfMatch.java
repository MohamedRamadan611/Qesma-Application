package app.qesma.api;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

/** Parses an {@code If-Match} header carrying an entity version: {@code "3"}, {@code W/"3"} or bare {@code 3}. */
final class IfMatch {

    private static final Pattern VERSION = Pattern.compile("^(?:(?:W/)?\"(\\d{1,9})\"|(\\d{1,9}))$");

    private IfMatch() {
    }

    /** Missing header => 428; present but not a version (including {@code *} or a list) => 422. */
    static int version(String header) {
        if (header == null || header.isBlank()) {
            throw ApiException.preconditionRequired("If-Match header with the current version is required");
        }
        Matcher m = VERSION.matcher(header.strip());
        if (!m.matches()) {
            throw ApiException.validation("If-Match must contain a single version, e.g. \"3\"");
        }
        return Integer.parseInt(m.group(1) != null ? m.group(1) : m.group(2));
    }
}
