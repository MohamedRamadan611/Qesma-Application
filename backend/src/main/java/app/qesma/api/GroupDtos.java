package app.qesma.api;

import app.qesma.domain.ExpenseGroup;
import app.qesma.domain.Member;
import app.qesma.service.GroupService;
import com.fasterxml.jackson.annotation.JsonProperty;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * Request and response shapes for groups and members. Requests contain only fields a client may set, so
 * owner, version, sort order and account links can never be mass-assigned.
 */
public final class GroupDtos {

    private GroupDtos() {
    }

    public record CreateGroupRequest(String name, String type, String currencyCode) {
    }

    /**
     * {@code treasurerMemberId}: optional; sets the pool treasurer (A137: only while the pool has no deposits or pool
     * expenses). Trip budget (A190, A193): {@code budgetMinor} (1..10^12 piasters), {@code tripStartDate} and
     * {@code tripEndDate} (YYYY-MM-DD, end on or after start on the resulting state) are each optional; absent or null
     * means "no change", {@code clearBudget} / {@code clearTripStartDate} / {@code clearTripEndDate} = true clears it,
     * and a value with its clear flag is a 422.
     */
    public record UpdateGroupRequest(String name, String type, UUID treasurerMemberId, Long budgetMinor,
                                     Boolean clearBudget, LocalDate tripStartDate, Boolean clearTripStartDate,
                                     LocalDate tripEndDate, Boolean clearTripEndDate) {

        public UpdateGroupRequest(String name, String type, UUID treasurerMemberId) {
            this(name, type, treasurerMemberId, null, null, null, null, null, null);
        }
    }

    public record CreateMemberRequest(String displayName) {
    }

    /**
     * Every field is optional but at least one must be sent. {@code role} (ADMIN or MEMBER) is the Owner's;
     * {@code status} (ACTIVE or LEFT) is the Owner's and Admin's. {@code defaultShareUnits} (1..100, A188) prefills the
     * SHARES editor only and needs the same permission as a rename; {@code clearDefaultShareUnits} = true clears it
     * (A193). Nothing else can be set (B12, A80).
     */
    public record UpdateMemberRequest(String displayName, String role, String status, Integer defaultShareUnits,
                                      Boolean clearDefaultShareUnits) {

        public UpdateMemberRequest(String displayName, String role, String status) {
            this(displayName, role, status, null, null);
        }
    }

    public record TransferOwnershipRequest(UUID toMemberId) {
    }

    /**
     * A member. {@code isYou} is true for the member that represents the signed-in user (the group owner, who is
     * member #1 of every group they create); it is computed by the server and cannot be set by a client.
     */
    public record MemberDto(UUID id, String displayName, int sortOrder, Instant createdAt,
                            @JsonProperty("isYou") boolean isYou, String role, String status, boolean hasAccount,
                            Integer defaultShareUnits) {
        static MemberDto from(Member m, UUID callerUserId) {
            return new MemberDto(m.getId(), m.getDisplayName(), m.getSortOrder(), m.getCreatedAt(),
                    m.getUserId() != null && m.getUserId().equals(callerUserId), m.getRole(), m.getStatus(),
                    m.getUserId() != null, m.getDefaultShareUnits());
        }
    }

    /**
     * List row. totalSpentMinor sums non-deleted expenses; lastExpenseAt is null when there are none.
     * {@code yourNetMinor}: what the caller is owed (positive) or owes (negative) in this group, in integer piasters
     * of the group's currency; null when the caller has no member in the group. Never add amounts of groups with
     * different currencies.
     */
    public record GroupSummaryDto(UUID id, String name, String type, String currencyCode, long memberCount,
                                  long totalSpentMinor, Instant lastExpenseAt, Long yourNetMinor, String yourRole) {
        static GroupSummaryDto from(GroupService.GroupSummary s) {
            return new GroupSummaryDto(s.id(), s.name(), s.type(), s.currencyCode(), s.memberCount(),
                    s.totalSpentMinor(), s.lastExpenseAt(), s.yourNetMinor(), s.yourRole());
        }
    }

    /** {@code yourMemberId} and {@code yourNetMinor} are null when the caller has no member in the group. {@code muted}: the caller's own
     * notification mute for this group (B16). */
    public record GroupDto(UUID id, String name, String type, String currencyCode, Instant createdAt,
                           Instant updatedAt, int version, long totalSpentMinor, Instant lastExpenseAt,
                           UUID yourMemberId, Long yourNetMinor, String yourRole, boolean muted,
                           List<MemberDto> members, UUID treasurerMemberId, Long poolBalanceMinor,
                           Long budgetMinor, LocalDate tripStartDate, LocalDate tripEndDate) {
        static GroupDto from(GroupService.GroupDetail d, UUID callerUserId) {
            ExpenseGroup g = d.group();
            return new GroupDto(g.getId(), g.getName(), g.getType(), g.getCurrencyCode(), g.getCreatedAt(),
                    g.getUpdatedAt(), g.getVersion(), d.totalSpentMinor(), d.lastExpenseAt(), d.yourMemberId(),
                    d.yourNetMinor(), d.yourRole(), d.muted(), d.members().stream().map(m -> MemberDto.from(m, callerUserId)).toList(),
                    g.getTreasurerMemberId(), d.poolBalanceMinor(), g.getBudgetMinor(), g.getTripStartDate(),
                    g.getTripEndDate());
        }
    }
}
