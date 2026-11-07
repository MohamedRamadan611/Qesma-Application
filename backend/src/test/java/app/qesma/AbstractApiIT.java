package app.qesma;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.request;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

/**
 * Helpers for API integration tests against real PostgreSQL. Concrete classes add @SpringBootTest,
 * @AutoConfigureMockMvc and @ActiveProfiles({"test", "fake-auth"}). Each test signs up its own users with
 * random Google subjects, so tests are independent and can share one database.
 */
public abstract class AbstractApiIT extends AbstractIntegrationTest {

    @Autowired protected MockMvc mvc;
    @Autowired protected ObjectMapper json;
    @Autowired protected JdbcTemplate jdbc;

    protected record Session(String accessToken, UUID userId) {
    }

    protected Session newUser() throws Exception {
        String sub = "sub-" + UUID.randomUUID();
        MvcResult r = mvc.perform(request(HttpMethod.POST, "/api/v1/auth/google")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"idToken\":\"fake:" + sub + ":" + sub + "@example.com:Tester\"}")).andReturn();
        JsonNode body = body(r);
        return new Session(body.get("accessToken").asText(), UUID.fromString(body.get("user").get("id").asText()));
    }

    /** Performs a request as {@code as} (null = anonymous). Extra headers are name/value pairs. */
    protected MvcResult call(HttpMethod method, String path, Session as, Object body, String... headers)
            throws Exception {
        MockHttpServletRequestBuilder b = request(method, path).contentType(MediaType.APPLICATION_JSON);
        if (as != null) {
            b.header("Authorization", "Bearer " + as.accessToken());
        }
        for (int i = 0; i + 1 < headers.length; i += 2) {
            b.header(headers[i], headers[i + 1]);
        }
        if (body != null) {
            b.content(body instanceof String s ? s : json.writeValueAsString(body));
        }
        return mvc.perform(b).andReturn();
    }

    protected JsonNode body(MvcResult r) throws Exception {
        String text = r.getResponse().getContentAsString();
        return text.isEmpty() ? json.nullNode() : json.readTree(text);
    }

    protected int status(MvcResult r) {
        return r.getResponse().getStatus();
    }

    protected String code(MvcResult r) throws Exception {
        return body(r).path("code").asText();
    }

    protected JsonNode createGroup(Session as, String name) throws Exception {
        MvcResult r = call(HttpMethod.POST, "/api/v1/groups", as,
                java.util.Map.of("name", name, "type", "TRIP"));
        if (status(r) != 201) {
            throw new AssertionError("create group failed: " + status(r) + " " + r.getResponse().getContentAsString());
        }
        return body(r);
    }

    protected JsonNode addMember(Session as, String groupId, String name) throws Exception {
        MvcResult r = call(HttpMethod.POST, "/api/v1/groups/" + groupId + "/members", as,
                java.util.Map.of("displayName", name));
        if (status(r) != 201) {
            throw new AssertionError("add member failed: " + status(r) + " " + r.getResponse().getContentAsString());
        }
        return body(r);
    }

    protected String etagOf(MvcResult r) {
        return r.getResponse().getHeader("ETag");
    }

    /** A problem+json body without the per-request id, for comparing two error responses. */
    protected JsonNode problemWithoutRequestId(MvcResult r) throws Exception {
        com.fasterxml.jackson.databind.node.ObjectNode node = (com.fasterxml.jackson.databind.node.ObjectNode) body(r);
        node.remove("requestId");
        return node;
    }
}
