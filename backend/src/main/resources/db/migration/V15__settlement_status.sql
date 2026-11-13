-- V15: two-sided settlements (Phase 2, B13, Decisions A83-A89).
--
-- A settlement now has a status. Balances count CONFIRMED rows only (A83). Every Phase 1 row is a payment somebody
-- recorded as already done, so:
--   * live rows (deleted_at IS NULL)  -> CONFIRMED, recorded_by_admin = true (balances stay identical);
--   * Phase 1 soft-deleted rows       -> CANCELLED (balances already ignored them; the history is kept, nothing is dropped).
-- deleted_at stays as a legacy column and is no longer written; the CHECK below only lets it exist on CANCELLED rows.
--
-- Migration safety: forward-only, additive. Columns are added nullable, backfilled, then constrained; settlements is a
-- small pre-release table, so the short ACCESS EXCLUSIVE lock of ALTER TABLE inside the Flyway transaction is fine.

ALTER TABLE settlements
    ADD COLUMN status               text,
    ADD COLUMN declared_at          timestamptz,
    ADD COLUMN confirmed_at         timestamptz,
    ADD COLUMN disputed_at          timestamptz,
    ADD COLUMN cancelled_at         timestamptz,
    ADD COLUMN recorded_by_admin    boolean     NOT NULL DEFAULT false,
    ADD COLUMN created_by_member_id uuid REFERENCES members (id);

UPDATE settlements
SET status               = CASE WHEN deleted_at IS NULL THEN 'CONFIRMED' ELSE 'CANCELLED' END,
    declared_at          = created_at,
    confirmed_at         = CASE WHEN deleted_at IS NULL THEN created_at END,
    cancelled_at         = deleted_at,
    recorded_by_admin    = true,
    created_by_member_id = (SELECT m.id FROM members m
                            WHERE m.group_id = settlements.group_id AND m.user_id = settlements.created_by_user_id);

ALTER TABLE settlements
    ALTER COLUMN status SET NOT NULL,
    ALTER COLUMN declared_at SET NOT NULL,
    ADD CONSTRAINT ck_settlements_status CHECK (status IN ('PENDING', 'CONFIRMED', 'DISPUTED', 'CANCELLED')),
    ADD CONSTRAINT ck_settlements_confirmed_at CHECK ((status = 'CONFIRMED') = (confirmed_at IS NOT NULL)),
    ADD CONSTRAINT ck_settlements_cancelled_at CHECK ((status = 'CANCELLED') = (cancelled_at IS NOT NULL)),
    ADD CONSTRAINT ck_settlements_disputed_at CHECK (status <> 'DISPUTED' OR disputed_at IS NOT NULL),
    ADD CONSTRAINT ck_settlements_pending_clean CHECK (status <> 'PENDING' OR (disputed_at IS NULL AND confirmed_at IS NULL)),
    ADD CONSTRAINT ck_settlements_legacy_deleted CHECK (deleted_at IS NULL OR status = 'CANCELLED');

-- The list now shows every status (cancelled rows stay in the history), so the partial "live only" index is replaced.
DROP INDEX ix_settlements_group_list;
CREATE INDEX ix_settlements_group_list ON settlements (group_id, settled_on DESC, created_at DESC, id DESC);

-- Balance totals read CONFIRMED rows of a group; the pending-pairs statement reads the open ones.
CREATE INDEX ix_settlements_group_confirmed ON settlements (group_id) WHERE status = 'CONFIRMED';
CREATE INDEX ix_settlements_group_open ON settlements (group_id, from_member_id, to_member_id)
    WHERE status IN ('PENDING', 'DISPUTED');
