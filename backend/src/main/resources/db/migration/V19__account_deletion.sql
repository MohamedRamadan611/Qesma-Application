-- V19: account deletion (B17, Phase 2). Additive and forward-only: one nullable column and one CHECK, no table rewrite.
-- A deleted account keeps its users row (ledger tables reference it) but is anonymised: no email, a fixed display name
-- and a random tombstone as the sign-in subject, so the original address / username / Google subject is free again.
-- The tombstone contains ':' which neither a username nor a Google subject can (usernames: A64), so no sign-in can match it.
ALTER TABLE users ADD COLUMN deleted_at timestamptz;

ALTER TABLE users ADD CONSTRAINT ck_users_deleted_anonymised CHECK (
    (deleted_at IS NULL AND auth_subject NOT LIKE 'deleted:%')
    OR (deleted_at IS NOT NULL AND auth_subject LIKE 'deleted:%' AND email IS NULL AND email_verified_at IS NULL
        AND display_name = 'Deleted user'));
