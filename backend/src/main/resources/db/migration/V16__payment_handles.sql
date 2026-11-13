-- V16: payment handles (Phase 2, B14, Decisions A90-A94). (V15 was taken by B13.)
--
-- A user may store one InstaPay address and one mobile-wallet number. They are personal data (PDPL 151/2020):
-- plain text, shown only to co-members through the balances transfers (A91), deleted with the account (B17).
-- The shape of every stored value is a CHECK, so a malformed or non-normalised row cannot exist even if the service
-- is bypassed. Wallet: 11 digits 01[0125]XXXXXXXX. InstaPay: lower-case local@bank, 3..60 ASCII characters.
--
-- Migration safety: new table only, no lock on existing data; forward-only.
CREATE TABLE payment_handles (
    id         uuid        PRIMARY KEY,
    user_id    uuid        NOT NULL REFERENCES users (id),
    type       text        NOT NULL,
    value      text        NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_payment_handles_user_type UNIQUE (user_id, type),
    CONSTRAINT ck_payment_handles_type CHECK (type IN ('INSTAPAY', 'WALLET')),
    CONSTRAINT ck_payment_handles_wallet CHECK (type <> 'WALLET' OR value ~ '^01[0125][0-9]{8}$'),
    CONSTRAINT ck_payment_handles_instapay CHECK (type <> 'INSTAPAY'
        OR (char_length(value) BETWEEN 3 AND 60 AND value ~ '^[a-z0-9._-]+@[a-z0-9.-]+$'))
);
