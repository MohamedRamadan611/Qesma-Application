---
description: "FL8 — Profile hub, edit profile, language, sign out, global offline/error states"
---

Read AGENTS.md, mobile/AGENTS.md, `.claude/mobile/SCREEN_MAP.md`, docs/PROJECT_SPEC.md sections 3.1 (Account), 9 (item 12), 11 (privacy) and open the screens `P10-01-Profile-Hub.png`, `P10-02-Edit-Profile.png`, `P10-03-Account-Settings.png`, `P11-01-No-Internet.png`, `P11-02-Generic-Error.png`, `P11-03-Loading-pattern.png`, `P11-05-Coach-Marks.png`. Prerequisite: FL7 merged. Skills (max 4): think-before-coding, ui-ux-pro-max, ux-copy, accessibility-review.

Step 0 (plan, wait for approval): which rows of the three profile screens survive (SCREEN_MAP section 3: name, email, group count, language, terms/privacy, version, sign out; **omit** role badge, notification settings, default-currency row, phone, avatar, payment handles, export, active devices, sign out everywhere, delete account); how the app version is obtained without a new dependency if possible (build-time `--dart-define`) or the ADR addendum if a package is needed; how connectivity is detected and which screens show the shared offline state; whether coach marks (P11-05) are in this milestone (optional, last, only if everything else is done).

Implement:
1. **Profile hub**: name, email (read only, "connected Google account"), number of groups (from the groups list total), net per currency only when derivable from `yourNetMinor` (else hidden), language row (Arabic / English, applies immediately, persisted, flips RTL/LTR), terms and privacy rows (static pages or placeholder links recorded as an open item: a privacy policy is required before public release), app version, **sign out** with confirm dialog.
2. **Edit profile**: display name only (required, max 60, trimmed) via `PATCH /me`, unsaved-changes dialog, validation message from the design, success updates the cached user everywhere (header, "you" label source if shown).
3. **Account settings**: only the connected Google account and sign out; record in the open-items list that **account deletion** (spec 11, Play requirement) has no Phase 1 backend support and must be solved before a public release.
4. **Global states**: no-internet screen and banner (P11-01) for every feature, generic error with retry and `requestId` (P11-02), skeleton pattern (P11-03) used by all list screens; session-expired dialog from FL2 verified here end to end.
5. Optional: 3-step coach marks shown once (stored flag).
6. Bottom navigation: only what exists in Phase 1 (Groups and Account). Omit Activity and Expenses tabs.

Tests: language switch persists and mirrors layout; edit profile validation and PATCH body; sign-out wipes storage and returns to welcome; offline state appears on every feature's repository error (parametrised test over features); version row; omitted-element search test; widget tests ar/en/2.0 text scale; goldens for the hub.
Constraints: SCREEN_MAP rules; no analytics SDKs, no new services. Done when analyze and tests pass. Then Stop protocol; do NOT start FL9 here.
