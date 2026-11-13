package app.qesma;

import static org.springframework.http.HttpMethod.GET;

import com.fasterxml.jackson.databind.JsonNode;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;
import java.util.UUID;

/** Shared helpers of the B15 integration tests: read events and their recipients straight from the database. */
public abstract class AbstractActivityIT extends AbstractApiIT {

    /** The events of the group with this type, oldest first. Keys: id, actor (member id or null), payload (jsonb text). */
    protected List<Map<String, Object>> eventsOf(String gid, String type) {
        return jdbc.queryForList("select id, actor_member_id as actor, payload::text as payload from group_events "
                + "where group_id = ?::uuid and type = ? order by created_at, id", gid, type);
    }

    protected Map<String, Object> onlyEvent(String gid, String type) {
        List<Map<String, Object>> found = eventsOf(gid, type);
        if (found.size() != 1) {
            throw new AssertionError("expected exactly one " + type + " event but found " + found.size());
        }
        return found.get(0);
    }

    /** The accounts notified about an event. */
    protected Set<UUID> recipients(Object eventId) {
        return new TreeSet<>(jdbc.queryForList("select user_id from notifications where event_id = ?::uuid",
                UUID.class, eventId.toString()));
    }

    protected Set<UUID> ids(Session... sessions) {
        Set<UUID> out = new TreeSet<>();
        for (Session s : sessions) {
            out.add(s.userId());
        }
        return out;
    }

    protected long eventCount(String gid) {
        return jdbc.queryForObject("select count(*) from group_events where group_id = ?::uuid", Long.class, gid);
    }

    protected long notificationCount(String gid) {
        return jdbc.queryForObject("select count(*) from notifications n join group_events e on e.id = n.event_id "
                + "where e.group_id = ?::uuid", Long.class, gid);
    }

    protected JsonNode feed(Session as, String gid, String query) throws Exception {
        return body(call(GET, "/api/v1/groups/" + gid + "/activity" + query, as, null));
    }

    protected List<String> idsOf(JsonNode items) {
        List<String> out = new ArrayList<>();
        items.forEach(i -> out.add(i.get("id").asText()));
        return out;
    }
}
