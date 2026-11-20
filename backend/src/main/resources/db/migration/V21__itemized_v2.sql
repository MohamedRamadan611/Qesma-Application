-- V21: BSA2 (itemized bill v2, A171-A177, STANDALONE_SPEC 18): item quantity and unit price, one bill discount
-- (percent or amount), service and tax as amounts. Forward-only and additive.
--
-- Existing rows stay valid and keep their meaning: every item becomes quantity 1 with unit = amount, every
-- ITEMIZED expense and its breakdown rows get discount 0, and no row uses an amount-form charge. Balances do not
-- change (nothing that feeds them is rewritten: expense_splits.owed_minor and expense_payers are untouched).
--
-- Migration safety: the backfill UPDATEs touch only ITEMIZED rows (items, itemized expenses, their breakdown
-- rows). Flyway runs this file in one transaction, so the ACCESS EXCLUSIVE locks on expense_items, expenses and
-- expense_splits are held until commit while the new CHECKs scan the rows. Accepted: the Java backend is frozen for
-- the standalone release and these tables are small (no NOT VALID / VALIDATE split would shorten a single-transaction
-- lock). The three replaced CHECKs are dropped and re-added in the same transaction, so no row is ever unchecked.
-- ADD COLUMN with a constant default (quantity) is metadata-only on PostgreSQL 11+.

-- ---- expense_items: quantity x unit price = amount ---------------------------------------------------------------
ALTER TABLE expense_items ADD COLUMN quantity int NOT NULL DEFAULT 1;
ALTER TABLE expense_items ADD COLUMN unit_amount_minor bigint;
UPDATE expense_items SET unit_amount_minor = amount_minor WHERE unit_amount_minor IS NULL;
ALTER TABLE expense_items ALTER COLUMN unit_amount_minor SET NOT NULL;

ALTER TABLE expense_items ADD CONSTRAINT ck_expense_items_quantity CHECK (quantity BETWEEN 1 AND 999);
ALTER TABLE expense_items ADD CONSTRAINT ck_expense_items_unit
    CHECK (unit_amount_minor > 0 AND unit_amount_minor <= 1000000000000);
-- No overflow: 999 x 10^12 fits in bigint.
ALTER TABLE expense_items ADD CONSTRAINT ck_expense_items_line
    CHECK (amount_minor = quantity::bigint * unit_amount_minor);

-- ---- expenses: discount and amount-form charges -------------------------------------------------------------------
-- discount_bps / discount_amount_minor / service_amount_minor / tax_amount_minor are the request (which form);
-- discount_minor is the computed discount total, like service_minor and tax_minor.
ALTER TABLE expenses ADD COLUMN discount_bps int;
ALTER TABLE expenses ADD COLUMN discount_amount_minor bigint;
ALTER TABLE expenses ADD COLUMN discount_minor bigint;
ALTER TABLE expenses ADD COLUMN service_amount_minor bigint;
ALTER TABLE expenses ADD COLUMN tax_amount_minor bigint;
UPDATE expenses SET discount_minor = 0 WHERE split_type = 'ITEMIZED' AND discount_minor IS NULL;

ALTER TABLE expenses ADD CONSTRAINT ck_expenses_discount_bps
    CHECK (discount_bps IS NULL OR discount_bps BETWEEN 1 AND 9999);
ALTER TABLE expenses ADD CONSTRAINT ck_expenses_charge_amounts CHECK (
    (discount_amount_minor IS NULL OR discount_amount_minor BETWEEN 1 AND 1000000000000)
    AND (service_amount_minor IS NULL OR service_amount_minor BETWEEN 1 AND 1000000000000)
    AND (tax_amount_minor IS NULL OR tax_amount_minor BETWEEN 1 AND 1000000000000));
-- Each charge is in one form at most: a percentage or an amount (A171, A173).
ALTER TABLE expenses ADD CONSTRAINT ck_expenses_charge_one_form CHECK (
    NOT (discount_bps IS NOT NULL AND discount_amount_minor IS NOT NULL)
    AND NOT (service_bps IS NOT NULL AND service_amount_minor IS NOT NULL)
    AND NOT (tax_bps IS NOT NULL AND tax_amount_minor IS NOT NULL));

-- Replaces the V5 rule: every itemized-only column (old and new) is NULL on EQUAL/EXACT expenses.
ALTER TABLE expenses DROP CONSTRAINT ck_expenses_itemized_columns;
ALTER TABLE expenses ADD CONSTRAINT ck_expenses_itemized_columns CHECK (
    split_type = 'ITEMIZED' OR (
        subtotal_minor IS NULL AND service_bps IS NULL AND service_minor IS NULL AND tax_bps IS NULL
        AND tax_minor IS NULL AND tax_base IS NULL AND adjustment_minor IS NULL
        AND discount_bps IS NULL AND discount_amount_minor IS NULL AND discount_minor IS NULL
        AND service_amount_minor IS NULL AND tax_amount_minor IS NULL));

-- Replaces the V6 rule: total = subtotal - discount + service + tax + adjustment; a charge > 0 has a form; an
-- amount-form charge is exactly its amount; 0 <= discount < subtotal; a tax base exists exactly when a tax does.
ALTER TABLE expenses DROP CONSTRAINT ck_expenses_itemized_charges;
ALTER TABLE expenses ADD CONSTRAINT ck_expenses_itemized_charges CHECK (
    split_type <> 'ITEMIZED' OR (
        subtotal_minor IS NOT NULL AND subtotal_minor > 0
        AND discount_minor IS NOT NULL AND discount_minor >= 0 AND discount_minor < subtotal_minor
        AND service_minor IS NOT NULL AND service_minor >= 0
        AND tax_minor IS NOT NULL AND tax_minor >= 0
        AND adjustment_minor IS NOT NULL
        AND total_minor = subtotal_minor - discount_minor + service_minor + tax_minor + adjustment_minor
        AND ((discount_bps IS NOT NULL OR discount_amount_minor IS NOT NULL) = (discount_minor > 0))
        AND (discount_amount_minor IS NULL OR discount_minor = discount_amount_minor)
        AND (service_bps IS NOT NULL OR service_amount_minor IS NOT NULL OR service_minor = 0)
        AND (service_amount_minor IS NULL OR service_minor = service_amount_minor)
        AND (tax_bps IS NOT NULL OR tax_amount_minor IS NOT NULL OR tax_minor = 0)
        AND (tax_amount_minor IS NULL OR tax_minor = tax_amount_minor)
        AND ((tax_bps IS NULL AND tax_amount_minor IS NULL) = (tax_base IS NULL))));

-- ---- expense_splits: per-member discount ---------------------------------------------------------------------------
ALTER TABLE expense_splits ADD COLUMN discount_minor bigint;
UPDATE expense_splits SET discount_minor = 0 WHERE items_minor IS NOT NULL AND discount_minor IS NULL;

-- Replaces the V6 rule: the breakdown is all-or-nothing and explains owed exactly; a member's discount part never
-- exceeds their items.
ALTER TABLE expense_splits DROP CONSTRAINT ck_expense_splits_breakdown;
ALTER TABLE expense_splits ADD CONSTRAINT ck_expense_splits_breakdown CHECK (
    (items_minor IS NULL AND discount_minor IS NULL AND service_minor IS NULL AND tax_minor IS NULL
        AND adjustment_minor IS NULL)
    OR (items_minor IS NOT NULL AND items_minor >= 0
        AND discount_minor IS NOT NULL AND discount_minor >= 0 AND discount_minor <= items_minor
        AND service_minor IS NOT NULL AND service_minor >= 0
        AND tax_minor IS NOT NULL AND tax_minor >= 0 AND adjustment_minor IS NOT NULL
        AND owed_minor = items_minor - discount_minor + service_minor + tax_minor + adjustment_minor));

