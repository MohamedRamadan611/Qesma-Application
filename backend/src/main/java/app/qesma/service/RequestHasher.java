package app.qesma.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Component;

/**
 * Canonical hash of a create-expense request for idempotency (spec 8.3). Two requests that mean the same thing
 * hash the same: text is already trimmed/normalized, lists are sorted by member id, JSON keys have a fixed order.
 * The endpoint and group id are part of the input, so a key reused on another group or endpoint never matches.
 * An omitted participant list and an explicit one are different requests and hash differently.
 */
@Component
public class RequestHasher {

    private final ObjectMapper mapper;

    public RequestHasher(ObjectMapper mapper) {
        this.mapper = mapper;
    }

    String hash(String endpoint, UUID groupId, ExpenseValidator.Valid v) {
        Map<String, Object> canonical = new LinkedHashMap<>();
        canonical.put("endpoint", endpoint);
        canonical.put("groupId", groupId.toString());
        canonical.put("title", v.title());
        canonical.put("expenseDate", v.expenseDate().toString());
        canonical.put("splitType", v.splitType());
        canonical.put("totalMinor", v.totalMinor());
        canonical.put("payers", amounts(v.payers().stream()
                .map(p -> new Entry(p.memberId(), p.amountMinor())).toList()));
        canonical.put("participantMemberIds", v.participantMemberIds() == null ? null
                : v.participantMemberIds().stream().map(UUID::toString).sorted().toList());
        canonical.put("shares", v.shares() == null ? null : amounts(v.shares().stream()
                .map(s -> new Entry(s.memberId(), s.amountMinor())).toList()));
        if (v.items() != null) {
            // Item order is user-visible (it is stored), so it is part of the meaning; assignee order is not.
            canonical.put("items", v.items().stream().map(i -> {
                Map<String, Object> m = new LinkedHashMap<>();
                m.put("name", i.name());
                m.put("amountMinor", i.amountMinor());
                m.put("assigneeMemberIds", i.assigneeMemberIds().stream().map(UUID::toString).sorted().toList());
                return m;
            }).toList());
            canonical.put("serviceBps", v.serviceBps());
            canonical.put("taxBps", v.taxBps());
            canonical.put("taxBase", v.taxBase());
            canonical.put("adjustmentMinor", v.adjustmentMinor());
        }
        try {
            byte[] json = mapper.writeValueAsString(canonical).getBytes(StandardCharsets.UTF_8);
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(json));
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("Could not canonicalize request", e);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 is required by the JVM specification", e);
        }
    }

    /** Canonical hash for other create endpoints: endpoint and group id first, then the already-normalized body. */
    String hash(String endpoint, UUID groupId, Map<String, Object> normalizedBody) {
        Map<String, Object> canonical = new LinkedHashMap<>();
        canonical.put("endpoint", endpoint);
        canonical.put("groupId", groupId.toString());
        canonical.putAll(normalizedBody);
        try {
            byte[] json = mapper.writeValueAsString(canonical).getBytes(StandardCharsets.UTF_8);
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(json));
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("Could not canonicalize request", e);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 is required by the JVM specification", e);
        }
    }

    private record Entry(UUID memberId, long amountMinor) {
    }

    private static List<Map<String, Object>> amounts(List<Entry> entries) {
        List<Entry> sorted = new ArrayList<>(entries);
        sorted.sort(Comparator.comparing((Entry e) -> e.memberId().toString()).thenComparingLong(Entry::amountMinor));
        List<Map<String, Object>> out = new ArrayList<>();
        for (Entry e : sorted) {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("memberId", e.memberId().toString());
            m.put("amountMinor", e.amountMinor());
            out.add(m);
        }
        return out;
    }
}
