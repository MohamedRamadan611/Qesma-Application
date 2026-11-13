package app.qesma.service;

import app.qesma.persistence.GroupEventStore;
import app.qesma.persistence.NotificationStore;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.micrometer.core.instrument.MeterRegistry;
import jakarta.persistence.EntityManager;
import java.time.Clock;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Collection;
import java.util.LinkedHashSet;
import java.util.Set;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

/**
 * The single write point of group events and notifications (B15, A95). Called only by services, inside the business
 * transaction ({@code MANDATORY}: it can never run in a transaction of its own), after every replay short-circuit and
 * only for a real change. Exactly two statements per event whatever the number of recipients: the event row and one
 * {@code INSERT ... SELECT} that resolves the recipients and writes all their notifications. B16 adds its mute filter
 * to that same statement; B18 reads the committed rows.
 *
 * <p>Nothing here logs or tags a payload, a name or a title: only ids, the type and counts.
 */
@Service
public class GroupEventRecorder {

    private static final Logger log = LoggerFactory.getLogger(GroupEventRecorder.class);

    /**
     * Who gets a notification: the listed members and/or the Owner and Admins. In every case only ACTIVE members with
     * an account, never the actor's own member, and each account once (A98).
     */
    public record Recipients(Set<UUID> memberIds, boolean includeManagers) {

        public Recipients {
            memberIds = Set.copyOf(memberIds);
        }

        public static Recipients members(Collection<UUID> ids) {
            return new Recipients(new LinkedHashSet<>(ids), false);
        }

        public static Recipients managers() {
            return new Recipients(Set.of(), true);
        }

        public static Recipients membersAndManagers(Collection<UUID> ids) {
            return new Recipients(new LinkedHashSet<>(ids), true);
        }

        /** Feed only. */
        public static Recipients none() {
            return new Recipients(Set.of(), false);
        }

        boolean isEmpty() {
            return memberIds.isEmpty() && !includeManagers;
        }
    }

    private final GroupEventStore events;
    private final NotificationStore notifications;
    private final EntityManager entityManager;
    private final ObjectMapper mapper;
    private final Clock clock;
    private final MeterRegistry metrics;

    public GroupEventRecorder(GroupEventStore events, NotificationStore notifications, EntityManager entityManager,
                              ObjectMapper mapper, Clock clock, MeterRegistry metrics) {
        this.events = events;
        this.notifications = notifications;
        this.entityManager = entityManager;
        this.mapper = mapper;
        this.clock = clock;
        this.metrics = metrics;
    }

    /**
     * Records one event of {@code groupId} and notifies {@code recipients}. {@code actorMemberId} is the member who did
     * it (null when there is none, e.g. a join request from somebody who is not a member yet).
     */
    @Transactional(propagation = Propagation.MANDATORY)
    public UUID record(UUID groupId, UUID actorMemberId, EventType type, EventPayload payload, Recipients recipients) {
        entityManager.flush();     // JdbcTemplate does not see Hibernate's pending changes (members, status, roles)
        Instant now = clock.instant().truncatedTo(ChronoUnit.MICROS);   // PostgreSQL stores microseconds
        UUID eventId = UUID.randomUUID();
        events.insert(eventId, groupId, actorMemberId, type.name(), json(payload), now);
        int notified = recipients.isEmpty() ? 0
                : notifications.insertFor(eventId, groupId, recipients.memberIds(), recipients.includeManagers(),
                        actorMemberId, now);
        metrics.counter("qesma.events", "type", type.name()).increment();
        if (notified > 0) {
            metrics.counter("qesma.notifications", "type", type.name()).increment(notified);
        }
        log.atInfo().addKeyValue("event", "activity.recorded").addKeyValue("groupId", groupId)
                .addKeyValue("eventId", eventId).addKeyValue("type", type).addKeyValue("notified", notified)
                .log("activity.recorded groupId={} eventId={} type={} notified={}", groupId, eventId, type, notified);
        return eventId;
    }

    private String json(EventPayload payload) {
        try {
            return mapper.writeValueAsString(payload);
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("Could not serialize event payload", e);
        }
    }
}
