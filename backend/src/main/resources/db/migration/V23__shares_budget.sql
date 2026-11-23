-- V23: fair-share SHARES split with proration by days present (A185-A189, STANDALONE_SPEC 19), the member default
-- weight (A188) and the group trip budget settings (A190, STANDALONE_SPEC 20.1). Forward-only and additive.
--
-- Existing rows stay valid and keep their meaning: every new column is nullable and NULL on every existing row, which
-- each new CHECK accepts, so there is no backfill. Balances do not change (expense_splits.owed_minor and
-- expense_payers are untouched; balances keep reading owed_minor only). Budget figures are never stored (A191).
--
-- Cross-table rules ("share_units is set exactly on the splits of a SHARES expense", "presence lies inside the
-- expense period") cannot be a CHECK (expense_splits has no split_type); they live in the validator and the engine,
-- like the itemized breakdown (A196).
--
-- Migration safety: nullable ADD COLUMN without a default is metadata-only. The replaced split_type CHECK and the new
-- CHECKs scan their tables under the ACCESS EXCLUSIVE lock Flyway holds until commit (one transaction). Accepted: the
-- Java backend is frozen for the standalone release and these tables are small. The replaced CHECK is dropped and
-- re-added in the same transaction, so no row is ever unchecked.

-- ---- expenses: the SHARES split type and its optional period ------------------------------------------------------
-- Replaces the V5 rule: SHARES is the fourth split type.
ALTER TABLE expenses DROP CONSTRAINT ck_expenses_split_type;
ALTER TABLE expenses ADD CONSTRAINT ck_expenses_split_type
    CHECK (split_type IN ('EQUAL', 'EXACT', 'ITEMIZED', 'SHARES'));

ALTER TABLE expenses ADD COLUMN period_from date;
ALTER TABLE expenses ADD COLUMN period_to date;

-- Both bounds or neither; only on SHARES; inclusive and at most 366 days (period_to - period_from <= 365).
ALTER TABLE expenses ADD CONSTRAINT ck_expenses_period CHECK (
    (period_from IS NULL AND period_to IS NULL)
    OR (split_type = 'SHARES' AND period_from IS NOT NULL AND period_to IS NOT NULL
        AND period_to >= period_from AND period_to - period_from <= 365));

-- ---- expense_splits: units and presence per participant (inputs only; owed_minor stays the stored result) ---------
ALTER TABLE expense_splits ADD COLUMN share_units integer;
ALTER TABLE expense_splits ADD COLUMN present_from date;
ALTER TABLE expense_splits ADD COLUMN present_to date;

ALTER TABLE expense_splits ADD CONSTRAINT ck_expense_splits_share_units
    CHECK (share_units IS NULL OR share_units BETWEEN 1 AND 100);

-- Presence is both bounds or neither, only next to units, and not reversed.
ALTER TABLE expense_splits ADD CONSTRAINT ck_expense_splits_presence CHECK (
    (present_from IS NULL AND present_to IS NULL)
    OR (share_units IS NOT NULL AND present_from IS NOT NULL AND present_to IS NOT NULL
        AND present_to >= present_from));

-- A split row is either an itemized breakdown row or a SHARES row, never both.
ALTER TABLE expense_splits ADD CONSTRAINT ck_expense_splits_shares_not_itemized
    CHECK (share_units IS NULL OR items_minor IS NULL);

-- ---- members: the default weight, a SHARES form prefill only (A188) -----------------------------------------------
ALTER TABLE members ADD COLUMN default_share_units integer;
ALTER TABLE members ADD CONSTRAINT ck_members_default_share_units
    CHECK (default_share_units IS NULL OR default_share_units BETWEEN 1 AND 100);

-- ---- expense_groups: trip budget settings (A190); each optional and clearable ----------------------------------
ALTER TABLE expense_groups ADD COLUMN budget_minor bigint;
ALTER TABLE expense_groups ADD COLUMN trip_start_date date;
ALTER TABLE expense_groups ADD COLUMN trip_end_date date;

ALTER TABLE expense_groups ADD CONSTRAINT ck_expense_groups_budget
    CHECK (budget_minor IS NULL OR budget_minor BETWEEN 1 AND 1000000000000);
ALTER TABLE expense_groups ADD CONSTRAINT ck_expense_groups_trip_dates
    CHECK (trip_start_date IS NULL OR trip_end_date IS NULL OR trip_end_date >= trip_start_date);
