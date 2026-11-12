-- V13: invitations and join requests (Phase 2, B11, Decisions A70-A76).
-- New tables only: no locks on existing data.
--
-- One secret per invite: the code (8 characters from a 32-symbol alphabet without look-alikes, stored normalised).
-- The same code is typed by hand and used inside the link. Guessing is limited by expiry, revoke, a per-IP and a
-- per-user limit in the application; the constraints below keep the stored shape honest.

CREATE TABLE group_invites (
    id                   uuid        PRIMARY KEY,
    group_id             uuid        NOT NULL REFERENCES expense_groups (id),
    code                 text        NOT NULL,
    created_by_member_id uuid        NOT NULL REFERENCES members (id),
    created_at           timestamptz NOT NULL DEFAULT now(),
    expires_at           timestamptz NOT NULL,
    max_uses             int,
    use_count            int         NOT NULL DEFAULT 0,
    requires_approval    boolean     NOT NULL,
    revoked_at           timestamptz,
    CONSTRAINT uq_group_invites_code UNIQUE (code),
    CONSTRAINT ck_group_invites_code CHECK (code ~ '^[A-HJ-NP-Z2-9]{8}$'),
    CONSTRAINT ck_group_invites_expiry CHECK (expires_at > created_at),
    CONSTRAINT ck_group_invites_max_uses CHECK (max_uses IS NULL OR max_uses BETWEEN 1 AND 1000),
    CONSTRAINT ck_group_invites_use_count CHECK (use_count >= 0 AND (max_uses IS NULL OR use_count <= max_uses))
);

CREATE INDEX ix_group_invites_group ON group_invites (group_id, created_at DESC, id DESC);
CREATE INDEX ix_group_invites_creator ON group_invites (created_by_member_id);

CREATE TABLE join_requests (
    id                   uuid        PRIMARY KEY,
    invite_id            uuid        NOT NULL REFERENCES group_invites (id),
    group_id             uuid        NOT NULL REFERENCES expense_groups (id),
    user_id              uuid        NOT NULL REFERENCES users (id),
    claim_member_id      uuid        REFERENCES members (id),
    new_member_name      text,
    status               text        NOT NULL DEFAULT 'PENDING',
    created_at           timestamptz NOT NULL DEFAULT now(),
    decided_at           timestamptz,
    decided_by_member_id uuid        REFERENCES members (id),
    CONSTRAINT ck_join_requests_status CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED')),
    CONSTRAINT ck_join_requests_target CHECK ((claim_member_id IS NULL) <> (new_member_name IS NULL)),
    CONSTRAINT ck_join_requests_name CHECK (new_member_name IS NULL OR char_length(btrim(new_member_name)) BETWEEN 1 AND 40),
    CONSTRAINT ck_join_requests_decided CHECK ((status = 'PENDING') = (decided_at IS NULL))
);

-- one open request per user per invite
CREATE UNIQUE INDEX ux_join_requests_pending ON join_requests (invite_id, user_id) WHERE status = 'PENDING';
CREATE INDEX ix_join_requests_group ON join_requests (group_id, status, created_at, id);
CREATE INDEX ix_join_requests_user ON join_requests (user_id);
CREATE INDEX ix_join_requests_claim ON join_requests (claim_member_id) WHERE claim_member_id IS NOT NULL;
CREATE INDEX ix_join_requests_decider ON join_requests (decided_by_member_id) WHERE decided_by_member_id IS NOT NULL;
