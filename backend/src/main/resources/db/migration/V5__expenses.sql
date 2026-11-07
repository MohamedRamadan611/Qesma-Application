-- V5: expenses, payers, resolved splits and idempotency keys (spec section 6).
-- New tables only: no locks on existing data.
--
-- Not created here (later milestones): expense_items / expense_item_assignees (B5),
-- expense_revisions (B6), settlements (B7).
--
-- Cross-row rules (sum of payers = total = sum of owed; members belong to the expense's group) cannot be
-- expressed as CHECK constraints on the spec's tables. They are enforced by the engine and the service and
-- proven by integration tests (spec 6 notes).

CREATE TABLE expenses (
    id                 uuid        PRIMARY KEY,
    group_id           uuid        NOT NULL REFERENCES expense_groups (id),
    title              text        NOT NULL,
    split_type         text        NOT NULL,
    total_minor        bigint      NOT NULL,
    expense_date       date        NOT NULL,
    -- itemized-only fields (NULL otherwise; filled from B5)
    subtotal_minor     bigint,
    service_bps        int,
    service_minor      bigint,
    tax_bps            int,
    tax_minor          bigint,
    tax_base           text,
    adjustment_minor   bigint,
    created_by_user_id uuid        NOT NULL REFERENCES users (id),
    created_at         timestamptz NOT NULL DEFAULT now(),
    updated_at         timestamptz NOT NULL DEFAULT now(),
    deleted_at         timestamptz,
    version            int         NOT NULL DEFAULT 1,
    CONSTRAINT ck_expenses_total CHECK (total_minor > 0),
    CONSTRAINT ck_expenses_title_length CHECK (char_length(btrim(title)) BETWEEN 1 AND 100),
    CONSTRAINT ck_expenses_split_type CHECK (split_type IN ('EQUAL', 'EXACT', 'ITEMIZED')),
    CONSTRAINT ck_expenses_service_bps CHECK (service_bps IS NULL OR service_bps BETWEEN 0 AND 10000),
    CONSTRAINT ck_expenses_tax_bps CHECK (tax_bps IS NULL OR tax_bps BETWEEN 0 AND 10000),
    CONSTRAINT ck_expenses_tax_base CHECK (tax_base IS NULL OR tax_base IN ('SUBTOTAL', 'SUBTOTAL_PLUS_SERVICE')),
    CONSTRAINT ck_expenses_version CHECK (version >= 1),
    -- Valid for B5 as well: itemized columns may only be set on ITEMIZED expenses.
    CONSTRAINT ck_expenses_itemized_columns CHECK (
        split_type = 'ITEMIZED' OR (
            subtotal_minor IS NULL AND service_bps IS NULL AND service_minor IS NULL AND tax_bps IS NULL
            AND tax_minor IS NULL AND tax_base IS NULL AND adjustment_minor IS NULL))
);

-- Listing a group's expenses, newest first, soft-deleted excluded.
CREATE INDEX ix_expenses_group_list ON expenses (group_id, expense_date DESC, created_at DESC, id DESC)
    WHERE deleted_at IS NULL;
-- "Does this group have any expense (deleted ones included)?" and group-level totals.
CREATE INDEX ix_expenses_group ON expenses (group_id);

CREATE TABLE expense_payers (
    expense_id   uuid   NOT NULL REFERENCES expenses (id),
    member_id    uuid   NOT NULL REFERENCES members (id),
    amount_minor bigint NOT NULL,
    PRIMARY KEY (expense_id, member_id),
    CONSTRAINT ck_expense_payers_amount CHECK (amount_minor > 0)
);

-- Final resolved participants and amounts (the snapshot). "All" is resolved here, one row per participant.
CREATE TABLE expense_splits (
    expense_id       uuid   NOT NULL REFERENCES expenses (id),
    member_id        uuid   NOT NULL REFERENCES members (id),
    owed_minor       bigint NOT NULL,
    -- itemized breakdown (NULL otherwise); owed = items + service + tax + adjustment
    items_minor      bigint,
    service_minor    bigint,
    tax_minor        bigint,
    adjustment_minor bigint,
    PRIMARY KEY (expense_id, member_id),
    CONSTRAINT ck_expense_splits_owed CHECK (owed_minor >= 0)
);

-- Member lookups: delete-member usage check (spec 7.10), memberId filter, and balance queries (B7).
CREATE INDEX ix_expense_payers_member ON expense_payers (member_id);
CREATE INDEX ix_expense_splits_member ON expense_splits (member_id);

CREATE TABLE idempotency_keys (
    user_id         uuid        NOT NULL REFERENCES users (id),
    key             text        NOT NULL,
    endpoint        text        NOT NULL,
    request_hash    text        NOT NULL,
    response_status int         NOT NULL,
    response_body   jsonb       NOT NULL,
    created_at      timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, key)
);

-- The cleanup job deletes keys older than 24 hours (spec 8.3).
CREATE INDEX ix_idempotency_keys_created ON idempotency_keys (created_at);
