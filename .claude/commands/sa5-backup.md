---
description: "SA5 — Backup: versioned JSON export/import, Android auto-backup, backup reminder"
---

Read AGENTS.md, mobile/AGENTS.md, docs/STANDALONE_SPEC.md (backup section) and its Decision Log entries, ADR-012 (`file_picker`, `share_plus`, `path_provider`), `lib/local/db/`, `lib/local/service/`, the profile hub from SA4, `android/app/src/main/AndroidManifest.xml`. Prerequisite: SA4 merged. Skills (max 4): think-before-coding, data-modeling-discipline, ux-copy, testing-with-discernment.

Without a server, the phone is the only copy of the user's data: losing it loses user trust. This prompt protects against that.

Step 0 (plan, wait for approval): (1) export format `qesma-backup-v1.json`: `formatVersion`, `schemaVersion`, `exportedAt`, app version, and every table needed to rebuild the ledger (groups, members, expenses with children, revisions, settlements, profile, own handles) — ids preserved; no idempotency keys; (2) import policy: replace-all after an explicit confirmation (recommended for v1; merge is out of scope), validated **before** anything is written: JSON schema/version check, referential integrity, limits, and a **recompute check** (balances recomputed by the engine must be internally consistent: nets sum to 0, every expense's shares sum to its total); one transaction; on any failure nothing changes; (3) forward compatibility (newer `formatVersion` -> clear refusal message); (4) Android auto-backup: include the database file, exclude caches; size limits; (5) reminder: after N new expenses or N days since the last export (decide), a dismissible banner; (6) privacy: the file contains names and amounts — say so in the share sheet text and the privacy policy draft.

Implement: `lib/local/backup/` (exporter, importer, validator), profile hub entries "Export backup" / "Restore from backup" with confirm dialogs, share via `share_plus`, pick via `file_picker`, the reminder banner, manifest backup rules, ARB strings, scope guard words for export/import in local mode.

Tests: export -> import round trip gives identical balances, expense details and revision history; corrupted file, wrong version, missing member reference, amount over the cap, shares not summing to total -> rejected with no change; import into a non-empty database replaces everything only after confirm; large backup (50 groups, 5,000 expenses) imports within a stated time on the test machine; reminder banner rules; widget tests ar/en.
Constraints: integer money only; no network; never log file contents. Done when analyze and tests pass. Then Stop protocol; do NOT start BSA1.
