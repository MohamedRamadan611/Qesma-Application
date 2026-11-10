-- V11: password accounts are identified by a USERNAME (ADR-008, Decision A64). The email stays optional and unused
-- for now (recovery by email is on hold), so a password account no longer needs one. Additive, forward-only.
ALTER TABLE users DROP CONSTRAINT ck_users_password_has_email;
-- The subject of a password account is its normalized (trimmed, lower-case) username, or, for the few accounts made
-- with an email address before this change, that address in the same normal form.
ALTER TABLE users ADD CONSTRAINT ck_users_password_subject
    CHECK (auth_provider <> 'PASSWORD' OR auth_subject = lower(btrim(auth_subject)));
