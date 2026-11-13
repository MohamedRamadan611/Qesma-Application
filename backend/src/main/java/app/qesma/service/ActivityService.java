package app.qesma.service;

import app.qesma.api.ApiException;
import app.qesma.persistence.GroupEventStore;
import app.qesma.persistence.NotificationStore;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.time.Clock;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Reads of the group activity feed and the notification center, and marking notifications read (B15, A100-A103).
 * The feed is authorized through {@link GroupAccessService} (non-member or LEFT: 404). The center is always filtered by
 * the caller's own user id in SQL. Each page is ONE statement; the page size is bounded.
 */
@Service
public class ActivityService {

    public static final int DEFAULT_LIMIT = 20;
    public static final int MAX_LIMIT = 50;
    public static final int MAX_IDS = 100;

    /** One event of a group feed. {@code subject}: expense title / member name resolved at read time, else null. */
    public record ActivityItem(UUID id, EventType type, UUID actorMemberId, Instant createdAt, EventPayload payload,
                               String subject) {
    }

    /** A page of the feed, newest first. {@code nextBefore} is the cursor of the next (older) page, null on the last. */
    public record ActivityPage(List<ActivityItem> items, String nextBefore) {
    }

    /** One notification. {@code id} is the notification id (used by mark-read), not the event id. */
    public record NotificationItem(UUID id, UUID groupId, String groupName, EventType type, UUID actorMemberId,
                                   String actorName, Instant createdAt, Instant readAt, EventPayload payload,
                                   String subject) {
    }

    public record NotificationPage(List<NotificationItem> items, String nextBefore) {
    }

    public record UnreadCount(long count) {
    }

    public record MarkReadResult(int marked, long unreadCount) {
    }

    private final GroupAccessService access;
    private final GroupEventStore events;
    private final NotificationStore notifications;
    private final ObjectMapper mapper;
    private final Clock clock;

    public ActivityService(GroupAccessService access, GroupEventStore events, NotificationStore notifications,
                           ObjectMapper mapper, Clock clock) {
        this.access = access;
        this.events = events;
        this.notifications = notifications;
        this.mapper = mapper;
        this.clock = clock;
    }

    @Transactional(readOnly = true)
    public ActivityPage feed(UUID userId, UUID groupId, Integer limit, String before) {
        int size = limit(limit);
        ActivityCursor cursor = before == null ? null : ActivityCursor.decode(before);
        access.requireMember(userId, groupId);                       // 404 for a stranger and for a LEFT member
        List<GroupEventStore.FeedRow> rows = events.feedPage(groupId, timeOf(cursor), idOf(cursor), size + 1);
        boolean more = rows.size() > size;
        List<GroupEventStore.FeedRow> page = more ? rows.subList(0, size) : rows;
        List<ActivityItem> items = page.stream().map(r -> new ActivityItem(r.id(), EventType.valueOf(r.type()),
                r.actorMemberId(), r.createdAt(), payload(r.payload()), r.subject())).toList();
        return new ActivityPage(items, more ? new ActivityCursor(last(page).createdAt(), last(page).id()).encode() : null);
    }

    @Transactional(readOnly = true)
    public NotificationPage notifications(UUID userId, Integer limit, String before) {
        int size = limit(limit);
        ActivityCursor cursor = before == null ? null : ActivityCursor.decode(before);
        List<NotificationStore.CenterRow> rows = notifications.centerPage(userId, timeOf(cursor), idOf(cursor), size + 1);
        boolean more = rows.size() > size;
        List<NotificationStore.CenterRow> page = more ? rows.subList(0, size) : rows;
        List<NotificationItem> items = page.stream().map(r -> new NotificationItem(r.id(), r.groupId(), r.groupName(),
                EventType.valueOf(r.type()), r.actorMemberId(), r.actorName(), r.createdAt(), r.readAt(),
                payload(r.payload()), r.subject())).toList();
        NotificationStore.CenterRow tail = last(page);
        return new NotificationPage(items, more ? new ActivityCursor(tail.createdAt(), tail.id()).encode() : null);
    }

    @Transactional(readOnly = true)
    public UnreadCount unreadCount(UUID userId) {
        return new UnreadCount(notifications.unreadCount(userId));
    }

    /**
     * Marks the caller's own notifications read: the given ids, or all. Ids that are unknown or belong to somebody else
     * match nothing, so the answer is the same for both. Idempotent by state (already-read rows are not counted again).
     */
    @Transactional
    public MarkReadResult markRead(UUID userId, List<UUID> ids, Boolean all) {
        boolean every = Boolean.TRUE.equals(all);
        if (every == (ids != null)) {
            throw ApiException.validation("Send exactly one of ids or all: true");
        }
        Instant now = clock.instant().truncatedTo(ChronoUnit.MICROS);
        int marked;
        if (every) {
            marked = notifications.markAllRead(userId, now);
        } else {
            if (ids.isEmpty() || ids.size() > MAX_IDS || ids.contains(null)) {
                throw ApiException.validation("ids must hold 1 to " + MAX_IDS + " notification ids");
            }
            Set<UUID> distinct = new LinkedHashSet<>(ids);
            marked = notifications.markRead(userId, distinct, now);
        }
        return new MarkReadResult(marked, notifications.unreadCount(userId));
    }

    // ---- helpers ------------------------------------------------------------------------------------------------

    private static int limit(Integer requested) {
        if (requested == null) {
            return DEFAULT_LIMIT;
        }
        if (requested < 1 || requested > MAX_LIMIT) {
            throw ApiException.validation("limit must be between 1 and " + MAX_LIMIT);
        }
        return requested;
    }

    private static String timeOf(ActivityCursor cursor) {
        return cursor == null ? GroupEventStore.NO_CURSOR_TIME : cursor.createdAt().toString();
    }

    private static String idOf(ActivityCursor cursor) {
        return cursor == null ? GroupEventStore.NO_CURSOR_ID : cursor.id().toString();
    }

    private static <T> T last(List<T> list) {
        return list.isEmpty() ? null : list.get(list.size() - 1);
    }

    private EventPayload payload(String json) {
        try {
            return mapper.readValue(json, EventPayload.class);
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("Stored event payload is not valid", e);
        }
    }
}
