-- V17: group events and in-app notifications (Phase 2, B15, Decisions A95-A103). (V16 was taken by B14.)
--
-- group_events is the append-only feed of a group: one row per real change, written in the same transaction as the
-- business write. The payload holds ids, versions and integer amounts only, never a name or a title (names are
-- resolved at read time). notifications is one row per (event, recipient account): it references the event instead of
-- copying type/payload/group, so there is one payload and nothing to drift. Read state only ever changes read_at.
--
-- group_id cascades: an empty group may be hard-deleted (A23/A82) and the events are derived data, not ledger.
-- actor_member_id is SET NULL: a ghost member can be hard-deleted. notifications.event_id cascades (purge, group
-- delete). notifications.user_id has no cascade: account deletion (B17) removes the rows explicitly.
-- The type list is widened by B16 (REMINDER) with a new constraint.
--
-- Migration safety: new tables only, no lock on existing data; forward-only.
CREATE TABLE group_events (
    id              uuid        PRIMARY KEY,
    group_id        uuid        NOT NULL REFERENCES expense_groups (id) ON DELETE CASCADE,
    actor_member_id uuid        REFERENCES members (id) ON DELETE SET NULL,
    type            text        NOT NULL,
    payload         jsonb       NOT NULL,
    created_at      timestamptz NOT NULL,
    CONSTRAINT ck_group_events_type CHECK (type IN (
        'EXPENSE_ADDED', 'EXPENSE_EDITED', 'EXPENSE_DELETED',
        'SETTLEMENT_PENDING', 'SETTLEMENT_CONFIRMED', 'SETTLEMENT_DISPUTED', 'SETTLEMENT_CANCELLED',
        'INVITE_ACCEPTED', 'JOIN_REQUESTED', 'MEMBER_JOINED', 'MEMBER_LEFT', 'MEMBER_REACTIVATED',
        'MEMBER_UNLINKED', 'ROLE_CHANGED', 'OWNERSHIP_TRANSFERRED')),
    CONSTRAINT ck_group_events_payload CHECK (jsonb_typeof(payload) = 'object')
);

CREATE INDEX ix_group_events_feed ON group_events (group_id, created_at DESC, id DESC);
CREATE INDEX ix_group_events_created ON group_events (created_at);                       -- retention purge
CREATE INDEX ix_group_events_actor ON group_events (actor_member_id) WHERE actor_member_id IS NOT NULL;  -- FK SET NULL

CREATE TABLE notifications (
    id         uuid        PRIMARY KEY,
    user_id    uuid        NOT NULL REFERENCES users (id),
    event_id   uuid        NOT NULL REFERENCES group_events (id) ON DELETE CASCADE,
    created_at timestamptz NOT NULL,
    read_at    timestamptz,
    CONSTRAINT uq_notifications_event_user UNIQUE (event_id, user_id),
    CONSTRAINT ck_notifications_read CHECK (read_at IS NULL OR read_at >= created_at)
);

CREATE INDEX ix_notifications_user ON notifications (user_id, created_at DESC, id DESC);
CREATE INDEX ix_notifications_unread ON notifications (user_id) WHERE read_at IS NULL;
