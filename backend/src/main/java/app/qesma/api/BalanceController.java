package app.qesma.api;

import app.qesma.security.CurrentUser;
import app.qesma.service.BalanceService;
import app.qesma.service.BalanceView;
import io.swagger.v3.oas.annotations.Operation;
import java.util.UUID;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** Balances of a group (spec 8.2). Computed on demand; nothing is stored. */
@RestController
@RequestMapping("/api/v1/groups/{gid}/balances")
public class BalanceController {

    private final BalanceService balances;
    private final CurrentUser currentUser;

    public BalanceController(BalanceService balances, CurrentUser currentUser) {
        this.balances = balances;
        this.currentUser = currentUser;
    }

    @GetMapping
    @Operation(summary = "Net balance per member and the simplified transfers that settle the group",
            description = "Positive net = the member is owed; negative = owes. Every member is listed, zeros "
                    + "included. Transfers are a deterministic greedy suggestion (spec 7.7), not a guaranteed minimum.")
    public BalanceView get(@PathVariable UUID gid) {
        return balances.balances(currentUser.id(), gid);
    }
}
