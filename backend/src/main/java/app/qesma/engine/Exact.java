package app.qesma.engine;

/** Overflow-checked arithmetic that reports overflow as a typed {@link EngineException}. */
final class Exact {

    private Exact() {
    }

    static long add(long a, long b) {
        try {
            return Math.addExact(a, b);
        } catch (ArithmeticException e) {
            throw new EngineException(EngineErrorCode.VALIDATION_ERROR, "Amount too large", e);
        }
    }

    static long negate(long a) {
        try {
            return Math.negateExact(a);
        } catch (ArithmeticException e) {
            throw new EngineException(EngineErrorCode.VALIDATION_ERROR, "Amount too large", e);
        }
    }
}
