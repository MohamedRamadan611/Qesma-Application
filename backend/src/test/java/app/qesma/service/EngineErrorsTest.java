package app.qesma.service;

import static org.assertj.core.api.Assertions.assertThat;

import app.qesma.api.ApiException;
import app.qesma.api.ErrorCode;
import app.qesma.engine.EngineErrorCode;
import app.qesma.engine.EngineException;
import org.junit.jupiter.api.Test;

/** Every engine error code maps to the matching spec 8.5 API code (422), so nothing falls through as a 500. */
class EngineErrorsTest {

    @Test
    void everyEngineCodeMapsToTheSameNamedApiCodeWith422() {
        for (EngineErrorCode engine : EngineErrorCode.values()) {
            ApiException api = EngineErrors.toApi(new EngineException(engine, "message"));
            assertThat(api.code().name()).as(engine.name()).isEqualTo(engine.name());
            assertThat(api.status().value()).isEqualTo(422);
            assertThat(api.getMessage()).isEqualTo("message");
        }
    }

    @Test
    void theTwoMismatchCodesAreDistinct() {
        assertThat(EngineErrors.toApi(new EngineException(EngineErrorCode.SPLIT_TOTAL_MISMATCH, "x")).code())
                .isEqualTo(ErrorCode.SPLIT_TOTAL_MISMATCH);
        assertThat(EngineErrors.toApi(new EngineException(EngineErrorCode.PAYERS_TOTAL_MISMATCH, "x")).code())
                .isEqualTo(ErrorCode.PAYERS_TOTAL_MISMATCH);
    }
}
