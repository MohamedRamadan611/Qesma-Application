-- V20: BSA1 (standalone contract): expense category, pool treasurer, paid-from-pool expenses, settlement kind.
-- Additive and forward-only. Every new column has a default (or is nullable), so existing rows stay valid:
-- category OTHER, paid_from_pool false, kind PAYMENT, no treasurer. Balances are unaffected (nothing reads the new columns).
ALTER TABLE expenses ADD COLUMN category text NOT NULL DEFAULT 'OTHER';
ALTER TABLE expenses ADD CONSTRAINT ck_expenses_category CHECK (category IN
    ('FOOD', 'TRANSPORT', 'FUEL', 'ACCOMMODATION', 'GROCERIES', 'SHOPPING', 'ENTERTAINMENT', 'BILLS', 'OTHER'));
ALTER TABLE expenses ADD COLUMN paid_from_pool boolean NOT NULL DEFAULT false;

ALTER TABLE settlements ADD COLUMN kind text NOT NULL DEFAULT 'PAYMENT';
ALTER TABLE settlements ADD CONSTRAINT ck_settlements_kind CHECK (kind IN ('PAYMENT', 'POOL_DEPOSIT'));

-- The treasurer must be a member of the same group (DB backstop; "ACTIVE" is checked by the service, A137).
ALTER TABLE members ADD CONSTRAINT uq_members_id_group UNIQUE (id, group_id);
ALTER TABLE expense_groups ADD COLUMN treasurer_member_id uuid;
ALTER TABLE expense_groups ADD CONSTRAINT fk_groups_treasurer
    FOREIGN KEY (treasurer_member_id, id) REFERENCES members (id, group_id);

CREATE INDEX ix_expenses_group_category ON expenses (group_id, category) WHERE deleted_at IS NULL;
CREATE INDEX ix_expenses_pool ON expenses (group_id) WHERE paid_from_pool;
CREATE INDEX ix_settlements_deposits ON settlements (group_id) WHERE kind = 'POOL_DEPOSIT';
