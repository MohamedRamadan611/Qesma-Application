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
import app.qesma.service.MemberService;
import app.qesma.service.UserService;
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

    private static final Logger log = LoggerFactory.getLogger(DevSeedRunner.class);

    private final UserService users;
    private final GroupService groups;
    private final MemberService members;
    private final ExpenseService expenses;

    public DevSeedRunner(UserService users, GroupService groups, MemberService members, ExpenseService expenses) {
        this.users = users;
        this.groups = groups;
        this.members = members;
        this.expenses = expenses;
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
        for (String name : MEMBER_NAMES) {
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
        log.info("dev.seed created group {} with {} members and 3 expenses. Sign in with idToken {}", group.getId(),
                ids.size(), FAKE_ID_TOKEN);
    }

    private void create(User owner, ExpenseGroup group, int number, ExpenseCommand command) {
        UUID key = UUID.nameUUIDFromBytes(("qesma-dahab-seed-" + number).getBytes(StandardCharsets.UTF_8));
        expenses.create(owner.getId(), group.getId(), key, command);
    }
}
