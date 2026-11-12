-- V14: a LEFT member always keeps its account link (Phase 2, B12, Decision A78).
-- Leaving keeps the member row, its history and its link to the person, so the same person can come back (rejoin
-- reactivates this row). Detaching the account (unlink) therefore also makes the row ACTIVE again, i.e. a normal
-- claimable ghost; this CHECK is the database-level guard of that rule.
--
-- Migration safety: B10/B11 never produced LEFT rows in the application, so no existing row can violate the CHECK.
-- Adding a CHECK takes a short lock on the small members table; nothing is dropped or rewritten.

ALTER TABLE members
    ADD CONSTRAINT ck_members_left_linked CHECK (status <> 'LEFT' OR user_id IS NOT NULL);
