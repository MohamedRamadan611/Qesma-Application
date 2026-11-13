package app.qesma.persistence;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

/** Storage of payment handles (B14). Values are personal data: nothing here logs them. */
@Repository
public class PaymentHandleStore {

    public static final String INSTAPAY = "INSTAPAY";
    public static final String WALLET = "WALLET";

    private final JdbcTemplate jdbc;

    public PaymentHandleStore(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    /** Locks the user row until the transaction ends so two PUTs of one user are serialised; false if no such user. */
    public boolean lockUser(UUID userId) {
        return !jdbc.queryForList("select 1 from users where id = ? for update", userId).isEmpty();
    }

    /** type -> value of one user. */
    public Map<String, String> findByUser(UUID userId) {
        Map<String, String> out = new HashMap<>();
        jdbc.query("select type, value from payment_handles where user_id = ?",
                rs -> {
                    out.put(rs.getString(1), rs.getString(2));
                }, userId);
        return out;
    }

    public void upsert(UUID userId, String type, String value) {
        jdbc.update("""
                insert into payment_handles (id, user_id, type, value) values (?, ?, ?, ?)
                on conflict (user_id, type) do update set value = excluded.value, updated_at = now()
                """, UUID.randomUUID(), userId, type, value);
    }

    public void delete(UUID userId, String type) {
        jdbc.update("delete from payment_handles where user_id = ? and type = ?", userId, type);
    }

    /** For account deletion (B17). */
    public int deleteAll(UUID userId) {
        return jdbc.update("delete from payment_handles where user_id = ?", userId);
    }
}
