package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.http.HttpMethod.DELETE;
import static org.springframework.http.HttpMethod.GET;
import static org.springframework.http.HttpMethod.POST;

import com.fasterxml.jackson.databind.JsonNode;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

/**
 * B11: invitations, preview, join (claim a ghost or become a new member), approval and unlink (Decisions A70-A76).
 * Privacy of the preview, the distinct 404/410 answers, idempotent replay and the approval rules are asserted here;
 * the races live in InviteConcurrencyIT.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "fake-auth"})
class InvitesJoinIT extends AbstractApiIT {

    private static String key() {
        return UUID.randomUUID().toString();
    }

    private static String g(String gid) {
        return "/api/v1/groups/" + gid;
    }

    private JsonNode createInvite(Session as, String gid, Map<String, Object> body) throws Exception {
        MvcResult r = call(POST, g(gid) + "/invites", as, body, "Idempotency-Key", key());
        assertThat(status(r)).as(r.getResponse().getContentAsString()).isEqualTo(201);
        return body(r);
    }

    private MvcResult join(Session as, String code, Object body) throws Exception {
        return call(POST, "/api/v1/invites/" + code + "/join", as, body, "Idempotency-Key", key());
    }

    private static Set<String> fields(JsonNode n) {
        Set<String> names = new TreeSet<>();
        n.fieldNames().forEachRemaining(names::add);
        return names;
    }

    /** A group with the owner (member #1 "Owner"), two ghosts and one expense that involves everyone. */
    private record World(Session owner, String gid, String ownerMember, String mohsen, String yousef) {
    }

    private World world() throws Exception {
        Session owner = newUser();
        String gid = createGroup(owner, "Dahab " + UUID.randomUUID()).get("id").asText();
        String ownerMember = member(owner, gid, "Owner").get("id").asText();
        String mohsen = addMember(owner, gid, "Mohsen").get("id").asText();
        String yousef = addMember(owner, gid, "Yousef").get("id").asText();
        createExpense(owner, gid, equalBody("Hotel", 3000, null, ownerMember, 3000L));
        return new World(owner, gid, ownerMember, mohsen, yousef);
    }

    private JsonNode balances(Session as, String gid) throws Exception {
        return body(call(GET, g(gid) + "/balances", as, null));
    }

    // ---- preview ---------------------------------------------------------------------------------------------------

    @Test
    void previewShowsOnlyWhatTheJoinScreenNeedsAndNeverMoneyOrAccounts() throws Exception {
        World w = world();
        Session admin = newUser();
        linkUser(w.gid(), admin, "ADMIN", "ACTIVE", "Linked Admin");
        JsonNode invite = createInvite(w.owner(), w.gid(), Map.of());
        Session joiner = newUser();

        MvcResult r = call(GET, "/api/v1/invites/" + invite.get("code").asText(), joiner, null);
        assertThat(status(r)).isEqualTo(200);
        JsonNode preview = body(r);

        assertThat(fields(preview)).containsExactlyInAnyOrder("groupName", "groupType", "inviterName", "memberCount",
                "unclaimedMembers", "requiresApproval", "expiresAt", "callerState");
        assertThat(preview.get("inviterName").asText()).isEqualTo("Owner");
        assertThat(preview.get("memberCount").asLong()).isEqualTo(4L);
        assertThat(preview.get("callerState").asText()).isEqualTo("NONE");
        List<String> ghosts = new ArrayList<>();
        for (JsonNode u : preview.get("unclaimedMembers")) {
            assertThat(fields(u)).containsExactlyInAnyOrder("id", "name");
            ghosts.add(u.get("name").asText());
        }
        assertThat(ghosts).as("only members nobody is linked to").containsExactly("Mohsen", "Yousef");
        String text = preview.toString().toLowerCase();
        assertThat(text).doesNotContain("minor").doesNotContain("balance").doesNotContain("net")
                .doesNotContain(w.owner().userId().toString()).doesNotContain(admin.userId().toString());
    }

    @Test
    void previewForAMemberAndForAPendingRequesterShowsTheirState() throws Exception {
        World w = world();
        JsonNode invite = createInvite(w.owner(), w.gid(), Map.of("requiresApproval", true));
        String code = invite.get("code").asText();
        assertThat(body(call(GET, "/api/v1/invites/" + code, w.owner(), null)).get("callerState").asText())
                .isEqualTo("ALREADY_MEMBER");
        Session asker = newUser();
        assertThat(status(join(asker, code, Map.of("newMemberName", "Asker")))).isEqualTo(202);
        assertThat(body(call(GET, "/api/v1/invites/" + code, asker, null)).get("callerState").asText())
                .isEqualTo("PENDING_APPROVAL");
    }

    @Test
    void theCodeIsNormalisedLowerCaseDashesSpacesAndArabicDigits() throws Exception {
        assertThat(app.qesma.service.InviteCodes.normalize(" abcd-2345 ")).isEqualTo("ABCD2345");
        assertThat(app.qesma.service.InviteCodes.normalize("٢٣٤٥abcd")).isEqualTo("2345ABCD");
        assertThat(app.qesma.service.InviteCodes.normalize("ABCD-OOO1")).as("O and 1 are not in the alphabet").isNull();
        assertThat(app.qesma.service.InviteCodes.normalize("short")).isNull();
        for (int i = 0; i < 200; i++) {
            assertThat(app.qesma.service.InviteCodes.generate()).matches("[A-HJ-NP-Z2-9]{8}");
        }
        World w = world();
        String code = createInvite(w.owner(), w.gid(), Map.of()).get("code").asText();
        String typed = " " + code.substring(0, 4).toLowerCase() + "-" + code.substring(4).toLowerCase();
        assertThat(status(call(GET, "/api/v1/invites/" + typed.strip(), newUser(), null))).isEqualTo(200);
    }

    // ---- states ---------------------------------------------------------------------------------------------------

    @Test
    void unknownIs404AndRevokedExpiredAndUsedUpAreDistinct410s() throws Exception {
        World w = world();
        Session someone = newUser();
        MvcResult unknown = call(GET, "/api/v1/invites/ZZZZZZZZ", someone, null);
        assertThat(status(unknown)).isEqualTo(404);
        assertThat(code(unknown)).isEqualTo("NOT_FOUND");
        assertThat(status(call(GET, "/api/v1/invites/not-a-code", someone, null))).isEqualTo(404);

        JsonNode revoked = createInvite(w.owner(), w.gid(), Map.of());
        assertThat(status(call(DELETE, g(w.gid()) + "/invites/" + revoked.get("id").asText(), w.owner(), null))).isEqualTo(204);
        assertThat(status(call(DELETE, g(w.gid()) + "/invites/" + revoked.get("id").asText(), w.owner(), null)))
                .as("revoking again is not an error").isEqualTo(204);
        MvcResult r = call(GET, "/api/v1/invites/" + revoked.get("code").asText(), someone, null);
        assertThat(status(r)).isEqualTo(410);
        assertThat(code(r)).isEqualTo("INVITE_REVOKED");
        assertThat(code(join(someone, revoked.get("code").asText(), Map.of("newMemberName", "X")))).isEqualTo("INVITE_REVOKED");

        JsonNode expired = createInvite(w.owner(), w.gid(), Map.of());
        jdbc.update("update group_invites set created_at = now() - interval '2 days', expires_at = now() - interval '1 day' "
                + "where id = ?::uuid", expired.get("id").asText());
        r = call(GET, "/api/v1/invites/" + expired.get("code").asText(), someone, null);
        assertThat(status(r)).isEqualTo(410);
        assertThat(code(r)).isEqualTo("INVITE_EXPIRED");

        JsonNode both = createInvite(w.owner(), w.gid(), Map.of());
        jdbc.update("update group_invites set created_at = now() - interval '2 days', expires_at = now() - interval '1 day', "
                + "revoked_at = now() where id = ?::uuid", both.get("id").asText());
        assertThat(code(call(GET, "/api/v1/invites/" + both.get("code").asText(), someone, null)))
                .as("revoked wins over expired").isEqualTo("INVITE_REVOKED");

        JsonNode once = createInvite(w.owner(), w.gid(), Map.of("maxUses", 1));
        assertThat(status(join(newUser(), once.get("code").asText(), Map.of("newMemberName", "First")))).isEqualTo(201);
        r = join(someone, once.get("code").asText(), Map.of("newMemberName", "Second"));
        assertThat(status(r)).isEqualTo(410);
        assertThat(code(r)).isEqualTo("INVITE_EXPIRED");
    }

    @Test
    void creatingValidatesExpiryAndUsesAndListsWithCodeLinkAndStatus() throws Exception {
        World w = world();
        for (Map<String, Object> bad : List.of(Map.<String, Object>of("expiresInDays", 0), Map.<String, Object>of("expiresInDays", 31),
                Map.<String, Object>of("maxUses", 0), Map.<String, Object>of("maxUses", 1001))) {
            MvcResult r = call(POST, g(w.gid()) + "/invites", w.owner(), bad, "Idempotency-Key", key());
            assertThat(status(r)).as(bad.toString()).isEqualTo(422);
        }
        assertThat(status(call(POST, g(w.gid()) + "/invites", w.owner(), Map.of()))).as("a key is required").isEqualTo(422);

        JsonNode invite = createInvite(w.owner(), w.gid(), Map.of("expiresInDays", 3, "maxUses", 5, "requiresApproval", true));
        assertThat(invite.get("code").asText()).matches("[A-HJ-NP-Z2-9]{8}");
        assertThat(invite.get("link").asText()).isEqualTo("https://qesma.app/join/" + invite.get("code").asText());
        assertThat(invite.get("status").asText()).isEqualTo("ACTIVE");
        assertThat(invite.get("maxUses").asInt()).isEqualTo(5);
        assertThat(invite.get("requiresApproval").asBoolean()).isTrue();
        long days = java.time.Duration.between(java.time.Instant.parse(invite.get("createdAt").asText()),
                java.time.Instant.parse(invite.get("expiresAt").asText())).toDays();
        assertThat(days).isEqualTo(3L);
        JsonNode dflt = createInvite(w.owner(), w.gid(), Map.of());
        assertThat(java.time.Duration.between(java.time.Instant.parse(dflt.get("createdAt").asText()),
                java.time.Instant.parse(dflt.get("expiresAt").asText())).toDays()).as("default 7 days").isEqualTo(7L);

        JsonNode list = body(call(GET, g(w.gid()) + "/invites", w.owner(), null));
        assertThat(list.get("items")).hasSize(2);
        assertThat(list.get("items").get(0).get("id").asText()).as("newest first").isEqualTo(dflt.get("id").asText());
        assertThat(list.get("items").get(0).get("code").asText()).isEqualTo(dflt.get("code").asText());
        assertThat(status(call(DELETE, g(w.gid()) + "/invites/" + UUID.randomUUID(), w.owner(), null))).isEqualTo(404);
    }

    @Test
    void creatingIsIdempotent() throws Exception {
        World w = world();
        String k = key();
        MvcResult first = call(POST, g(w.gid()) + "/invites", w.owner(), Map.of("expiresInDays", 2), "Idempotency-Key", k);
        MvcResult again = call(POST, g(w.gid()) + "/invites", w.owner(), Map.of("expiresInDays", 2), "Idempotency-Key", k);
        assertThat(status(first)).isEqualTo(201);
        assertThat(status(again)).isEqualTo(201);
        assertThat(again.getResponse().getHeader("Idempotency-Replayed")).isEqualTo("true");
        assertThat(body(again).get("code").asText()).isEqualTo(body(first).get("code").asText());
        assertThat(jdbc.queryForObject("select count(*) from group_invites where group_id = ?::uuid", Long.class, w.gid())).isEqualTo(1L);
        MvcResult other = call(POST, g(w.gid()) + "/invites", w.owner(), Map.of("expiresInDays", 9), "Idempotency-Key", k);
        assertThat(status(other)).isEqualTo(422);
        assertThat(code(other)).isEqualTo("IDEMPOTENCY_KEY_REUSED");
    }

    // ---- join --------------------------------------------------------------------------------------------------------

    @Test
    void joiningAsANewMemberLinksTheAccountGivesRoleMemberAndAccessToThatGroupOnly() throws Exception {
        World w = world();
        Session other = newUser();
        String otherGroup = createGroup(other, "Elsewhere").get("id").asText();
        JsonNode invite = createInvite(w.owner(), w.gid(), Map.of());
        Session joiner = newUser();

        MvcResult r = join(joiner, invite.get("code").asText(), Map.of("newMemberName", "  Karim  "));
        assertThat(status(r)).as(r.getResponse().getContentAsString()).isEqualTo(201);
        JsonNode joined = body(r);
        assertThat(joined.get("status").asText()).isEqualTo("JOINED");
        assertThat(joined.get("groupId").asText()).isEqualTo(w.gid());
        assertThat(joined.get("member").get("displayName").asText()).isEqualTo("Karim");
        assertThat(joined.get("member").get("role").asText()).isEqualTo("MEMBER");

        Map<String, Object> row = jdbc.queryForMap("select role, status, user_id::text as uid, sort_order, joined_at from members "
                + "where id = ?::uuid", joined.get("member").get("id").asText());
        assertThat(row.get("role")).isEqualTo("MEMBER");
        assertThat(row.get("status")).isEqualTo("ACTIVE");
        assertThat(row.get("uid")).isEqualTo(joiner.userId().toString());
        assertThat(row.get("sort_order")).isEqualTo(4);
        assertThat(row.get("joined_at")).isNotNull();
        assertThat(jdbc.queryForObject("select use_count from group_invites where id = ?::uuid", Integer.class,
                invite.get("id").asText())).isEqualTo(1);

        JsonNode group = body(call(GET, g(w.gid()), joiner, null));
        assertThat(group.get("yourRole").asText()).isEqualTo("MEMBER");
        assertThat(group.get("yourMemberId").asText()).isEqualTo(joined.get("member").get("id").asText());
        assertThat(status(call(GET, g(otherGroup), joiner, null))).as("no access to other groups").isEqualTo(404);
        assertThat(status(call(GET, g(w.gid()), other, null))).as("a stranger still has none").isEqualTo(404);
        // the joiner can add an expense, but not manage invites
        assertThat(status(call(POST, g(w.gid()) + "/invites", joiner, Map.of(), "Idempotency-Key", key()))).isEqualTo(403);
    }

    @Test
    void claimingAGhostKeepsTheirHistoryAndBalance() throws Exception {
        World w = world();
        String code = createInvite(w.owner(), w.gid(), Map.of()).get("code").asText();
        JsonNode before = balances(w.owner(), w.gid());
        Session mohsenAccount = newUser();

        MvcResult r = join(mohsenAccount, code, Map.of("claimMemberId", w.mohsen()));
        assertThat(status(r)).isEqualTo(201);
        assertThat(body(r).get("member").get("id").asText()).as("the same member, not a new one").isEqualTo(w.mohsen());
        assertThat(balances(w.owner(), w.gid())).as("claiming moves no money").isEqualTo(before);
        JsonNode group = body(call(GET, g(w.gid()), mohsenAccount, null));
        assertThat(group.get("yourMemberId").asText()).isEqualTo(w.mohsen());
        assertThat(group.get("yourNetMinor").asLong()).as("his share of the hotel (3000 / 3)").isEqualTo(-1000L);
        for (JsonNode m : group.get("members")) {
            if (m.get("id").asText().equals(w.mohsen())) {
                assertThat(m.get("hasAccount").asBoolean()).isTrue();
                assertThat(m.get("role").asText()).isEqualTo("MEMBER");
            }
        }
        JsonNode preview = body(call(GET, "/api/v1/invites/" + code, newUser(), null));
        List<String> names = new ArrayList<>();
        preview.get("unclaimedMembers").forEach(u -> names.add(u.get("name").asText()));
        assertThat(names).containsExactly("Yousef");
    }

    @Test
    void badJoinBodiesAndCollisionsHaveStableCodes() throws Exception {
        World w = world();
        Session otherOwner = newUser();
        String foreignGroup = createGroup(otherOwner, "Foreign").get("id").asText();
        String foreignGhost = addMember(otherOwner, foreignGroup, "Stranger Ghost").get("id").asText();
        String code = createInvite(w.owner(), w.gid(), Map.of()).get("code").asText();
        Session joiner = newUser();

        assertThat(status(join(joiner, code, Map.of()))).as("neither").isEqualTo(422);
        assertThat(status(join(joiner, code, Map.of("claimMemberId", w.mohsen(), "newMemberName", "Both")))).as("both").isEqualTo(422);
        assertThat(status(join(joiner, code, Map.of("newMemberName", "   ")))).as("blank").isEqualTo(422);
        assertThat(status(join(joiner, code, Map.of("newMemberName", "x".repeat(41))))).as("too long").isEqualTo(422);
        MvcResult foreign = join(joiner, code, Map.of("claimMemberId", foreignGhost));
        assertThat(status(foreign)).isEqualTo(422);
        assertThat(code(foreign)).isEqualTo("MEMBER_NOT_IN_GROUP");
        MvcResult dup = join(joiner, code, Map.of("newMemberName", "mohsen"));
        assertThat(status(dup)).isEqualTo(409);
        assertThat(code(dup)).isEqualTo("DUPLICATE_MEMBER_NAME");
        MvcResult mine = join(w.owner(), code, Map.of("newMemberName", "Me again"));
        assertThat(status(mine)).isEqualTo(409);
        assertThat(code(mine)).isEqualTo("ALREADY_MEMBER");
        assertThat(jdbc.queryForObject("select use_count from group_invites where code = ?", Integer.class, code))
                .as("nothing above used the invite").isZero();
        assertThat(jdbc.queryForObject("select count(*) from members where group_id = ?::uuid", Long.class, w.gid())).isEqualTo(3L);
    }

    @Test
    void claimingAMemberSomebodyElseClaimedIs409() throws Exception {
        World w = world();
        String code = createInvite(w.owner(), w.gid(), Map.of()).get("code").asText();
        assertThat(status(join(newUser(), code, Map.of("claimMemberId", w.yousef())))).isEqualTo(201);
        MvcResult r = join(newUser(), code, Map.of("claimMemberId", w.yousef()));
        assertThat(status(r)).isEqualTo(409);
        assertThat(code(r)).isEqualTo("MEMBER_ALREADY_CLAIMED");
    }

    @Test
    void joiningIsIdempotentAndAReplaySurvivesTheInviteBeingRevoked() throws Exception {
        World w = world();
        JsonNode invite = createInvite(w.owner(), w.gid(), Map.of());
        String code = invite.get("code").asText();
        Session joiner = newUser();
        String k = key();
        Map<String, Object> body = Map.of("newMemberName", "Once");
        MvcResult first = call(POST, "/api/v1/invites/" + code + "/join", joiner, body, "Idempotency-Key", k);
        assertThat(status(call(DELETE, g(w.gid()) + "/invites/" + invite.get("id").asText(), w.owner(), null))).isEqualTo(204);
        MvcResult again = call(POST, "/api/v1/invites/" + code + "/join", joiner, body, "Idempotency-Key", k);

        assertThat(status(first)).isEqualTo(201);
        assertThat(status(again)).as("the stored answer, although the invite is revoked now").isEqualTo(201);
        assertThat(again.getResponse().getHeader("Idempotency-Replayed")).isEqualTo("true");
        assertThat(body(again)).isEqualTo(body(first));
        assertThat(jdbc.queryForObject("select count(*) from members where user_id = ?::uuid", Long.class, joiner.userId().toString()))
                .isEqualTo(1L);
        assertThat(jdbc.queryForObject("select use_count from group_invites where id = ?::uuid", Integer.class,
                invite.get("id").asText())).isEqualTo(1);
        MvcResult reused = call(POST, "/api/v1/invites/" + code + "/join", joiner, Map.of("newMemberName", "Other"),
                "Idempotency-Key", k);
        assertThat(status(reused)).isEqualTo(422);
        assertThat(code(reused)).isEqualTo("IDEMPOTENCY_KEY_REUSED");
    }

    // ---- approval ------------------------------------------------------------------------------------------------------

    @Test
    void approvalPathPendingRequestApproveRejectAndRepeatRules() throws Exception {
        World w = world();
        JsonNode invite = createInvite(w.owner(), w.gid(), Map.of("requiresApproval", true));
        String code = invite.get("code").asText();
        Session asker = newUser();
        Session second = newUser();

        MvcResult pending = join(asker, code, Map.of("newMemberName", "Asker"));
        assertThat(status(pending)).isEqualTo(202);
        assertThat(body(pending).get("status").asText()).isEqualTo("PENDING_APPROVAL");
        String rid = body(pending).get("requestId").asText();
        assertThat(body(join(asker, code, Map.of("newMemberName", "Asker"))).get("requestId").asText())
                .as("asking twice is the same request").isEqualTo(rid);
        assertThat(status(call(GET, g(w.gid()), asker, null))).as("not a member yet").isEqualTo(404);
        String rid2 = body(join(second, code, Map.of("claimMemberId", w.mohsen()))).get("requestId").asText();
        assertThat(jdbc.queryForObject("select use_count from group_invites where code = ?", Integer.class, code)).isZero();

        JsonNode list = body(call(GET, g(w.gid()) + "/join-requests", w.owner(), null));
        assertThat(list.get("items")).hasSize(2);
        for (JsonNode item : list.get("items")) {
            assertThat(fields(item)).containsExactlyInAnyOrder("id", "status", "requesterName", "claimMemberId",
                    "claimMemberName", "newMemberName", "createdAt", "decidedAt");
        }
        assertThat(list.toString()).doesNotContain(asker.userId().toString()).doesNotContain(second.userId().toString());

        MvcResult approved = call(POST, g(w.gid()) + "/join-requests/" + rid + "/approve", w.owner(), null);
        assertThat(status(approved)).as(approved.getResponse().getContentAsString()).isEqualTo(200);
        assertThat(body(approved).get("status").asText()).isEqualTo("APPROVED");
        assertThat(status(call(GET, g(w.gid()), asker, null))).as("now a member").isEqualTo(200);
        assertThat(jdbc.queryForObject("select use_count from group_invites where code = ?", Integer.class, code)).isEqualTo(1);
        assertThat(status(call(POST, g(w.gid()) + "/join-requests/" + rid + "/approve", w.owner(), null)))
                .as("repeating a decision is fine").isEqualTo(200);
        assertThat(jdbc.queryForObject("select use_count from group_invites where code = ?", Integer.class, code))
                .as("and does not use the invite twice").isEqualTo(1);
        MvcResult opposite = call(POST, g(w.gid()) + "/join-requests/" + rid + "/reject", w.owner(), null);
        assertThat(status(opposite)).isEqualTo(409);
        assertThat(code(opposite)).isEqualTo("VERSION_CONFLICT");

        MvcResult rejected = call(POST, g(w.gid()) + "/join-requests/" + rid2 + "/reject", w.owner(), null);
        assertThat(status(rejected)).isEqualTo(200);
        assertThat(body(rejected).get("status").asText()).isEqualTo("REJECTED");
        assertThat(status(call(GET, g(w.gid()), second, null))).isEqualTo(404);
        assertThat(body(call(GET, g(w.gid()) + "/join-requests", w.owner(), null)).get("items")).isEmpty();
        assertThat(jdbc.queryForObject("select user_id is null from members where id = ?::uuid", Boolean.class, w.mohsen()))
                .as("a rejected claim leaves the ghost free").isTrue();
        assertThat(status(call(POST, g(w.gid()) + "/join-requests/" + UUID.randomUUID() + "/approve", w.owner(), null))).isEqualTo(404);
    }

    @Test
    void approvingFailsWhenTheGhostWasClaimedMeanwhileAndTheRequestStaysPending() throws Exception {
        World w = world();
        String approvalCode = createInvite(w.owner(), w.gid(), Map.of("requiresApproval", true)).get("code").asText();
        String openCode = createInvite(w.owner(), w.gid(), Map.of()).get("code").asText();
        Session asker = newUser();
        String rid = body(join(asker, approvalCode, Map.of("claimMemberId", w.mohsen()))).get("requestId").asText();
        assertThat(status(join(newUser(), openCode, Map.of("claimMemberId", w.mohsen())))).isEqualTo(201);

        MvcResult r = call(POST, g(w.gid()) + "/join-requests/" + rid + "/approve", w.owner(), null);
        assertThat(status(r)).isEqualTo(409);
        assertThat(code(r)).isEqualTo("MEMBER_ALREADY_CLAIMED");
        assertThat(jdbc.queryForObject("select status from join_requests where id = ?::uuid", String.class, rid)).isEqualTo("PENDING");
        assertThat(jdbc.queryForObject("select use_count from group_invites where code = ?", Integer.class, approvalCode)).isZero();
        assertThat(status(call(POST, g(w.gid()) + "/join-requests/" + rid + "/reject", w.owner(), null))).isEqualTo(200);
    }

    @Test
    void approvingPastMaxUsesIs410AndTheRequestStaysPending() throws Exception {
        World w = world();
        String code = createInvite(w.owner(), w.gid(), Map.of("requiresApproval", true, "maxUses", 1)).get("code").asText();
        String r1 = body(join(newUser(), code, Map.of("newMemberName", "One"))).get("requestId").asText();
        String r2 = body(join(newUser(), code, Map.of("newMemberName", "Two"))).get("requestId").asText();
        assertThat(status(call(POST, g(w.gid()) + "/join-requests/" + r1 + "/approve", w.owner(), null))).isEqualTo(200);
        MvcResult r = call(POST, g(w.gid()) + "/join-requests/" + r2 + "/approve", w.owner(), null);
        assertThat(status(r)).isEqualTo(410);
        assertThat(code(r)).isEqualTo("INVITE_EXPIRED");
        assertThat(jdbc.queryForObject("select status from join_requests where id = ?::uuid", String.class, r2)).isEqualTo("PENDING");
    }

    @Test
    void anApprovedNewMemberWithATakenNameFailsAtApprovalTime() throws Exception {
        World w = world();
        String approvalCode = createInvite(w.owner(), w.gid(), Map.of("requiresApproval", true)).get("code").asText();
        String openCode = createInvite(w.owner(), w.gid(), Map.of()).get("code").asText();
        String rid = body(join(newUser(), approvalCode, Map.of("newMemberName", "Taken Later"))).get("requestId").asText();
        assertThat(status(join(newUser(), openCode, Map.of("newMemberName", "taken later")))).isEqualTo(201);
        MvcResult r = call(POST, g(w.gid()) + "/join-requests/" + rid + "/approve", w.owner(), null);
        assertThat(status(r)).isEqualTo(409);
        assertThat(code(r)).isEqualTo("DUPLICATE_MEMBER_NAME");
    }

    // ---- unlink ---------------------------------------------------------------------------------------------------------

    @Test
    void unlinkingKeepsTheMemberAndBalanceRemovesAccessAndMakesTheMemberClaimableAgain() throws Exception {
        World w = world();
        String code = createInvite(w.owner(), w.gid(), Map.of()).get("code").asText();
        Session karim = newUser();
        String karimMember = body(join(karim, code, Map.of("newMemberName", "Karim"))).get("member").get("id").asText();
        createExpense(karim, w.gid(), equalBody("Fuel", 900, null, karimMember, 900L));
        JsonNode before = balances(w.owner(), w.gid());

        assertThat(status(call(POST, g(w.gid()) + "/members/" + karimMember + "/unlink", w.owner(), null))).isEqualTo(204);

        assertThat(status(call(GET, g(w.gid()), karim, null))).as("access is gone at once").isEqualTo(404);
        assertThat(balances(w.owner(), w.gid())).as("history and balance stay").isEqualTo(before);
        Map<String, Object> row = jdbc.queryForMap("select user_id, role, status from members where id = ?::uuid", karimMember);
        assertThat(row.get("user_id")).isNull();
        assertThat(row.get("role")).isEqualTo("MEMBER");
        assertThat(jdbc.queryForObject("select count(*) from expenses where group_id = ?::uuid and deleted_at is null", Long.class,
                w.gid())).isEqualTo(2L);
        assertThat(status(call(POST, g(w.gid()) + "/members/" + karimMember + "/unlink", w.owner(), null)))
                .as("unlinking a ghost does nothing").isEqualTo(204);
        Session again = newUser();
        assertThat(status(join(again, code, Map.of("claimMemberId", karimMember)))).as("claimable again").isEqualTo(201);
    }

    @Test
    void theOwnersMemberIsProtectedAndOnlyTheOwnerMayUnlinkAnAdmin() throws Exception {
        World w = world();
        Session admin = newUser();
        Session admin2 = newUser();
        String adminMember = linkUser(w.gid(), admin, "ADMIN", "ACTIVE", "Admin One");
        String admin2Member = linkUser(w.gid(), admin2, "ADMIN", "ACTIVE", "Admin Two");

        MvcResult owner = call(POST, g(w.gid()) + "/members/" + w.ownerMember() + "/unlink", admin, null);
        assertThat(status(owner)).isEqualTo(409);
        assertThat(code(owner)).isEqualTo("OWNER_MEMBER_PROTECTED");
        MvcResult peer = call(POST, g(w.gid()) + "/members/" + admin2Member + "/unlink", admin, null);
        assertThat(status(peer)).isEqualTo(403);
        assertThat(code(peer)).isEqualTo("FORBIDDEN");
        assertThat(status(call(POST, g(w.gid()) + "/members/" + adminMember + "/unlink", w.owner(), null))).isEqualTo(204);
        assertThat(jdbc.queryForObject("select role from members where id = ?::uuid", String.class, adminMember))
                .as("an unlinked admin is a plain ghost again").isEqualTo("MEMBER");
        assertThat(status(call(GET, g(w.gid()), admin, null))).isEqualTo(404);
    }
}
