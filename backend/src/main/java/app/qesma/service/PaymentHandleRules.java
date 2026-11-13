package app.qesma.service;

import app.qesma.api.ApiException;
import java.util.Locale;
import java.util.regex.Pattern;

/**
 * Input rules for payment handles (A90). A blank or missing value means "remove" and yields null. Everything else is
 * normalised to the stored form or rejected with 422 {@code VALIDATION_ERROR} naming the field; the message never
 * contains the value (personal data).
 */
final class PaymentHandleRules {

    static final int INSTAPAY_MIN = 3;
    static final int INSTAPAY_MAX = 60;

    private static final Pattern WALLET = Pattern.compile("01[0125][0-9]{8}");
    private static final Pattern INSTAPAY = Pattern.compile("[a-z0-9._-]+@[a-z0-9.-]+");

    private PaymentHandleRules() {
    }

    /** Egyptian mobile number to {@code 01XXXXXXXXX}: Arabic-Indic digits, spaces, dashes and +20/0020 accepted. */
    static String wallet(String raw) {
        if (raw == null || raw.isBlank()) {
            return null;
        }
        StringBuilder sb = new StringBuilder(raw.length());
        for (int i = 0; i < raw.length(); i++) {
            char c = raw.charAt(i);
            if (c >= 0x0660 && c <= 0x0669) {
                sb.append((char) ('0' + (c - 0x0660)));
            } else if (c >= 0x06F0 && c <= 0x06F9) {
                sb.append((char) ('0' + (c - 0x06F0)));
            } else if (c == ' ' || c == 0x00A0 || c == '-' || c == 0x2010 || c == 0x2011 || c == '\t') {
                continue;
            } else {
                sb.append(c);
            }
        }
        String s = sb.toString();
        if (s.startsWith("+20")) {
            s = "0" + s.substring(3);
        } else if (s.startsWith("0020")) {
            s = "0" + s.substring(4);
        }
        if (!WALLET.matcher(s).matches()) {
            throw ApiException.validation("wallet must be an Egyptian mobile number such as 01012345678");
        }
        return s;
    }

    /** {@code local@bank}, ASCII only, one {@code @}, no whitespace, 3..60 characters; stored in lower case. */
    static String instapay(String raw) {
        if (raw == null || raw.isBlank()) {
            return null;
        }
        String s = raw.strip();
        // ASCII is checked BEFORE lower-casing: U+212A (Kelvin sign) lower-cases to 'k' and would slip through.
        for (int i = 0; i < s.length(); i++) {
            if (s.charAt(i) > 127) {
                throw bad();
            }
        }
        if (s.length() < INSTAPAY_MIN || s.length() > INSTAPAY_MAX) {
            throw bad();
        }
        s = s.toLowerCase(Locale.ROOT);
        if (!INSTAPAY.matcher(s).matches() || s.indexOf('@') != s.lastIndexOf('@')) {
            throw bad();
        }
        return s;
    }

    private static ApiException bad() {
        return ApiException.validation("instapay must look like name@bank (3 to 60 letters, digits, dots, dashes)");
    }
}
