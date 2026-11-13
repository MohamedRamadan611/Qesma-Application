package app.qesma.service;

import java.util.List;
import java.util.UUID;

/**
 * Balances of a group (spec 7.6, 7.7), computed on demand. {@code nets} lists every member in sort order, zeros
 * included; positive means the member is owed. Nets and {@code transfers} count CONFIRMED settlements only (A83).
 *
 * <p>Each transfer also carries what is still open between exactly that pair, computed by the backend: the sum of
 * PENDING settlements ({@code pendingMinor}), whether a DISPUTED one exists ({@code hasDispute}) and the ids of the open
 * ones ({@code openSettlementIds}, oldest first) so the UI can open them. The client never subtracts these itself.
 */
public record BalanceView(List<Net> nets, List<TransferView> transfers) {

    public record Net(UUID memberId, long netMinor) {
    }

    public record TransferView(UUID fromMemberId, UUID toMemberId, long amountMinor, long pendingMinor,
                               boolean hasDispute, List<UUID> openSettlementIds) {
    }
}
