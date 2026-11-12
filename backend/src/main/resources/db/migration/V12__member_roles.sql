-- V12: roles and status for members (Phase 2, B10, Decisions A65-A69).
-- Authorization moves from expense_groups.owner_user_id to members: a caller reaches a group only through an ACTIVE
-- member linked to their account, and members.role = 'OWNER' is the single authority for ownership.
-- expense_groups.owner_user_id stays as the immutable creator and is no longer used for authorization.
--
-- Migration safety:
--   * guard first: if any group has no member linked to its creator (groups created before B9, Decision A55) their
--     owners would lose access, so the migration aborts with a clear message instead of orphaning data;
--   * ADD COLUMN with a constant DEFAULT is metadata-only on PostgreSQL 11+ (no table rewrite);
--   * the CHECKs and indexes are added on the small members table (a short lock);
--   * nothing is dropped; the old owner index on expense_groups is simply unused now.

DO $$
DECLARE
    orphaned bigint;
BEGIN
    SELECT count(*) INTO orphaned
    FROM expense_groups g
    WHERE NOT EXISTS (SELECT 1 FROM members m WHERE m.group_id = g.id AND m.user_id = g.owner_user_id);
    IF orphaned > 0 THEN
        RAISE EXCEPTION 'V12 aborted: % group(s) have no member linked to their owner (created before B9). '
            'Delete or re-seed that data first (Decision A55/A68).', orphaned;
    END IF;
END $$;

ALTER TABLE members
    ADD COLUMN role      text        NOT NULL DEFAULT 'MEMBER',
    ADD COLUMN status    text        NOT NULL DEFAULT 'ACTIVE',
    ADD COLUMN joined_at timestamptz,
    ADD COLUMN left_at   timestamptz;

UPDATE members m
SET role = 'OWNER'
FROM expense_groups g
WHERE m.group_id = g.id AND m.user_id = g.owner_user_id;

UPDATE members SET joined_at = created_at;

ALTER TABLE members
    ADD CONSTRAINT ck_members_role CHECK (role IN ('OWNER', 'ADMIN', 'MEMBER')),
    ADD CONSTRAINT ck_members_status CHECK (status IN ('ACTIVE', 'LEFT')),
    ADD CONSTRAINT ck_members_owner_linked_active CHECK (role <> 'OWNER' OR (user_id IS NOT NULL AND status = 'ACTIVE')),
    ADD CONSTRAINT ck_members_left_at CHECK ((status = 'LEFT') = (left_at IS NOT NULL));

-- at most one owner per group (at least one is guaranteed by group creation in one transaction, A53)
CREATE UNIQUE INDEX ux_members_group_owner ON members (group_id) WHERE role = 'OWNER';

-- "my groups" and the membership check start from the account
CREATE INDEX ix_members_user_active ON members (user_id, group_id) WHERE user_id IS NOT NULL AND status = 'ACTIVE';
