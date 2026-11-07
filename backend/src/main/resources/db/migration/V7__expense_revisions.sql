-- V7: immutable history of every expense (spec section 6, 7.9). New table only: no lock on existing data.
--
-- One row per change: CREATE (version 1), each UPDATE, and the soft DELETE. `snapshot` is the full expense as it
-- looked right after that change (header, payers, resolved shares, items, charges). Rows are written inside the
-- same transaction as the change they record and are never updated or deleted.
-- UNIQUE (expense_id, version) is a second line of defence: two writers can never produce the same version.
--
-- Expenses created before this migration (development data only) have no CREATE revision.

CREATE TABLE expense_revisions (
    id                  uuid        PRIMARY KEY,
    expense_id          uuid        NOT NULL REFERENCES expenses (id),
    version             int         NOT NULL,
    change_type         text        NOT NULL,
    snapshot            jsonb       NOT NULL,
    changed_by_user_id  uuid        NOT NULL REFERENCES users (id),
    changed_at          timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT ck_expense_revisions_version CHECK (version >= 1),
    CONSTRAINT ck_expense_revisions_type CHECK (change_type IN ('CREATE', 'UPDATE', 'DELETE')),
    CONSTRAINT ux_expense_revisions_version UNIQUE (expense_id, version)
);
