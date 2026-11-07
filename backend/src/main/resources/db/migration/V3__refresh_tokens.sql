-- V3: refresh tokens. Only the SHA-256 hash of the opaque token is stored.
-- A "family" is one login session; rotated tokens chain via replaced_by_id.
-- Reuse of a rotated token revokes the whole family (set revoked_at on every row of family_id).
-- New table only: no locks on existing data.
CREATE TABLE refresh_tokens (
    id             uuid        PRIMARY KEY,
    user_id        uuid        NOT NULL REFERENCES users (id),
    family_id      uuid        NOT NULL,
    token_hash     bytea       NOT NULL,
    expires_at     timestamptz NOT NULL,
    revoked_at     timestamptz,
    replaced_by_id uuid        REFERENCES refresh_tokens (id),
    created_at     timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_refresh_tokens_token_hash UNIQUE (token_hash),
    CONSTRAINT ck_refresh_tokens_hash_length CHECK (octet_length(token_hash) = 32),
    CONSTRAINT ck_refresh_tokens_expiry CHECK (expires_at > created_at),
    CONSTRAINT ck_refresh_tokens_not_self_replaced CHECK (replaced_by_id IS NULL OR replaced_by_id <> id),
    CONSTRAINT ck_refresh_tokens_replaced_implies_revoked CHECK (replaced_by_id IS NULL OR revoked_at IS NOT NULL)
);

CREATE INDEX ix_refresh_tokens_user_id ON refresh_tokens (user_id);
CREATE INDEX ix_refresh_tokens_family_id ON refresh_tokens (family_id);
