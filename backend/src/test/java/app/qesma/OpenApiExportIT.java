package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;

import app.qesma.api.ErrorCode;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;

/**
 * The OpenAPI contract the mobile client is generated from (B8). The app itself produces the document; the committed
 * {@code docs/openapi.json} must equal it, so the contract can never drift silently. Regenerate with:
 * {@code ./mvnw -o verify -Dit.test=OpenApiExportIT -Dtest=NoSuchTest -Dsurefire.failIfNoSpecifiedTests=false
 * -Dopenapi.write=true}. Also compares the real routes with the endpoint list of spec section 8.2.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "fake-auth"})
@TestPropertySource(properties = "springdoc.api-docs.enabled=true")
class OpenApiExportIT extends AbstractIntegrationTest {

    private static final Path COMMITTED = Path.of("..", "docs", "openapi.json");
    private static final Path SPEC = Path.of("..", "docs", "PROJECT_SPEC.md");
    private static final Set<String> METHODS = Set.of("get", "post", "put", "patch", "delete");

    @Autowired MockMvc mvc;

    private final ObjectMapper pretty = new ObjectMapper().enable(SerializationFeature.INDENT_OUTPUT)
            .enable(SerializationFeature.ORDER_MAP_ENTRIES_BY_KEYS);

    private JsonNode generated() throws Exception {
        String json = mvc.perform(get("/v3/api-docs")).andReturn().getResponse().getContentAsString();
        assertThat(json).as("springdoc must be serving the document").startsWith("{");
        return new ObjectMapper().readTree(json);
    }

    private String canonical(JsonNode doc) throws Exception {
        Object tree = new ObjectMapper().treeToValue(doc, Object.class);
        return pretty.writeValueAsString(tree).replace("\r\n", "\n") + "\n";
    }

    @Test
    void theCommittedOpenApiFileEqualsTheOneTheAppGenerates() throws Exception {
        String actual = canonical(generated());
        if (Boolean.getBoolean("openapi.write")) {
            Files.writeString(COMMITTED, actual);
        }
        assertThat(COMMITTED).as("docs/openapi.json must exist: regenerate with -Dopenapi.write=true").exists();
        String committed = Files.readString(COMMITTED).replace("\r\n", "\n");
        assertThat(actual).as("docs/openapi.json is out of date: regenerate with -Dopenapi.write=true")
                .isEqualTo(committed);
    }

    /** "METHOD /api/v1/path" for every operation in the generated document. */
    private Set<String> operations(JsonNode doc) {
        Set<String> out = new TreeSet<>();
        Iterator<Map.Entry<String, JsonNode>> paths = doc.get("paths").fields();
        while (paths.hasNext()) {
            Map.Entry<String, JsonNode> path = paths.next();
            Iterator<String> methods = path.getValue().fieldNames();
            while (methods.hasNext()) {
                String m = methods.next();
                if (METHODS.contains(m)) {
                    out.add(m.toUpperCase() + " " + path.getKey());
                }
            }
        }
        return out;
    }

    @Test
    void everyEndpointOfSpecSection82ExistsAndNothingExtraIsExposed() throws Exception {
        String spec = Files.readString(SPEC);
        int start = spec.indexOf("### 8.2 Endpoints");
        int end = spec.indexOf("### 8.3", start);
        Matcher m = Pattern.compile("(?m)^(GET|POST|PUT|PATCH|DELETE)\\s+(/\\S+)").matcher(spec.substring(start, end));
        Set<String> expected = new TreeSet<>();
        while (m.find()) {
            expected.add(m.group(1) + " /api/v1" + m.group(2));
        }
        assertThat(expected).as("parsed the endpoint list of spec 8.2").hasSizeGreaterThan(20);

        assertThat(operations(generated())).isEqualTo(expected);
    }

    @Test
    void everyErrorCodeAndTheMoneyUnitsAreDocumented() throws Exception {
        JsonNode doc = generated();
        List<String> codes = new ArrayList<>();
        doc.at("/components/schemas/Problem/properties/code/enum").forEach(c -> codes.add(c.asText()));
        for (ErrorCode code : ErrorCode.values()) {
            assertThat(codes).contains(code.name());
            // ... and at least one operation says it can return it
            assertThat(doc.toString()).as("operation responses mention " + code).contains("code: ")
                    .contains(code.name());
        }
        assertThat(doc.at("/components/securitySchemes/bearerAuth/scheme").asText()).isEqualTo("bearer");
        // auth operations carry no security, every other one inherits the bearer requirement
        assertThat(doc.at("/paths/~1api~1v1~1auth~1google/post/security").size()).isZero();
        assertThat(doc.at("/security/0/bearerAuth").isArray()).isTrue();
        // every *Minor property says integer minor units
        doc.at("/components/schemas").fields().forEachRemaining(schema -> {
            JsonNode props = schema.getValue().get("properties");
            if (props == null) {
                return;
            }
            props.fields().forEachRemaining(p -> {
                if (p.getKey().endsWith("Minor")) {
                    assertThat(p.getValue().get("type").asText()).as(schema.getKey() + "." + p.getKey())
                            .isEqualTo("integer");
                    assertThat(p.getValue().path("format").asText()).as(schema.getKey() + "." + p.getKey())
                            .isEqualTo("int64");
                    assertThat(p.getValue().path("description").asText()).contains("minor units");
                }
            });
        });
        // creates and edits state their required headers; the three split types have request examples
        JsonNode create = doc.at("/paths/~1api~1v1~1groups~1{gid}~1expenses/post");
        assertThat(create.toString()).contains("Idempotency-Key").contains("\"EQUAL\"").contains("\"EXACT\"")
                .contains("\"ITEMIZED\"");
        assertThat(doc.at("/paths/~1api~1v1~1groups~1{gid}~1expenses~1{eid}/put").toString()).contains("If-Match");
        assertThat(doc.at("/paths/~1api~1v1~1groups~1{gid}~1expenses/post/responses/201/content/application~1json/schema")
                .toString()).contains("ExpenseView");
    }
}
