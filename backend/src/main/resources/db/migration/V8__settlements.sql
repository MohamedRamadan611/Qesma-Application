-- V8: settlements (spec section 6, 7.8) and the money-amount cap (review CP2-001).
--
-- Settlement: a recorded real-world payment from -> to. Soft-deleted via deleted_at (the row stays; balances ignore
-- it). No version column: the spec has none and DELETE needs no If-Match.
--
-- Amount cap: every stored amount is at most 10^12 piasters (10 billion EGP; engine Limits.MAX_AMOUNT_MINOR), so
-- sums over a group's ledger cannot overflow bigint-backed Java longs. The cap is added as CHECK constraints to the
-- existing money tables. ADD CONSTRAINT scans those tables under a short lock; they are small and pre-release.
-- Any development row above the cap makes this migration fail loudly: delete such rows first.
--
-- Not expressible as CHECKs (service + tests): both members belong to the group of the settlement.

CREATE TABLE settlements (
    id                 uuid        PRIMARY KEY,
    group_id           uuid        NOT NULL REFERENCES expense_groups (id),
    from_member_id     uuid        NOT NULL REFERENCES members (id),   -- the one who paid
    to_member_id       uuid        NOT NULL REFERENCES members (id),   -- the one who received
    amount_minor       bigint      NOT NULL,
    settled_on         date        NOT NULL,
    note               text,
    created_by_user_id uuid        NOT NULL REFERENCES users (id),
    created_at         timestamptz NOT NULL DEFAULT now(),
    deleted_at         timestamptz,
    CONSTRAINT ck_settlements_amount CHECK (amount_minor BETWEEN 1 AND 1000000000000),
    CONSTRAINT ck_settlements_members CHECK (from_member_id <> to_member_id),
    CONSTRAINT ck_settlements_note CHECK (note IS NULL OR char_length(btrim(note)) BETWEEN 1 AND 200)
);

-- Listing a group's settlements, newest first, soft-deleted excluded (also the balances range).
CREATE INDEX ix_settlements_group_list ON settlements (group_id, settled_on DESC, created_at DESC, id DESC)
    WHERE deleted_at IS NULL;
-- "Does this group have any settlement (deleted ones included)?"
CREATE INDEX ix_settlements_group ON settlements (group_id);
-- Delete-member rule (spec 7.10): is the member in any settlement, deleted ones included?
CREATE INDEX ix_settlements_from_member ON settlements (from_member_id);
CREATE INDEX ix_settlements_to_member ON settlements (to_member_id);

ALTER TABLE expenses ADD CONSTRAINT ck_expenses_total_cap CHECK (total_minor <= 1000000000000);
ALTER TABLE expense_payers ADD CONSTRAINT ck_expense_payers_cap CHECK (amount_minor <= 1000000000000);
ALTER TABLE expense_splits ADD CONSTRAINT ck_expense_splits_cap CHECK (owed_minor <= 1000000000000);
ALTER TABLE expense_items ADD CONSTRAINT ck_expense_items_cap CHECK (amount_minor <= 1000000000000);
