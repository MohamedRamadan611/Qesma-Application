-- V10: email + password sign-in (ADR-007, Decision A59). Additive and forward-only.
-- Passwords live in their own table so Google users never carry a credential column; only a salted hash is stored.

ALTER TABLE users DROP CONSTRAINT ck_users_auth_provider;
ALTER TABLE users ADD CONSTRAINT ck_users_auth_provider CHECK (auth_provider IN ('GOOGLE', 'PASSWORD'));

-- A password account is identified by its normalized email, which is also its subject (so the existing
-- UNIQUE (auth_provider, auth_subject) decides concurrent registrations). Existing rows are all GOOGLE.
ALTER TABLE users ADD CONSTRAINT ck_users_password_has_email
    CHECK (auth_provider <> 'PASSWORD' OR (email IS NOT NULL AND auth_subject = lower(btrim(email))));

-- Null until the address was proven; Google accounts are treated as verified by the application.
ALTER TABLE users ADD COLUMN email_verified_at timestamptz;

CREATE TABLE user_passwords (
    user_id             uuid        PRIMARY KEY REFERENCES users (id),
    password_hash       text        NOT NULL,
    failed_attempts     integer     NOT NULL DEFAULT 0,
    locked_until        timestamptz,
    password_changed_at timestamptz NOT NULL DEFAULT now(),
    created_at          timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT ck_user_passwords_hash_not_blank CHECK (char_length(password_hash) > 0),
    CONSTRAINT ck_user_passwords_failed_attempts CHECK (failed_attempts >= 0)
);

-- One-time links (verify the address, reset the password). Only the SHA-256 of the opaque token is stored.
CREATE TABLE email_tokens (
    id         uuid        PRIMARY KEY,
    user_id    uuid        NOT NULL REFERENCES users (id),
    purpose    text        NOT NULL,
    token_hash bytea       NOT NULL,
    expires_at timestamptz NOT NULL,
    used_at    timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_email_tokens_token_hash UNIQUE (token_hash),
    CONSTRAINT ck_email_tokens_purpose CHECK (purpose IN ('VERIFY_EMAIL', 'RESET_PASSWORD')),
    CONSTRAINT ck_email_tokens_hash_length CHECK (octet_length(token_hash) = 32),
    CONSTRAINT ck_email_tokens_expiry CHECK (expires_at > created_at)
);

CREATE INDEX ix_email_tokens_user_id ON email_tokens (user_id);
