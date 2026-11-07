package app.qesma.security;

import app.qesma.api.ErrorCode;
import app.qesma.api.RequestIdFilter;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.LinkedHashMap;
import java.util.Map;
import org.slf4j.MDC;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;

/** Writes RFC 7807 problem+json from servlet filters, where {@code @RestControllerAdvice} does not apply. */
@Component
public class ProblemJsonWriter {

    private final ObjectMapper mapper;

    public ProblemJsonWriter(ObjectMapper mapper) {
        this.mapper = mapper;
    }

    public void write(HttpServletResponse response, HttpStatus status, ErrorCode code, String title)
            throws IOException {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("type", code.type().toString());
        body.put("title", title);
        body.put("status", status.value());
        body.put("code", code.name());
        body.put("requestId", MDC.get(RequestIdFilter.MDC_KEY));
        response.setStatus(status.value());
        response.setContentType(MediaType.APPLICATION_PROBLEM_JSON_VALUE);
        mapper.writeValue(response.getOutputStream(), body);
    }
}
