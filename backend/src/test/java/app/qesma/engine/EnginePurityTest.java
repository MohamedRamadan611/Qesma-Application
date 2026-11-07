package app.qesma.engine;

import static org.assertj.core.api.Assertions.assertThat;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.regex.Pattern;
import java.util.stream.Stream;
import org.junit.jupiter.api.Test;

/** Guards AGENTS.md invariants 1 and 3: engine is framework-free, I/O-free and float-free. */
class EnginePurityTest {

    private static final Path ENGINE_SRC = Path.of("src", "main", "java", "app", "qesma", "engine");

    private static final Pattern FORBIDDEN_IMPORT = Pattern.compile(
            "^import\\s+(static\\s+)?(org\\.springframework|org\\.hibernate|jakarta|javax|java\\.sql|java\\.io|java\\.net|java\\.nio|org\\.slf4j|com\\.fasterxml)\\b.*");

    private static final Pattern FORBIDDEN_TYPE = Pattern.compile("\\b(double|float|Double|Float|BigDecimal)\\b");

    @Test
    void engineSourcesUseNoFrameworkIoOrFloatingPoint() throws IOException {
        List<Path> files;
        try (Stream<Path> s = Files.walk(ENGINE_SRC)) {
            files = s.filter(p -> p.toString().endsWith(".java")).toList();
        }
        assertThat(files).as("engine sources found").isNotEmpty();

        for (Path file : files) {
            for (String raw : Files.readAllLines(file)) {
                String line = raw.strip();
                if (line.startsWith("//") || line.startsWith("*") || line.startsWith("/*")) {
                    continue; // comments and Javadoc may mention these words
                }
                assertThat(FORBIDDEN_IMPORT.matcher(line).matches()).as("%s: %s", file, line).isFalse();
                assertThat(FORBIDDEN_TYPE.matcher(line).find()).as("%s: %s", file, line).isFalse();
            }
        }
    }
}
