package app.qesma.security;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.fasterxml.jackson.databind.ObjectMapper;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import jakarta.servlet.ServletInputStream;
import java.nio.charset.StandardCharsets;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockFilterChain;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

class RequestSizeLimitFilterTest {

    private final RequestSizeLimitFilter filter = new RequestSizeLimitFilter(100, new ProblemJsonWriter(new ObjectMapper()),
            new SimpleMeterRegistry());

    private static MockHttpServletRequest post(String path, byte[] body) {
        MockHttpServletRequest request = new MockHttpServletRequest("POST", path);
        request.setContent(body);
        return request;
    }

    @Test
    void aDeclaredLengthOverTheLimitIsRejectedWith413AndNeverReachesTheController() throws Exception {
        MockHttpServletResponse response = new MockHttpServletResponse();
        MockFilterChain chain = new MockFilterChain();
        filter.doFilter(post("/api/v1/groups/x/expenses", new byte[101]), response, chain);

        assertThat(response.getStatus()).isEqualTo(413);
        assertThat(response.getContentType()).startsWith("application/problem+json");
        assertThat(response.getContentAsString()).contains("\"code\":\"VALIDATION_ERROR\"");
        assertThat(chain.getRequest()).isNull();
    }

    @Test
    void aBodyAtTheLimitPassesThroughUnchanged() throws Exception {
        MockHttpServletResponse response = new MockHttpServletResponse();
        MockFilterChain chain = new MockFilterChain();
        byte[] body = "x".repeat(100).getBytes(StandardCharsets.UTF_8);
        filter.doFilter(post("/api/v1/groups/x/expenses", body), response, chain);

        assertThat(response.getStatus()).isEqualTo(200);
        ServletInputStream in = ((jakarta.servlet.http.HttpServletRequest) chain.getRequest()).getInputStream();
        assertThat(in.readAllBytes()).hasSize(100);
    }

    @Test
    void aBodyWithoutADeclaredLengthIsCountedWhileReadAndFailsOnceItGrowsPastTheLimit() throws Exception {
        // an unknown length (-1), like a chunked upload
        MockHttpServletRequest chunked = new MockHttpServletRequest("POST", "/api/v1/groups/x/expenses") {
            @Override
            public long getContentLengthLong() {
                return -1;
            }
        };
        chunked.setContent(new byte[500]);
        MockFilterChain chain = new MockFilterChain();
        filter.doFilter(chunked, new MockHttpServletResponse(), chain);

        ServletInputStream in = ((jakarta.servlet.http.HttpServletRequest) chain.getRequest()).getInputStream();
        assertThatThrownBy(in::readAllBytes).isInstanceOf(RequestSizeLimitFilter.RequestTooLargeException.class);
    }

    @Test
    void nonApiPathsAreLeftAlone() throws Exception {
        MockHttpServletResponse response = new MockHttpServletResponse();
        MockFilterChain chain = new MockFilterChain();
        filter.doFilter(post("/actuator/health", new byte[1000]), response, chain);
        assertThat(response.getStatus()).isEqualTo(200);
        assertThat(chain.getRequest()).isNotNull();
    }
}
