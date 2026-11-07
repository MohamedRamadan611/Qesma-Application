package app.qesma.api;

import static org.assertj.core.api.Assertions.assertThat;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.stream.Stream;
import org.junit.jupiter.api.Test;

/**
 * Keeps authorization central (AGENTS.md invariant 7): group data is reachable only through services, which
 * go through GroupAccessService. Controllers and DTOs must never touch repositories.
 */
class LayeringTest {

    private static final Path MAIN = Path.of("src", "main", "java", "app", "qesma");

    private static List<Path> sources(String pkg) throws IOException {
        try (Stream<Path> s = Files.walk(MAIN.resolve(pkg))) {
            return s.filter(p -> p.toString().endsWith(".java")).toList();
        }
    }

    @Test
    void apiPackageNeverImportsPersistence() throws IOException {
        List<Path> files = sources("api");
        assertThat(files).isNotEmpty();
        for (Path file : files) {
            assertThat(Files.readString(file)).as(file.toString()).doesNotContain("import app.qesma.persistence.");
        }
    }

    @Test
    void onlyTheServiceLayerTouchesRepositories() throws IOException {
        for (String pkg : new String[] {"api", "security", "domain", "engine"}) {
            for (Path file : sources(pkg)) {
                assertThat(Files.readString(file)).as(file.toString()).doesNotContain("Repository;");
            }
        }
    }

    @Test
    void expenseRepositoriesAreUsedOnlyByTheExpenseSideOfTheServiceLayer() throws IOException {
        List<String> allowed = List.of("ExpenseService.java", "GroupService.java", "ExpenseMemberUsageChecker.java",
                "ExpenseGroupUsageChecker.java");
        for (Path file : sources("service")) {
            String text = Files.readString(file);
            boolean usesLedger = text.contains("ExpenseRepository") || text.contains("ExpensePayerRepository")
                    || text.contains("ExpenseSplitRepository");
            if (usesLedger) {
                assertThat(allowed).as(file + " must not read ledger data directly")
                        .contains(file.getFileName().toString());
            }
        }
    }

    @Test
    void idempotencyStorageIsReachedOnlyThroughTheIdempotencyService() throws IOException {
        List<String> allowed = List.of("IdempotencyService.java", "IdempotencyCleanupJob.java");
        for (Path file : sources("service")) {
            if (Files.readString(file).contains("IdempotencyKeyStore")) {
                assertThat(allowed).as(file.toString()).contains(file.getFileName().toString());
            }
        }
    }

    @Test
    void groupAndMemberRepositoriesAreUsedOnlyByTheGroupServices() throws IOException {
        List<String> allowed = List.of("GroupAccessService.java", "GroupService.java", "MemberService.java");
        for (Path file : sources("service")) {
            String text = Files.readString(file);
            boolean usesGroupData = text.contains("ExpenseGroupRepository") || text.contains("MemberRepository");
            if (usesGroupData) {
                assertThat(allowed).as(file + " must not read group data directly").contains(file.getFileName().toString());
            }
        }
    }
}
