-- V9: a group's owner is a member of it (B9, Decision A53). members.user_id (FK to users since V4) links a member to
-- an account; from B9 the creator of a group is member #1 and linked. A user can be at most one member of a group.
--
-- Migration safety: one index on the small `members` table (a short lock while it is built); no data is changed and
-- there is no backfill: groups created before B9 simply have no linked member (local development data only).
CREATE UNIQUE INDEX ux_members_group_user ON members (group_id, user_id) WHERE user_id IS NOT NULL;
