package app.qesma.api;

import app.qesma.domain.ExpenseGroup;
import app.qesma.domain.Member;
import app.qesma.service.GroupService;
import java.time.Instant;
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

    public record UpdateGroupRequest(String name, String type) {
    }

    public record CreateMemberRequest(String displayName) {
    }

    public record UpdateMemberRequest(String displayName) {
    }

    public record MemberDto(UUID id, String displayName, int sortOrder, Instant createdAt) {
        static MemberDto from(Member m) {
            return new MemberDto(m.getId(), m.getDisplayName(), m.getSortOrder(), m.getCreatedAt());
        }
    }

    /** List row. totalSpentMinor and lastExpenseAt are placeholders until expenses exist (B4). */
    public record GroupSummaryDto(UUID id, String name, String type, String currencyCode, long memberCount,
                                  long totalSpentMinor, Instant lastExpenseAt) {
        static GroupSummaryDto from(GroupService.GroupSummary s) {
            return new GroupSummaryDto(s.id(), s.name(), s.type(), s.currencyCode(), s.memberCount(), 0L, null);
        }
    }

    public record GroupDto(UUID id, String name, String type, String currencyCode, Instant createdAt,
                           Instant updatedAt, int version, long totalSpentMinor, List<MemberDto> members) {
        static GroupDto from(ExpenseGroup g, List<Member> members) {
            return new GroupDto(g.getId(), g.getName(), g.getType(), g.getCurrencyCode(), g.getCreatedAt(),
                    g.getUpdatedAt(), g.getVersion(), 0L, members.stream().map(MemberDto::from).toList());
        }

        static GroupDto from(GroupService.GroupDetail d) {
            return from(d.group(), d.members());
        }
    }
}
