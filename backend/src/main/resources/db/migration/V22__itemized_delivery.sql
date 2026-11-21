-- V22: itemized delivery charge (A180, STANDALONE_SPEC 18): one delivery amount on an itemized bill, outside the
-- discount, service and tax, split equally among the members who have an item. Forward-only and additive.
--
-- Existing rows stay valid and keep their meaning: every ITEMIZED expense and its breakdown rows get delivery 0.
-- Balances do not change (expense_splits.owed_minor and expense_payers are untouched).
--
-- Migration safety: same shape as V21. The backfill UPDATEs touch only ITEMIZED rows; Flyway runs the file in one
-- transaction, so the ACCESS EXCLUSIVE locks on expenses and expense_splits are held until commit while the replaced
-- CHECKs scan the rows. Accepted: the Java backend is frozen for the standalone release and these tables are small.
-- Each replaced CHECK is dropped and re-added in the same transaction, so no row is ever unchecked.

-- ---- expenses: the delivery amount (request and computed total are the same number) ------------------------------
ALTER TABLE expenses ADD COLUMN delivery_minor bigint;
UPDATE expenses SET delivery_minor = 0 WHERE split_type = 'ITEMIZED' AND delivery_minor IS NULL;

ALTER TABLE expenses ADD CONSTRAINT ck_expenses_delivery_range
    CHECK (delivery_minor IS NULL OR delivery_minor BETWEEN 0 AND 1000000000000);

-- Replaces the V21 rule: every itemized-only column is NULL on EQUAL/EXACT expenses, delivery included.
ALTER TABLE expenses DROP CONSTRAINT ck_expenses_itemized_columns;
ALTER TABLE expenses ADD CONSTRAINT ck_expenses_itemized_columns CHECK (
    split_type = 'ITEMIZED' OR (
        subtotal_minor IS NULL AND service_bps IS NULL AND service_minor IS NULL AND tax_bps IS NULL
        AND tax_minor IS NULL AND tax_base IS NULL AND adjustment_minor IS NULL
        AND discount_bps IS NULL AND discount_amount_minor IS NULL AND discount_minor IS NULL
        AND service_amount_minor IS NULL AND tax_amount_minor IS NULL AND delivery_minor IS NULL));

-- Replaces the V21 rule: total = subtotal - discount + service + tax + delivery + adjustment; delivery is present on
-- every ITEMIZED expense. The other charge rules are unchanged.
ALTER TABLE expenses DROP CONSTRAINT ck_expenses_itemized_charges;
ALTER TABLE expenses ADD CONSTRAINT ck_expenses_itemized_charges CHECK (
    split_type <> 'ITEMIZED' OR (
        subtotal_minor IS NOT NULL AND subtotal_minor > 0
        AND discount_minor IS NOT NULL AND discount_minor >= 0 AND discount_minor < subtotal_minor
        AND service_minor IS NOT NULL AND service_minor >= 0
        AND tax_minor IS NOT NULL AND tax_minor >= 0
        AND delivery_minor IS NOT NULL AND delivery_minor >= 0
        AND adjustment_minor IS NOT NULL
        AND total_minor = subtotal_minor - discount_minor + service_minor + tax_minor + delivery_minor + adjustment_minor
        AND ((discount_bps IS NOT NULL OR discount_amount_minor IS NOT NULL) = (discount_minor > 0))
        AND (discount_amount_minor IS NULL OR discount_minor = discount_amount_minor)
        AND (service_bps IS NOT NULL OR service_amount_minor IS NOT NULL OR service_minor = 0)
        AND (service_amount_minor IS NULL OR service_minor = service_amount_minor)
        AND (tax_bps IS NOT NULL OR tax_amount_minor IS NOT NULL OR tax_minor = 0)
        AND (tax_amount_minor IS NULL OR tax_minor = tax_amount_minor)
        AND ((tax_bps IS NULL AND tax_amount_minor IS NULL) = (tax_base IS NULL))));

-- ---- expense_splits: per-member delivery ---------------------------------------------------------------------------
ALTER TABLE expense_splits ADD COLUMN delivery_minor bigint;
UPDATE expense_splits SET delivery_minor = 0 WHERE items_minor IS NOT NULL AND delivery_minor IS NULL;

-- Replaces the V21 rule: the breakdown is all-or-nothing (delivery included) and explains owed exactly.
ALTER TABLE expense_splits DROP CONSTRAINT ck_expense_splits_breakdown;
ALTER TABLE expense_splits ADD CONSTRAINT ck_expense_splits_breakdown CHECK (
    (items_minor IS NULL AND discount_minor IS NULL AND service_minor IS NULL AND tax_minor IS NULL
        AND adjustment_minor IS NULL AND delivery_minor IS NULL)
    OR (items_minor IS NOT NULL AND items_minor >= 0
        AND discount_minor IS NOT NULL AND discount_minor >= 0 AND discount_minor <= items_minor
        AND service_minor IS NOT NULL AND service_minor >= 0
        AND tax_minor IS NOT NULL AND tax_minor >= 0
        AND delivery_minor IS NOT NULL AND delivery_minor >= 0
        AND adjustment_minor IS NOT NULL
        AND owed_minor = items_minor - discount_minor + service_minor + tax_minor + delivery_minor + adjustment_minor));
