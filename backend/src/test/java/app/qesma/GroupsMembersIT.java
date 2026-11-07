package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.http.HttpMethod.DELETE;
import static org.springframework.http.HttpMethod.GET;
import static org.springframework.http.HttpMethod.PATCH;
import static org.springframework.http.HttpMethod.POST;

import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import com.fasterxml.jackson.databind.JsonNode;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.Callable;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import org.junit.jupiter.api.Test;
import org.slf4j.LoggerFactory;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

/** Groups and members end to end against real PostgreSQL (Testcontainers) with fake Google sign-in. */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "fake-auth"})
class GroupsMembersIT extends AbstractApiIT {

    private static final String GROUPS = "/api/v1/groups";

    private List<MvcResult> runConcurrently(int threads, List<Callable<MvcResult>> calls) throws Exception {
        ExecutorService pool = Executors.newFixedThreadPool(threads);
        CountDownLatch go = new CountDownLatch(1);
        List<Future<MvcResult>> futures = new ArrayList<>();
        for (Callable<MvcResult> c : calls) {
            futures.add(pool.submit(() -> {
                go.await();
                return c.call();
            }));
        }
        go.countDown();
        List<MvcResult> results = new ArrayList<>();
        for (Future<MvcResult> f : futures) {
            results.add(f.get());
        }
        pool.shutdown();
        return results;
    }

    // ---- groups: create / read / validate ------------------------------------------------------------

    @Test
    void createdGroupDefaultsToEgpAndIsReadableWithEtagAndVersion() throws Exception {
        Session ali = newUser();
        MvcResult created = call(POST, GROUPS, ali, Map.of("name", "  Dahab Trip  ", "type", "trip"));

        assertThat(status(created)).isEqualTo(201);
        assertThat(created.getResponse().getHeader("Location")).startsWith(GROUPS + "/");
        assertThat(etagOf(created)).isEqualTo("\"1\"");
        JsonNode g = body(created);
        assertThat(g.get("name").asText()).isEqualTo("Dahab Trip");
        assertThat(g.get("type").asText()).isEqualTo("TRIP");
        assertThat(g.get("currencyCode").asText()).isEqualTo("EGP");
        assertThat(g.get("version").asInt()).isEqualTo(1);

        MvcResult read = call(GET, GROUPS + "/" + g.get("id").asText(), ali, null);
        assertThat(status(read)).isEqualTo(200);
        assertThat(etagOf(read)).isEqualTo("\"1\"");
        // the creator is the group's first member (B9): exactly one member, linked to them
        assertThat(body(read).get("members")).hasSize(1);
        assertThat(body(read).get("members").get(0).get("isYou").asBoolean()).isTrue();
        assertThat(body(read).get("members").get(0).get("sortOrder").asInt()).isEqualTo(1);
        assertThat(body(read).get("yourMemberId").asText()).isEqualTo(body(read).get("members").get(0).get("id").asText());
        assertThat(body(read).get("totalSpentMinor").asLong()).isZero();
    }

    @Test
    void currencyIsNormalizedAndValidated() throws Exception {
        Session ali = newUser();
        MvcResult usd = call(POST, GROUPS, ali, Map.of("name", "US", "type", "OTHER", "currencyCode", "usd"));
        assertThat(body(usd).get("currencyCode").asText()).isEqualTo("USD");

        for (String bad : new String[] {"ZZZ", "EG", "EGPP", "XXX", "e1p"}) {
            MvcResult r = call(POST, GROUPS, ali, Map.of("name", "Bad", "type", "OTHER", "currencyCode", bad));
            assertThat(status(r)).as(bad).isEqualTo(422);
            assertThat(code(r)).isEqualTo("VALIDATION_ERROR");
        }
    }

    @Test
    void invalidNamesAndTypesAreRejectedWithValidationError() throws Exception {
        Session ali = newUser();
        List<Map<String, String>> bad = List.of(
                Map.of("name", "", "type", "TRIP"),
                Map.of("name", "   ", "type", "TRIP"),
                Map.of("name", "x".repeat(61), "type", "TRIP"),
                Map.of("name", "😀".repeat(61), "type", "TRIP"),
                Map.of("name", "Ok", "type", "VACATION"),
                Map.of("name", "Ok", "type", ""));
        for (Map<String, String> body : bad) {
            MvcResult r = call(POST, GROUPS, ali, body);
            assertThat(status(r)).as(body.toString()).isEqualTo(422);
            assertThat(code(r)).isEqualTo("VALIDATION_ERROR");
        }
        assertThat(status(call(POST, GROUPS, ali, "{}"))).isEqualTo(422); // missing fields
        // boundary: exactly 60 Arabic letters is fine
        assertThat(status(call(POST, GROUPS, ali, Map.of("name", "ع".repeat(60), "type", "TRIP")))).isEqualTo(201);
    }

    // ---- ownership isolation (IDOR) --------------------------------------------------------------------

    @Test
    void anotherUsersGroupAndMembersAreNotFoundOnEveryVerb() throws Exception {
        Session owner = newUser();
        Session intruder = newUser();
        String gid = createGroup(owner, "Private").get("id").asText();
        String mid = addMember(owner, gid, "Secret Friend").get("id").asText();

        MvcResult nonexistent = call(GET, GROUPS + "/" + UUID.randomUUID(), intruder, null);
        assertThat(status(nonexistent)).isEqualTo(404);
        JsonNode baseline = problemWithoutRequestId(nonexistent);

        String g = GROUPS + "/" + gid;
        String m = g + "/members/" + mid;
        List<MvcResult> attempts = List.of(
                call(GET, g, intruder, null),
                call(PATCH, g, intruder, Map.of("name", "Hacked"), "If-Match", "\"1\""),
                call(DELETE, g, intruder, null),
                call(POST, g + "/members", intruder, Map.of("displayName", "Injected")),
                call(PATCH, m, intruder, Map.of("displayName", "Hacked")),
                call(DELETE, m, intruder, null));
        for (MvcResult r : attempts) {
            assertThat(status(r)).isEqualTo(404);                       // never 403
            assertThat(problemWithoutRequestId(r)).isEqualTo(baseline); // indistinguishable from "does not exist"
        }

        // nothing changed, and the intruder's own list is empty
        JsonNode intact = body(call(GET, g, owner, null));
        assertThat(intact.get("name").asText()).isEqualTo("Private");
        assertThat(intact.get("version").asInt()).isEqualTo(1);
        assertThat(intact.get("members")).hasSize(2);             // the owner's member and the friend
        assertThat(intact.get("members").get(1).get("displayName").asText()).isEqualTo("Secret Friend");
        assertThat(body(call(GET, GROUPS, intruder, null)).get("totalElements").asLong()).isZero();
    }

    @Test
    void aMemberOfAnotherGroupCannotBeReachedThroughMyOwnGroup() throws Exception {
        Session owner = newUser();
        Session other = newUser();
        String ownerGroup = createGroup(owner, "A").get("id").asText();
        String victim = addMember(owner, ownerGroup, "Victim").get("id").asText();
        String otherGroup = createGroup(other, "B").get("id").asText();

        // "other" owns otherGroup, but the member belongs to ownerGroup
        MvcResult rename = call(PATCH, GROUPS + "/" + otherGroup + "/members/" + victim, other, Map.of("displayName", "X"));
        MvcResult delete = call(DELETE, GROUPS + "/" + otherGroup + "/members/" + victim, other, null);
        assertThat(status(rename)).isEqualTo(404);
        assertThat(status(delete)).isEqualTo(404);
        assertThat(body(call(GET, GROUPS + "/" + ownerGroup, owner, null)).get("members").get(1).get("displayName")
                .asText()).isEqualTo("Victim");   // member #2: the owner is #1
    }

    @Test
    void unauthenticatedCallsAreRejectedBeforeAnyDataIsTouched() throws Exception {
        assertThat(status(call(GET, GROUPS, null, null))).isEqualTo(401);
        assertThat(status(call(POST, GROUPS, null, Map.of("name", "x", "type", "TRIP")))).isEqualTo(401);
    }

    // ---- members ---------------------------------------------------------------------------------------

    @Test
    void membersGetIncreasingSortOrderAndAreListedInThatOrder() throws Exception {
        Session ali = newUser();
        String gid = createGroup(ali, "Order").get("id").asText();
        for (String name : List.of("Zed", "Amr", "Mona")) {
            addMember(ali, gid, name);
        }
        JsonNode members = body(call(GET, GROUPS + "/" + gid, ali, null)).get("members");
        assertThat(members).hasSize(4);                          // the owner (#1) plus the three added
        for (int i = 0; i < 4; i++) {
            assertThat(members.get(i).get("sortOrder").asInt()).isEqualTo(i + 1);
        }
        assertThat(members.get(0).get("isYou").asBoolean()).isTrue();
        assertThat(members.get(1).get("displayName").asText()).isEqualTo("Zed"); // creation order, not alphabetical
    }

    @Test
    void duplicateNamesAreRejectedCaseInsensitivelyOnCreateAndRename() throws Exception {
        Session ali = newUser();
        String gid = createGroup(ali, "Dups").get("id").asText();
        String sara = addMember(ali, gid, "Sara").get("id").asText();
        addMember(ali, gid, "Omar");

        MvcResult dup = call(POST, GROUPS + "/" + gid + "/members", ali, Map.of("displayName", "sARA"));
        assertThat(status(dup)).isEqualTo(409);
        assertThat(code(dup)).isEqualTo("DUPLICATE_MEMBER_NAME");

        MvcResult renameToOther = call(PATCH, GROUPS + "/" + gid + "/members/" + sara, ali, Map.of("displayName", "OMAR"));
        assertThat(status(renameToOther)).isEqualTo(409);
        assertThat(code(renameToOther)).isEqualTo("DUPLICATE_MEMBER_NAME");

        // changing only the case of one's own name is allowed
        MvcResult ownCase = call(PATCH, GROUPS + "/" + gid + "/members/" + sara, ali, Map.of("displayName", "SARA"));
        assertThat(status(ownCase)).isEqualTo(200);
        assertThat(body(ownCase).get("displayName").asText()).isEqualTo("SARA");
        assertThat(body(ownCase).get("sortOrder").asInt()).isEqualTo(2); // sort order never changes (Sara is member #2 after the owner)

        // the same name is fine in a different group
        String other = createGroup(ali, "Other").get("id").asText();
        assertThat(status(call(POST, GROUPS + "/" + other + "/members", ali, Map.of("displayName", "Sara")))).isEqualTo(201);
    }

    @Test
    void memberNamesAreValidated() throws Exception {
        Session ali = newUser();
        String gid = createGroup(ali, "Names").get("id").asText();
        for (String bad : new String[] {"", "   ", "x".repeat(41), "😀".repeat(41)}) {
            MvcResult r = call(POST, GROUPS + "/" + gid + "/members", ali, Map.of("displayName", bad));
            assertThat(status(r)).as("[" + bad + "]").isEqualTo(422);
            assertThat(code(r)).isEqualTo("VALIDATION_ERROR");
        }
        MvcResult trimmed = call(POST, GROUPS + "/" + gid + "/members", ali, Map.of("displayName", "  محمد  "));
        assertThat(body(trimmed).get("displayName").asText()).isEqualTo("محمد");
    }

    @Test
    void sortOrderIsNeverReusedEvenAfterDeletingTheNewestMember() throws Exception {
        Session ali = newUser();
        String gid = createGroup(ali, "NoReuse").get("id").asText();
        addMember(ali, gid, "A");
        String b = addMember(ali, gid, "B").get("id").asText();
        assertThat(status(call(DELETE, GROUPS + "/" + gid + "/members/" + b, ali, null))).isEqualTo(204);

        assertThat(addMember(ali, gid, "C").get("sortOrder").asInt()).isEqualTo(4); // owner 1, A 2, B 3 deleted: not 3
    }

    @Test
    void addingMembersDoesNotChangeTheGroupEtag() throws Exception {
        Session ali = newUser();
        String gid = createGroup(ali, "Etag").get("id").asText();
        String before = etagOf(call(GET, GROUPS + "/" + gid, ali, null));
        addMember(ali, gid, "One");
        addMember(ali, gid, "Two");
        assertThat(etagOf(call(GET, GROUPS + "/" + gid, ali, null))).isEqualTo(before);
    }

    @Test
    void sixteenConcurrentMemberCreationsGetDistinctConsecutiveSortOrders() throws Exception {
        Session ali = newUser();
        String gid = createGroup(ali, "Race").get("id").asText();
        List<Callable<MvcResult>> calls = new ArrayList<>();
        for (int i = 0; i < 16; i++) {
            String name = "Member " + i;
            calls.add(() -> call(POST, GROUPS + "/" + gid + "/members", ali, Map.of("displayName", name)));
        }
        List<MvcResult> results = runConcurrently(16, calls);

        List<Integer> orders = new ArrayList<>();
        for (MvcResult r : results) {
            assertThat(status(r)).isEqualTo(201);
            orders.add(body(r).get("sortOrder").asInt());
        }
        assertThat(orders).containsExactlyInAnyOrder(2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17); // owner is #1
        Integer distinct = jdbc.queryForObject(
                "select count(distinct sort_order) from members where group_id = ?::uuid", Integer.class, gid);
        assertThat(distinct).isEqualTo(17);                      // 16 added plus the owner
    }

    @Test
    void concurrentCreationOfTheSameNameYieldsOneSuccessAndTheRestConflict() throws Exception {
        Session ali = newUser();
        String gid = createGroup(ali, "SameName").get("id").asText();
        List<Callable<MvcResult>> calls = new ArrayList<>();
        for (int i = 0; i < 8; i++) {
            String name = i % 2 == 0 ? "Twin" : "TWIN"; // differ only by case
            calls.add(() -> call(POST, GROUPS + "/" + gid + "/members", ali, Map.of("displayName", name)));
        }
        List<MvcResult> results = runConcurrently(8, calls);

        long created = results.stream().filter(r -> status(r) == 201).count();
        long conflicts = results.stream().filter(r -> status(r) == 409).count();
        assertThat(created).isEqualTo(1);
        assertThat(conflicts).isEqualTo(7);
        for (MvcResult r : results) {
            if (status(r) == 409) {
                assertThat(code(r)).isEqualTo("DUPLICATE_MEMBER_NAME");
            }
        }
        // a rejected duplicate must not burn a sort_order number
        assertThat(addMember(ali, gid, "Next").get("sortOrder").asInt()).isEqualTo(3); // owner 1, Twin 2
    }

    // ---- optimistic concurrency on groups ----------------------------------------------------------------

    @Test
    void patchWithCurrentVersionSucceedsAndBumpsTheEtag() throws Exception {
        Session ali = newUser();
        String gid = createGroup(ali, "Before").get("id").asText();

        MvcResult ok = call(PATCH, GROUPS + "/" + gid, ali, Map.of("name", "After", "type", "OUTING"), "If-Match", "\"1\"");
        assertThat(status(ok)).isEqualTo(200);
        assertThat(etagOf(ok)).isEqualTo("\"2\"");
        assertThat(body(ok).get("name").asText()).isEqualTo("After");
        assertThat(body(ok).get("type").asText()).isEqualTo("OUTING");
        assertThat(body(ok).get("currencyCode").asText()).isEqualTo("EGP"); // currency is not editable
    }

    @Test
    void staleMissingAndMalformedIfMatchAreRejected() throws Exception {
        Session ali = newUser();
        String gid = createGroup(ali, "Versioned").get("id").asText();
        call(PATCH, GROUPS + "/" + gid, ali, Map.of("name", "v2"), "If-Match", "\"1\""); // now version 2

        MvcResult stale = call(PATCH, GROUPS + "/" + gid, ali, Map.of("name", "late"), "If-Match", "\"1\"");
        assertThat(status(stale)).isEqualTo(409);
        assertThat(code(stale)).isEqualTo("VERSION_CONFLICT");

        MvcResult missing = call(PATCH, GROUPS + "/" + gid, ali, Map.of("name", "x"));
        assertThat(status(missing)).isEqualTo(428);

        MvcResult malformed = call(PATCH, GROUPS + "/" + gid, ali, Map.of("name", "x"), "If-Match", "*");
        assertThat(status(malformed)).isEqualTo(422);

        assertThat(body(call(GET, GROUPS + "/" + gid, ali, null)).get("name").asText()).isEqualTo("v2");
    }

    @Test
    void invalidPatchInputIs422AndAnUnchangedPatchKeepsTheVersion() throws Exception {
        Session ali = newUser();
        String gid = createGroup(ali, "Same").get("id").asText();

        MvcResult bad = call(PATCH, GROUPS + "/" + gid, ali, Map.of("name", "  "), "If-Match", "\"1\"");
        assertThat(status(bad)).isEqualTo(422);
        MvcResult badType = call(PATCH, GROUPS + "/" + gid, ali, Map.of("type", "NOPE"), "If-Match", "\"1\"");
        assertThat(status(badType)).isEqualTo(422);

        MvcResult noop = call(PATCH, GROUPS + "/" + gid, ali, Map.of("name", "Same"), "If-Match", "\"1\"");
        assertThat(status(noop)).isEqualTo(200);
        assertThat(etagOf(noop)).isEqualTo("\"1\"");
    }

    @Test
    void ownerIsNotMassAssignableThroughPatch() throws Exception {
        Session ali = newUser();
        Session mallory = newUser();
        String gid = createGroup(ali, "Mine").get("id").asText();

        MvcResult r = call(PATCH, GROUPS + "/" + gid, ali,
                Map.of("name", "Still mine", "ownerUserId", mallory.userId().toString(), "version", 50),
                "If-Match", "\"1\"");
        assertThat(status(r)).isEqualTo(200);
        assertThat(body(r).get("version").asInt()).isEqualTo(2); // the real counter, not 50

        String owner = jdbc.queryForObject("select owner_user_id::text from expense_groups where id = ?::uuid",
                String.class, gid);
        assertThat(owner).isEqualTo(ali.userId().toString());
    }

    @Test
    void eightConcurrentPatchesWithTheSameVersionYieldOneWinner() throws Exception {
        Session ali = newUser();
        String gid = createGroup(ali, "Contended").get("id").asText();
        List<Callable<MvcResult>> calls = new ArrayList<>();
        for (int i = 0; i < 8; i++) {
            String name = "Name " + i;
            calls.add(() -> call(PATCH, GROUPS + "/" + gid, ali, Map.of("name", name), "If-Match", "\"1\""));
        }
        List<MvcResult> results = runConcurrently(8, calls);

        assertThat(results.stream().filter(r -> status(r) == 200).count()).isEqualTo(1);
        for (MvcResult r : results) {
            if (status(r) != 200) {
                assertThat(status(r)).isEqualTo(409);
                assertThat(code(r)).isEqualTo("VERSION_CONFLICT");
            }
        }
        assertThat(body(call(GET, GROUPS + "/" + gid, ali, null)).get("version").asInt()).isEqualTo(2);
    }

    // ---- delete ---------------------------------------------------------------------------------------

    @Test
    void deletingAnEmptyLedgerGroupRemovesItsMembersToo() throws Exception {
        Session ali = newUser();
        String gid = createGroup(ali, "Doomed").get("id").asText();
        addMember(ali, gid, "A");
        addMember(ali, gid, "B");

        assertThat(status(call(DELETE, GROUPS + "/" + gid, ali, null))).isEqualTo(204);

        assertThat(status(call(GET, GROUPS + "/" + gid, ali, null))).isEqualTo(404);
        assertThat(jdbc.queryForObject("select count(*) from members where group_id = ?::uuid", Integer.class, gid))
                .isZero();
        assertThat(status(call(DELETE, GROUPS + "/" + gid, ali, null))).isEqualTo(404); // second delete
    }

    @Test
    void deletingAMemberWithoutTransactionsSucceeds() throws Exception {
        Session ali = newUser();
        String gid = createGroup(ali, "Members").get("id").asText();
        String mid = addMember(ali, gid, "Temp").get("id").asText();
        assertThat(status(call(DELETE, GROUPS + "/" + gid + "/members/" + mid, ali, null))).isEqualTo(204);
        assertThat(body(call(GET, GROUPS + "/" + gid, ali, null)).get("members")).hasSize(1);   // only the owner remains
    }

    // ---- listing ----------------------------------------------------------------------------------------

    @Test
    void listIsPagedNewestFirstOwnGroupsOnlyWithAccurateMemberCounts() throws Exception {
        Session ali = newUser();
        Session other = newUser();
        createGroup(other, "Not mine");
        String first = null;
        for (int i = 0; i < 25; i++) {
            String id = createGroup(ali, String.format("Group %02d", i)).get("id").asText();
            if (i == 0) {
                first = id;
            }
        }
        addMember(ali, first, "M1");
        addMember(ali, first, "M2");
        addMember(ali, first, "M3");

        JsonNode p0 = body(call(GET, GROUPS + "?page=0&size=10", ali, null));
        JsonNode p1 = body(call(GET, GROUPS + "?page=1&size=10", ali, null));
        JsonNode p2 = body(call(GET, GROUPS + "?page=2&size=10", ali, null));
        assertThat(p0.get("items")).hasSize(10);
        assertThat(p1.get("items")).hasSize(10);
        assertThat(p2.get("items")).hasSize(5);
        assertThat(p0.get("totalElements").asLong()).isEqualTo(25);
        assertThat(p0.get("totalPages").asInt()).isEqualTo(3);
        assertThat(p0.get("items").get(0).get("name").asText()).isEqualTo("Group 24"); // newest first
        assertThat(p2.get("items").get(4).get("name").asText()).isEqualTo("Group 00");
        assertThat(p2.get("items").get(4).get("memberCount").asLong()).isEqualTo(4);   // owner + 3
        assertThat(p0.get("items").get(0).get("memberCount").asLong()).isEqualTo(1);   // only the owner
        assertThat(p0.get("items").get(0).get("totalSpentMinor").asLong()).isZero();
        assertThat(p0.get("items").get(0).get("lastExpenseAt").isNull()).isTrue();

        assertThat(body(call(GET, GROUPS, other, null)).get("totalElements").asLong()).isEqualTo(1);
    }

    @Test
    void pagingParametersOutsideTheAllowedRangeAre422() throws Exception {
        Session ali = newUser();
        for (String q : new String[] {"?size=0", "?size=101", "?size=100000", "?page=-1"}) {
            MvcResult r = call(GET, GROUPS + q, ali, null);
            assertThat(status(r)).as(q).isEqualTo(422);
            assertThat(code(r)).isEqualTo("VALIDATION_ERROR");
        }
        assertThat(status(call(GET, GROUPS + "?size=100", ali, null))).isEqualTo(200);
        assertThat(status(call(GET, GROUPS + "?size=abc", ali, null))).isEqualTo(400);
    }

    // ---- invariants live in the database --------------------------------------------------------------------

    @Test
    void databaseRejectsRowsThatBreakTheSchemaRules() throws Exception {
        Session ali = newUser();
        String gid = createGroup(ali, "Schema").get("id").asText();
        addMember(ali, gid, "Taken");

        String insertGroup = "insert into expense_groups (id, owner_user_id, name, type, currency_code) values (?, ?, ?, ?, ?)";
        UUID owner = ali.userId();
        assertThatThrownBy(() -> jdbc.update(insertGroup, UUID.randomUUID(), owner, "  ", "TRIP", "EGP"))
                .isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> jdbc.update(insertGroup, UUID.randomUUID(), owner, "x", "NOPE", "EGP"))
                .isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> jdbc.update(insertGroup, UUID.randomUUID(), owner, "x", "TRIP", "egp"))
                .isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> jdbc.update(insertGroup, UUID.randomUUID(), UUID.randomUUID(), "x", "TRIP", "EGP"))
                .isInstanceOf(DataIntegrityViolationException.class); // owner must exist

        String insertMember = "insert into members (id, group_id, display_name, sort_order) values (?, ?::uuid, ?, ?)";
        assertThatThrownBy(() -> jdbc.update(insertMember, UUID.randomUUID(), gid, "tAKEN", 99))
                .isInstanceOf(DataIntegrityViolationException.class); // case-insensitive unique name
        assertThatThrownBy(() -> jdbc.update(insertMember, UUID.randomUUID(), gid, "Other", 1))
                .isInstanceOf(DataIntegrityViolationException.class); // unique sort_order per group
        assertThatThrownBy(() -> jdbc.update(insertMember, UUID.randomUUID(), gid, "Zero", 0))
                .isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> jdbc.update(insertMember, UUID.randomUUID(), gid, "   ", 5))
                .isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> jdbc.update(insertMember, UUID.randomUUID(), UUID.randomUUID().toString(), "Orphan", 5))
                .isInstanceOf(DataIntegrityViolationException.class); // group must exist
    }

    // ---- logging: ids only, never names (personal data) ------------------------------------------------------

    @Test
    void logsCarryGroupAndMemberEventsButNotTheNamesPeopleTyped() throws Exception {
        Logger root = (Logger) LoggerFactory.getLogger(Logger.ROOT_LOGGER_NAME);
        ListAppender<ILoggingEvent> appender = new ListAppender<>();
        appender.start();
        root.addAppender(appender);
        String groupName = "TopSecretTripName" + UUID.randomUUID();
        String memberName = "TopSecretFriend" + UUID.randomUUID().toString().substring(0, 8); // member names max 40
        try {
            Session ali = newUser();
            String gid = createGroup(ali, groupName).get("id").asText();
            String mid = addMember(ali, gid, memberName).get("id").asText();
            call(PATCH, GROUPS + "/" + gid + "/members/" + mid, ali, Map.of("displayName", memberName + "2"));
            call(DELETE, GROUPS + "/" + gid + "/members/" + mid, ali, null);
            call(DELETE, GROUPS + "/" + gid, ali, null);
        } finally {
            root.detachAppender(appender);
        }

        StringBuilder all = new StringBuilder();
        List<String> events = new ArrayList<>();
        for (ILoggingEvent e : new ArrayList<>(appender.list)) {
            all.append(e.getFormattedMessage()).append('\n');
            if (e.getKeyValuePairs() != null) {
                e.getKeyValuePairs().forEach(kv -> {
                    all.append(kv.key).append('=').append(kv.value).append('\n');
                    if ("event".equals(kv.key)) {
                        events.add(String.valueOf(kv.value));
                    }
                });
            }
        }
        assertThat(all.toString()).doesNotContain("TopSecretTripName").doesNotContain("TopSecretFriend");
        assertThat(events).contains("group.created", "member.created", "member.renamed", "member.deleted",
                "group.deleted");
    }
}
