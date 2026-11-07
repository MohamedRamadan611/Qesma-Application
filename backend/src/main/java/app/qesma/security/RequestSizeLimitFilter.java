package app.qesma.security;

import app.qesma.api.ErrorCode;
import io.micrometer.core.instrument.MeterRegistry;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ReadListener;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletInputStream;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletRequestWrapper;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.web.filter.OncePerRequestFilter;

/**
 * Caps the request body of every API call (basic abuse protection, B5). A declared Content-Length over the limit
 * is rejected immediately with 413 problem+json; a body without a length (chunked) is counted as it is read and
 * fails with {@link RequestTooLargeException}, which the global handler turns into the same 413.
 */
public class RequestSizeLimitFilter extends OncePerRequestFilter {

    /** Far above any legitimate bill (100 items x 100 assignees is about 40 KB of JSON). */
    public static final long MAX_BODY_BYTES = 64 * 1024;

    private static final Logger log = LoggerFactory.getLogger(RequestSizeLimitFilter.class);

    private final long maxBytes;
    private final ProblemJsonWriter problems;
    private final MeterRegistry metrics;

    public RequestSizeLimitFilter(long maxBytes, ProblemJsonWriter problems, MeterRegistry metrics) {
        this.maxBytes = maxBytes;
        this.problems = problems;
        this.metrics = metrics;
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        return !request.getRequestURI().startsWith("/api/v1/");
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        if (request.getContentLengthLong() > maxBytes) {
            metrics.counter("qesma.request_too_large").increment();
            log.atWarn().addKeyValue("event", "request.too_large").log("request.too_large");
            problems.write(response, HttpStatus.PAYLOAD_TOO_LARGE, ErrorCode.VALIDATION_ERROR,
                    "Request body is too large");
            return;
        }
        chain.doFilter(new Limited(request, maxBytes), response);
    }

    /** Thrown while reading a body that grows past the limit without having declared its length. */
    public static final class RequestTooLargeException extends IOException {
        private static final long serialVersionUID = 1L;

        RequestTooLargeException() {
            super("Request body is too large");
        }
    }

    private static final class Limited extends HttpServletRequestWrapper {
        private final long max;
        private ServletInputStream stream;

        Limited(HttpServletRequest request, long max) {
            super(request);
            this.max = max;
        }

        @Override
        public ServletInputStream getInputStream() throws IOException {
            if (stream == null) {
                stream = new Counting(super.getInputStream(), max);
            }
            return stream;
        }
    }

    private static final class Counting extends ServletInputStream {
        private final ServletInputStream in;
        private final long max;
        private long read;

        Counting(ServletInputStream in, long max) {
            this.in = in;
            this.max = max;
        }

        private void count(long n) throws IOException {
            if (n > 0) {
                read += n;
                if (read > max) {
                    throw new RequestTooLargeException();
                }
            }
        }

        @Override
        public int read() throws IOException {
            int b = in.read();
            count(b < 0 ? 0 : 1);
            return b;
        }

        @Override
        public int read(byte[] buf, int off, int len) throws IOException {
            int n = in.read(buf, off, len);
            count(n);
            return n;
        }

        @Override
        public boolean isFinished() {
            return in.isFinished();
        }

        @Override
        public boolean isReady() {
            return in.isReady();
        }

        @Override
        public void setReadListener(ReadListener listener) {
            in.setReadListener(listener);
        }
    }
}
