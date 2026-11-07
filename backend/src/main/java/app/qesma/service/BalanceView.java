package app.qesma.service;

import java.util.List;
import java.util.UUID;

/**
 * Balances of a group (spec 7.6, 7.7), computed on demand. {@code nets} lists every member in sort order, zeros
 * included; positive means the member is owed. {@code transfers} is the engine's deterministic simplification.
 */
public record BalanceView(List<Net> nets, List<TransferView> transfers) {

    public record Net(UUID memberId, long netMinor) {
    }

    public record TransferView(UUID fromMemberId, UUID toMemberId, long amountMinor) {
    }
}
