-- V4: expense groups and members (spec section 6) plus the CHECKs the spec's rules imply.
-- New tables only: no locks on existing data.
--
-- Deviations from the spec 6 table, recorded in the Decision Log (A20):
--   * expense_groups.member_seq: per-group counter so members.sort_order is never reused (spec 7.10).
--   * UNIQUE (group_id, sort_order): DB backstop for the counter, also serves the ordered member read.

CREATE TABLE expense_groups (
    id            uuid        PRIMARY KEY,
    owner_user_id uuid        NOT NULL REFERENCES users (id),
    name          text        NOT NULL,
    type          text        NOT NULL,
    currency_code char(3)     NOT NULL DEFAULT 'EGP',
    created_at    timestamptz NOT NULL DEFAULT now(),
    updated_at    timestamptz NOT NULL DEFAULT now(),
    version       int         NOT NULL DEFAULT 1,
    member_seq    int         NOT NULL DEFAULT 0,
    CONSTRAINT ck_expense_groups_name_length CHECK (char_length(btrim(name)) BETWEEN 1 AND 60),
    CONSTRAINT ck_expense_groups_type CHECK (type IN ('TRIP', 'HOUSING', 'OUTING', 'OTHER')),
    CONSTRAINT ck_expense_groups_currency CHECK (currency_code ~ '^[A-Z]{3}$'),
    CONSTRAINT ck_expense_groups_version CHECK (version >= 1),
    CONSTRAINT ck_expense_groups_member_seq CHECK (member_seq >= 0)
);

-- The owner's group list, newest first (the only list access path in Phase 1).
CREATE INDEX ix_expense_groups_owner_created ON expense_groups (owner_user_id, created_at DESC, id DESC);

CREATE TABLE members (
    id           uuid        PRIMARY KEY,
    group_id     uuid        NOT NULL REFERENCES expense_groups (id),
    display_name text        NOT NULL,
    user_id      uuid        REFERENCES users (id), -- NULL = ghost member (all members in Phase 1)
    sort_order   int         NOT NULL,
    created_at   timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT ck_members_name_length CHECK (char_length(btrim(display_name)) BETWEEN 1 AND 40),
    CONSTRAINT ck_members_sort_order CHECK (sort_order >= 1),
    CONSTRAINT uq_members_group_sort_order UNIQUE (group_id, sort_order)
);

CREATE UNIQUE INDEX ux_members_group_name ON members (group_id, lower(display_name));
