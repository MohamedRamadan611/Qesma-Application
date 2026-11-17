---
description: "SA8 — Trip recap image for WhatsApp (totals, top payer, biggest expense, category split) and text balance summary"
---

Read AGENTS.md, mobile/AGENTS.md, docs/STANDALONE_SPEC.md (trip recap) and Decision Log entries, `mobile/packages/qesma_engine/`, `lib/local/insights/` (from SA7), `lib/features/balances/` and the group home, docs/design/DESIGN.md, `share_plus` usage already in the app. Prerequisite: SA7 merged. Skills (max 4): think-before-coding, test-driven-development, ui-ux-pro-max, ux-copy.

This is the app's free marketing: every shared image carries the app name.

Step 0 (plan, wait for approval): (1) engine function `insights/trip_recap.dart`: total spent, expense count, per-member paid totals, top payer (tie -> lower sortOrder), biggest expense (tie -> earlier date, then earlier creation), category totals and percentages in bps via LRM summing to exactly 10000 (LRM ties by the category enum order, A133; no expenses -> no recap), date range; (2) the image layout (portrait 1080x1350 or 1080x1920 — decide), RTL Arabic, brand header, footer with app name and a short Play link placeholder until SA13, readable at WhatsApp compression; (3) rendering: offscreen `RepaintBoundary` -> PNG bytes -> temp file -> `share_plus`; fonts embedded so Arabic renders the same on all phones; (4) the text summary share ("who pays whom" from `GET balances`, formatted with `core/money`); (5) privacy: confirm dialog before sharing names (A134); (6) entry points (group home menu and balances tab "all settled" state).

Implement: engine function + fixtures `fixtures/insights/trip-recap-*.json`, local repository method, recap preview screen with "Share image" and "Share as text", rendering service, ARB strings, guard updates.

Tests: engine fixtures (ties, single member, deleted expense, all-OTHER categories, percentages sum to 10000); golden of the recap image in ar and en; rendering service produces a non-empty PNG of the chosen size; text summary formatting (Western digits, `ج.م`); widget tests text scale 2.0 (the share image itself uses a fixed scale — state it).
Constraints: no UI arithmetic; no network; no new dependencies. Done when analyze and tests pass. Then Stop protocol; do NOT start SA9.
