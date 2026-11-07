package app.qesma.engine;

/**
 * Engine-local error codes. Names mirror the stable API codes of spec 8.5 so the api layer can
 * map them one-to-one; the engine itself must not depend on the api package.
 */
public enum EngineErrorCode {
    /** Malformed or out-of-range input, including arithmetic overflow. */
    VALIDATION_ERROR,
    /** EXACT shares do not sum to the expense total (spec 7.3). */
    SPLIT_TOTAL_MISMATCH,
    /** Payer amounts do not sum to the expense total (spec 7.5). */
    PAYERS_TOTAL_MISMATCH,
    /** A referenced member is not part of the supplied roster. */
    MEMBER_NOT_IN_GROUP
}
