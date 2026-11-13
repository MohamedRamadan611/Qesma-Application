package app.qesma.dev;

import app.qesma.domain.ExpenseGroup;
import app.qesma.domain.Member;
import app.qesma.domain.User;
import app.qesma.security.GoogleIdentity;
import app.qesma.service.ExpenseCommand;
import app.qesma.service.ExpenseCommand.ItemInput;
import app.qesma.service.ExpenseCommand.PayerInput;
import app.qesma.service.ExpenseService;
import app.qesma.service.GroupService;
import app.qesma.service.IdempotencyService;
import app.qesma.service.InviteCommand;
import app.qesma.service.InviteService;
import app.qesma.service.JoinCommand;
import app.qesma.service.JoinService;
import app.qesma.service.MemberService;
import app.qesma.service.SettlementCommand;
import app.qesma.service.SettlementService;
import app.qesma.service.UserService;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

/**
 * Development data for the mobile app (B8): the Dahab trip from docs/STITCH_PROMPTS.md. Runs only with the profiles
 * {@code local} and {@code seed} (never in prod) and goes through the real services, so every rule applies. Safe to
 * run again: the group is found by name and the expenses use fixed idempotency keys.
 *
 * <pre>
 * ./mvnw spring-boot:run -Dspring-boot.run.profiles=local,fake-auth,seed
 * sign in with the idToken printed in the log:  fake:dahab:mohamed@example.com:محمد
 * </pre>
 */
@Component
@Profile("local & seed")
public class DevSeedRunner implements ApplicationRunner {

    public static final String SUBJECT = "dahab";
    public static final String EMAIL = "mohamed@example.com";
    public static final String OWNER_NAME = "محمد";
    public static final String GROUP_NAME = "رحلة دهب";
    public static final List<String> MEMBER_NAMES = List.of("محمد", "عاصم", "محسن", "يوسف", "كريم");
    /** What a fake-auth client sends to POST /api/v1/auth/google to become the seeded owner. */
    public static final String FAKE_ID_TOKEN = "fake:" + SUBJECT + ":" + EMAIL + ":" + OWNER_NAME;
    /** B12: عاصم joins with an account and is promoted to ADMIN; كريم joins and then leaves (a LEFT member with a balance). */
    public static final String ASEM_ID_TOKEN = "fake:dahab-asem:asem@example.com:عاصم";
    public static final String KARIM_ID_TOKEN = "fake:dahab-karim:karim@example.com:كريم";

    private static final Logger log = LoggerFactory.getLogger(DevSeedRunner.class);

    private final UserService users;
    private final GroupService groups;
    private final MemberService members;
    private final ExpenseService expenses;
    private final InviteService invites;
    private final JoinService joins;
    private final SettlementService settlements;
    private final ObjectMapper mapper;

    public DevSeedRunner(UserService users, GroupService groups, MemberService members, ExpenseService expenses,
                         InviteService invites, JoinService joins, SettlementService settlements,
                         ObjectMapper mapper) {
        this.users = users;
        this.groups = groups;
        this.members = members;
        this.expenses = expenses;
        this.invites = invites;
        this.joins = joins;
        this.settlements = settlements;
        this.mapper = mapper;
    }

    @Override
    public void run(ApplicationArguments args) {
        User owner = users.upsertGoogleUser(new GoogleIdentity(SUBJECT, EMAIL, OWNER_NAME));
        boolean exists = groups.list(owner.getId(), 0, 100).getContent().stream()
                .anyMatch(g -> GROUP_NAME.equals(g.name()));
        if (exists) {
            log.info("dev.seed already present: nothing to do. Sign in with idToken {}", FAKE_ID_TOKEN);
            return;
        }
        ExpenseGroup group = groups.create(owner.getId(), GROUP_NAME, "TRIP", "EGP");
        List<UUID> ids = new ArrayList<>();
        // the owner (named after their profile, "محمد") is already member #1 since B9; add the other four
        ids.add(groups.get(owner.getId(), group.getId()).members().get(0).getId());
        for (String name : MEMBER_NAMES.subList(1, MEMBER_NAMES.size())) {
            Member m = members.add(owner.getId(), group.getId(), name);
            ids.add(m.getId());
        }
        UUID mohamed = ids.get(0);
        UUID asem = ids.get(1);
        UUID mohsen = ids.get(2);
        LocalDate day1 = LocalDate.of(2026, 10, 16);

        // بنزين 600.00, paid by محمد, equal among all five (120.00 each)
        create(owner, group, 1, new ExpenseCommand("بنزين", day1, "EQUAL", 60000L,
                List.of(new PayerInput(mohamed, 60000L)), null, null));
        // فندق 3 000.00, paid by عاصم 2 000.00 + محمد 1 000.00, equal among all five (600.00 each)
        create(owner, group, 2, new ExpenseCommand("فندق", day1, "EQUAL", 300000L,
                List.of(new PayerInput(asem, 200000L), new PayerInput(mohamed, 100000L)), null, null));
        // عشاء مأكولات بحرية 561.79, restaurant bill with 12% service and 14% tax
        create(owner, group, 3, new ExpenseCommand("عشاء مأكولات بحرية", LocalDate.of(2026, 10, 17), "ITEMIZED", null,
                List.of(new PayerInput(mohamed, 30000L), new PayerInput(mohsen, 26179L)), null, null,
                List.of(new ItemInput("بيتزا", 20000L, List.of(mohamed, asem)),
                        new ItemInput("باستا", 15000L, List.of(mohsen)),
                        new ItemInput("مشروبات", 9000L, List.of(mohamed, asem, mohsen))),
                new ExpenseCommand.ServiceInput(1200), new ExpenseCommand.TaxInput(1400, "SUBTOTAL_PLUS_SERVICE"), null));
        User asemUser = seedLifecycle(owner, group, asem, ids.get(4));
        seedSettlements(owner, asemUser, group, mohamed, asem);
        log.info("dev.seed created group {} with {} members and 3 expenses. Sign in with idToken {} "
                + "(admin: {}, member who left: {}); 1 PENDING and 1 DISPUTED settlement", group.getId(), ids.size(), FAKE_ID_TOKEN, ASEM_ID_TOKEN,
                KARIM_ID_TOKEN);
    }

    /** B12: two people claim their ghost through a real invite; the owner promotes one, the other leaves. */
    private User seedLifecycle(User owner, ExpenseGroup group, UUID asemMember, UUID karimMember) {
        User asem = users.upsertGoogleUser(new GoogleIdentity("dahab-asem", "asem@example.com", "عاصم"));
        User karim = users.upsertGoogleUser(new GoogleIdentity("dahab-karim", "karim@example.com", "كريم"));
        String code = inviteCode(owner, group);
        join(asem, code, asemMember, 1);
        join(karim, code, karimMember, 2);
        members.update(owner.getId(), group.getId(), asemMember, new MemberService.MemberPatch(null, "ADMIN", null));
        members.leave(karim.getId(), group.getId());
        return asem;
    }

    /**
     * B13: one PENDING and one DISPUTED payment from عاصم to محمد. Neither counts in the balances (A83), so the documented
     * nets stay as they are; both show up as pending/dispute information on the suggested transfers they match.
     */
    private void seedSettlements(User owner, User asem, ExpenseGroup group, UUID mohamed, UUID asemMember) {
        declare(asem, group, 1, new SettlementCommand(asemMember, mohamed, 5000L, LocalDate.of(2026, 10, 18), "تحويل إنستاباي"));
        String disputed = declare(asem, group, 2,
                new SettlementCommand(asemMember, mohamed, 3000L, LocalDate.of(2026, 10, 19), "كاش في الفندق"));
        settlements.dispute(owner.getId(), group.getId(), UUID.fromString(disputed));
    }

    private String declare(User payer, ExpenseGroup group, int number, SettlementCommand command) {
        UUID key = UUID.nameUUIDFromBytes(("qesma-dahab-seed-settlement-" + number).getBytes(StandardCharsets.UTF_8));
        IdempotencyService.Outcome out = settlements.create(payer.getId(), group.getId(), key, command);
        try {
            return mapper.readTree(out.body()).get("id").asText();
        } catch (java.io.IOException e) {
            throw new IllegalStateException("dev.seed could not read the settlement it just created", e);
        }
    }

    private String inviteCode(User owner, ExpenseGroup group) {
        UUID key = UUID.nameUUIDFromBytes("qesma-dahab-seed-invite".getBytes(StandardCharsets.UTF_8));
        IdempotencyService.Outcome out = invites.create(owner.getId(), group.getId(), key,
                new InviteCommand(7, null, false));
        try {
            return mapper.readTree(out.body()).get("code").asText();
        } catch (java.io.IOException e) {
            throw new IllegalStateException("dev.seed could not read the invite it just created", e);
        }
    }

    private void join(User user, String code, UUID memberId, int number) {
        UUID key = UUID.nameUUIDFromBytes(("qesma-dahab-seed-join-" + number).getBytes(StandardCharsets.UTF_8));
        joins.join(user.getId(), key, code, new JoinCommand(memberId, null));
    }

    private void create(User owner, ExpenseGroup group, int number, ExpenseCommand command) {
        UUID key = UUID.nameUUIDFromBytes(("qesma-dahab-seed-" + number).getBytes(StandardCharsets.UTF_8));
        expenses.create(owner.getId(), group.getId(), key, command);
    }
}
