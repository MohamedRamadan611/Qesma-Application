---
description: "SA7 — My share: what I consumed per month and category across all groups, versus what I paid up front"
---

Read AGENTS.md, mobile/AGENTS.md, docs/STANDALONE_SPEC.md (My share) and Decision Log entries, `mobile/packages/qesma_engine/`, `fixtures/README.md`, `lib/local/service/`, `lib/features/profile/` and the main shell (where a new entry fits), docs/design/DESIGN.md. Prerequisite: SA6 merged. Skills (max 4): think-before-coding, test-driven-development, ui-ux-pro-max, ux-copy.

Step 0 (plan, wait for approval): (1) pure function in `qesma_engine` (`insights/my_share.dart`): input = for each non-deleted expense in every group: date, category, the "you" member's owed amount, the "you" payer amount; output = per month (YYYY-MM, Africa/Cairo calendar date of the expense — the expense date is already a local date, confirm no timezone shift) x category: consumedMinor and paidUpFrontMinor, plus month totals; deterministic ordering; (2) how the local backend exposes it — recommended: a local-only repository method (`lib/local/insights/`) calling the engine over DAO data, **not** a fake HTTP endpoint (it is not in the server contract; document it as a server-phase endpoint to add later); (3) the screen: month selector, total consumed vs paid up front, category breakdown (bars with LRM-based percentages from the engine, never computed in the widget), drill-down to the expenses of a category; empty state; (4) entry point (profile hub or main shell tab — decide with the design system).

Implement: engine function + fixtures `fixtures/insights/my-share-*.json` (several groups, deleted expense, edited expense, member not "you", month boundary, zero months), local repository, Riverpod controller, screen, ARB strings, guard updates (the widget layer still does no arithmetic).

Tests: engine fixtures and property test (sum over categories = month total; consumed equals the sum of the "you" owed amounts); repository test over an in-memory DB; widget tests ar/en/text scale 2.0; golden; guard tests.
Constraints: integer money only; percentages as bps from the engine; no UI arithmetic. Done when analyze and tests pass. Then Stop protocol; do NOT start SA8.
