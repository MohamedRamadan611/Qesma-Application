-- V18: notification preferences and the Remind log (Phase 2, B16, Decisions A104-A112).
--
-- notification_prefs: one row per (user, scope). group_id NULL is the global switch (muted = true means "notifications
-- off"); a group_id row is a per-group mute. No row means the default (enabled, not muted). A plain UNIQUE (user_id,
-- group_id) would treat NULLs as distinct, so there are two partial unique indexes. group_id cascades (an empty group may
-- be hard-deleted); user_id has no cascade: account deletion (B17) removes the rows explicitly.
--
-- remind_log: one row per sent reminder. It is the single source of truth of the rate limit (one per group + debtor per
-- window, and a per-account daily cap), written in the same transaction as the REMINDER event. Rows older than the
-- window are useless and are purged by the activity purge job. No money is stored here (the amount is in the event).
--
-- group_events.type gains 'REMINDER' (the constraint is replaced: a CHECK cannot be extended in place).
--
-- Migration safety: new tables only; the constraint swap runs in one transaction on a small append-only table
-- (ADD CONSTRAINT validates existing rows: all already satisfy the wider list). Forward-only.
CREATE TABLE notification_prefs (
    id         uuid        PRIMARY KEY,
    user_id    uuid        NOT NULL REFERENCES users (id),
    group_id   uuid        REFERENCES expense_groups (id) ON DELETE CASCADE,
    muted      boolean     NOT NULL,
    updated_at timestamptz NOT NULL
);

CREATE UNIQUE INDEX ux_notification_prefs_global ON notification_prefs (user_id) WHERE group_id IS NULL;
CREATE UNIQUE INDEX ux_notification_prefs_group ON notification_prefs (user_id, group_id) WHERE group_id IS NOT NULL;
CREATE INDEX ix_notification_prefs_group ON notification_prefs (group_id) WHERE group_id IS NOT NULL;   -- FK cascade

CREATE TABLE remind_log (
    id              uuid        PRIMARY KEY,
    group_id        uuid        NOT NULL REFERENCES expense_groups (id) ON DELETE CASCADE,
    from_member_id  uuid        NOT NULL REFERENCES members (id) ON DELETE CASCADE,
    to_member_id    uuid        NOT NULL REFERENCES members (id) ON DELETE CASCADE,
    sent_by_user_id uuid        NOT NULL REFERENCES users (id),
    created_at      timestamptz NOT NULL,
    CONSTRAINT ck_remind_log_distinct CHECK (from_member_id <> to_member_id)
);

CREATE INDEX ix_remind_log_pair ON remind_log (group_id, from_member_id, created_at DESC);
CREATE INDEX ix_remind_log_sender ON remind_log (sent_by_user_id, created_at DESC);
CREATE INDEX ix_remind_log_created ON remind_log (created_at);                       -- retention purge
CREATE INDEX ix_remind_log_to_member ON remind_log (to_member_id);                    -- FK cascade

ALTER TABLE group_events DROP CONSTRAINT ck_group_events_type;
ALTER TABLE group_events ADD CONSTRAINT ck_group_events_type CHECK (type IN (
    'EXPENSE_ADDED', 'EXPENSE_EDITED', 'EXPENSE_DELETED',
    'SETTLEMENT_PENDING', 'SETTLEMENT_CONFIRMED', 'SETTLEMENT_DISPUTED', 'SETTLEMENT_CANCELLED',
    'INVITE_ACCEPTED', 'JOIN_REQUESTED', 'MEMBER_JOINED', 'MEMBER_LEFT', 'MEMBER_REACTIVATED',
    'MEMBER_UNLINKED', 'ROLE_CHANGED', 'OWNERSHIP_TRANSFERRED', 'REMINDER'));
