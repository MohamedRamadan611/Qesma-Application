package app.qesma.service;

import java.security.SecureRandom;
import java.util.Locale;
import java.util.regex.Pattern;

/**
 * The invite code: 8 characters from a 32-symbol alphabet without look-alikes (no 0/O, 1/I), about 2^40 values,
 * from a {@link SecureRandom}. People type it (shown as {@code XXXX-XXXX}) and the link carries it, so input is
 * normalised: trimmed, dashes and spaces removed, upper-cased, Arabic-Indic digits turned into Western ones.
 */
public final class InviteCodes {

    public static final String ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
    public static final int LENGTH = 8;
    private static final Pattern SHAPE = Pattern.compile("[A-HJ-NP-Z2-9]{8}");
    private static final SecureRandom RANDOM = new SecureRandom();

    private InviteCodes() {
    }

    public static String generate() {
        StringBuilder sb = new StringBuilder(LENGTH);
        for (int i = 0; i < LENGTH; i++) {
            sb.append(ALPHABET.charAt(RANDOM.nextInt(ALPHABET.length()))); // 32 symbols: no modulo bias
        }
        return sb.toString();
    }

    /** The stored form of what a person typed or a link carried, or {@code null} when it cannot be a code. */
    public static String normalize(String raw) {
        if (raw == null) {
            return null;
        }
        StringBuilder sb = new StringBuilder();
        for (char c : raw.strip().toCharArray()) {
            if (c == '-' || c == '–' || c == ' ' || c == '‏' || c == '‎') {
                continue;
            }
            if (c >= '٠' && c <= '٩') {          // Arabic-Indic digits
                c = (char) ('0' + (c - '٠'));
            } else if (c >= '۰' && c <= '۹') {   // Eastern Arabic-Indic digits
                c = (char) ('0' + (c - '۰'));
            }
            sb.append(c);
        }
        String code = sb.toString().toUpperCase(Locale.ROOT);
        return SHAPE.matcher(code).matches() ? code : null;
    }

    /** {@code ABCD2345} -> {@code ABCD-2345}, for display. */
    public static String display(String code) {
        return code.substring(0, 4) + "-" + code.substring(4);
    }
}
