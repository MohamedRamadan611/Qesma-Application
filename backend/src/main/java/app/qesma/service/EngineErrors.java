package app.qesma.service;

import app.qesma.api.ApiException;
import app.qesma.api.ErrorCode;
import app.qesma.engine.EngineException;
import org.springframework.http.HttpStatus;

/**
 * The one place that turns engine rule violations into API errors (spec 8.5). The engine knows nothing about
 * HTTP; its messages contain no personal data and are safe to show.
 */
final class EngineErrors {

    private EngineErrors() {
    }

    static ApiException toApi(EngineException e) {
        return switch (e.code()) {
            case SPLIT_TOTAL_MISMATCH ->
                    new ApiException(ErrorCode.SPLIT_TOTAL_MISMATCH, HttpStatus.UNPROCESSABLE_ENTITY, e.getMessage());
            case PAYERS_TOTAL_MISMATCH ->
                    new ApiException(ErrorCode.PAYERS_TOTAL_MISMATCH, HttpStatus.UNPROCESSABLE_ENTITY, e.getMessage());
            case MEMBER_NOT_IN_GROUP ->
                    new ApiException(ErrorCode.MEMBER_NOT_IN_GROUP, HttpStatus.UNPROCESSABLE_ENTITY, e.getMessage());
            case VALIDATION_ERROR -> ApiException.validation(e.getMessage());
        };
    }
}
