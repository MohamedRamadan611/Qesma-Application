-- V6: itemized restaurant bills (spec section 6): items, item assignees, and the invariants that tie an
-- ITEMIZED expense's charges and per-member breakdown together.
--
-- Migration safety: two tables are new. The two ADD CONSTRAINT statements scan `expenses` / `expense_splits`
-- under a short ACCESS EXCLUSIVE lock; at this point both hold only EQUAL/EXACT rows from B4 (ITEMIZED was
-- rejected until now) and both constraints are trivially true for those rows, so the scan is negligible.
--
-- Not expressible as CHECKs (enforced by the engine + service and proven by integration tests): items add up
-- to subtotal_minor, every assignee/payer belongs to the expense's group, sum(owed) = total_minor.

CREATE TABLE expense_items (
    id           uuid   PRIMARY KEY,
    expense_id   uuid   NOT NULL REFERENCES expenses (id),
    name         text   NOT NULL,
    amount_minor bigint NOT NULL,
    sort_order   int    NOT NULL,
    CONSTRAINT ck_expense_items_name CHECK (char_length(btrim(name)) BETWEEN 1 AND 100),
    CONSTRAINT ck_expense_items_amount CHECK (amount_minor > 0),
    CONSTRAINT ck_expense_items_sort CHECK (sort_order >= 0),
    CONSTRAINT ux_expense_items_order UNIQUE (expense_id, sort_order)
);

CREATE TABLE expense_item_assignees (
    item_id   uuid NOT NULL REFERENCES expense_items (id),
    member_id uuid NOT NULL REFERENCES members (id),
    PRIMARY KEY (item_id, member_id)
);

-- Delete-member rule (spec 7.10): an item assignee counts as "used" even when rounding left them owing 0.
CREATE INDEX ix_expense_item_assignees_member ON expense_item_assignees (member_id);

-- An ITEMIZED expense carries all of its charges, and they add up to the total. Service and tax are
-- independent: no rate means no amount, and a tax base exists exactly when a tax rate does.
ALTER TABLE expenses ADD CONSTRAINT ck_expenses_itemized_charges CHECK (
    split_type <> 'ITEMIZED' OR (
        subtotal_minor IS NOT NULL AND subtotal_minor > 0
        AND service_minor IS NOT NULL AND service_minor >= 0
        AND tax_minor IS NOT NULL AND tax_minor >= 0
        AND adjustment_minor IS NOT NULL
        AND total_minor = subtotal_minor + service_minor + tax_minor + adjustment_minor
        AND (service_bps IS NOT NULL OR service_minor = 0)
        AND (tax_bps IS NOT NULL OR tax_minor = 0)
        AND ((tax_bps IS NULL) = (tax_base IS NULL))));

-- The per-member breakdown is all-or-nothing, and when present it explains owed_minor exactly.
ALTER TABLE expense_splits ADD CONSTRAINT ck_expense_splits_breakdown CHECK (
    (items_minor IS NULL AND service_minor IS NULL AND tax_minor IS NULL AND adjustment_minor IS NULL)
    OR (items_minor IS NOT NULL AND items_minor >= 0 AND service_minor IS NOT NULL AND service_minor >= 0
        AND tax_minor IS NOT NULL AND tax_minor >= 0 AND adjustment_minor IS NOT NULL
        AND owed_minor = items_minor + service_minor + tax_minor + adjustment_minor));
