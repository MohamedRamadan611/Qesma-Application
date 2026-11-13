package app.qesma.service;

import app.qesma.api.ApiException;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Base64;
import java.util.UUID;

/**
 * The opaque {@code before} cursor of the activity feed and the notification center (A101): base64url (no padding) of
 * {@code "<createdAt in epoch microseconds>:<uuid>"}. Microseconds, because PostgreSQL stores no finer time, so the
 * value round-trips exactly. Anything else is 422 VALIDATION_ERROR.
 */
record ActivityCursor(Instant createdAt, UUID id) {

    private static final long MAX_MICROS = 253_402_300_799_999_999L;   // year 9999
    private static final int MAX_LENGTH = 100;

    String encode() {
        long micros = createdAt.getEpochSecond() * 1_000_000L + createdAt.getNano() / 1_000;
        return Base64.getUrlEncoder().withoutPadding()
                .encodeToString((micros + ":" + id).getBytes(StandardCharsets.UTF_8));
    }

    static ActivityCursor decode(String raw) {
        try {
            if (raw == null || raw.isEmpty() || raw.length() > MAX_LENGTH) {
                throw new IllegalArgumentException("size");
            }
            String text = new String(Base64.getUrlDecoder().decode(raw), StandardCharsets.UTF_8);
            int colon = text.indexOf(':');
            if (colon <= 0) {
                throw new IllegalArgumentException("shape");
            }
            long micros = Long.parseLong(text.substring(0, colon));
            if (micros < 0 || micros > MAX_MICROS) {
                throw new IllegalArgumentException("range");
            }
            UUID id = UUID.fromString(text.substring(colon + 1));
            Instant at = Instant.ofEpochSecond(Math.floorDiv(micros, 1_000_000L),
                    Math.floorMod(micros, 1_000_000L) * 1_000L);
            return new ActivityCursor(at, id);
        } catch (IllegalArgumentException e) {   // also NumberFormatException; the cause is never echoed
            throw ApiException.validation("before is not a valid cursor");
        }
    }
}
