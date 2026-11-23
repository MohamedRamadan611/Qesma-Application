package app.qesma.engine;

import java.time.LocalDate;

/**
 * The optional inclusive period of a SHARES expense (A186). Both bounds are required; a record with one bound is
 * accepted here so the engine can reject it with {@link EngineErrorCode#VALIDATION_ERROR}.
 */
public record SharePeriod(LocalDate from, LocalDate to) {
}
