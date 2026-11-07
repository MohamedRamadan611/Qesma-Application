package app.qesma.engine;

/** Typed, unchecked failure for any rule violation inside the engine. Messages contain no personal data. */
public final class EngineException extends RuntimeException {

    private static final long serialVersionUID = 1L;

    private final EngineErrorCode code;

    public EngineException(EngineErrorCode code, String message) {
        super(message);
        this.code = code;
    }

    public EngineException(EngineErrorCode code, String message, Throwable cause) {
        super(message, cause);
        this.code = code;
    }

    public EngineErrorCode code() {
        return code;
    }

    static EngineException invalid(String message) {
        return new EngineException(EngineErrorCode.VALIDATION_ERROR, message);
    }
}
