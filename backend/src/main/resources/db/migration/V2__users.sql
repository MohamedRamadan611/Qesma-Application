-- V2: users (spec section 6). Sign-in is Google only in Phase 1 (Decision A4).
-- New table only: no locks on existing data, nothing to roll back.
CREATE TABLE users (
    id            uuid        PRIMARY KEY,
    auth_provider text        NOT NULL,
    auth_subject  text        NOT NULL,
    email         text,
    display_name  text        NOT NULL,
    created_at    timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_users_provider_subject UNIQUE (auth_provider, auth_subject),
    CONSTRAINT ck_users_auth_provider CHECK (auth_provider IN ('GOOGLE')),
    CONSTRAINT ck_users_auth_subject_not_blank CHECK (char_length(btrim(auth_subject)) > 0),
    CONSTRAINT ck_users_display_name_length CHECK (char_length(btrim(display_name)) BETWEEN 1 AND 60)
);
