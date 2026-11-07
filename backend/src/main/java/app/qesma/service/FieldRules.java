package app.qesma.service;

import app.qesma.api.ApiException;
import java.util.Currency;
import java.util.Locale;
import java.util.Set;
import java.util.regex.Pattern;

/** Input rules shared by the group and member services. Failures are 422 VALIDATION_ERROR. */
final class FieldRules {

    static final int GROUP_NAME_MAX = 60;
    static final int MEMBER_NAME_MAX = 40;
    static final int PAGE_SIZE_MAX = 100;
    static final int PAGE_SIZE_DEFAULT = 20;
    static final String DEFAULT_CURRENCY = "EGP";
    static final Set<String> GROUP_TYPES = Set.of("TRIP", "HOUSING", "OUTING", "OTHER");

    private static final Pattern ISO_SHAPE = Pattern.compile("[A-Z]{3}");

    private FieldRules() {
    }

    /** Trimmed, 1 to {@code max} Unicode code points (so Arabic letters and emoji count once). */
    static String name(String raw, int max, String field) {
        String name = raw == null ? "" : raw.strip();
        if (name.isEmpty()) {
            throw ApiException.validation(field + " must not be blank");
        }
        if (name.codePointCount(0, name.length()) > max) {
            throw ApiException.validation(field + " must be at most " + max + " characters");
        }
        return name;
    }

    static String groupType(String raw) {
        String type = raw == null ? "" : raw.strip().toUpperCase(Locale.ROOT);
        if (!GROUP_TYPES.contains(type)) {
            throw ApiException.validation("type must be one of TRIP, HOUSING, OUTING, OTHER");
        }
        return type;
    }

    /** Null or blank means the default (EGP); otherwise a real ISO 4217 currency, normalized to upper case. */
    static String currency(String raw) {
        if (raw == null || raw.isBlank()) {
            return DEFAULT_CURRENCY;
        }
        String code = raw.strip().toUpperCase(Locale.ROOT);
        if (!ISO_SHAPE.matcher(code).matches()) {
            throw ApiException.validation("currencyCode must be a valid ISO 4217 code");
        }
        try {
            // Pseudo-currencies (XXX, XTS, precious metals) report -1 fraction digits and are not usable.
            if (Currency.getInstance(code).getDefaultFractionDigits() < 0) {
                throw ApiException.validation("currencyCode must be a valid ISO 4217 code");
            }
        } catch (IllegalArgumentException e) {
            throw ApiException.validation("currencyCode must be a valid ISO 4217 code");
        }
        return code;
    }

    static void page(int page, int size) {
        if (page < 0) {
            throw ApiException.validation("page must be 0 or greater");
        }
        if (size < 1 || size > PAGE_SIZE_MAX) {
            throw ApiException.validation("size must be between 1 and " + PAGE_SIZE_MAX);
        }
    }
}
