---
description: "SA9 — WhatsApp reminder message with soft / firm / funny Egyptian tones (plain templates, no AI)"
---

Read AGENTS.md, mobile/AGENTS.md, `.claude/mobile/SCREEN_MAP.md`, docs/STANDALONE_SPEC.md (reminder tones) and Decision Log entries, `lib/features/balances/` (transfer card, suggested transfers), `lib/features/profile/` (own payment handles from FL14), `url_launcher` usage in the app, and open `P13-04-Remind.png` for visual reference only. Prerequisite: SA8 merged. Skills (max 4): ux-copy, ui-ux-pro-max, accessibility-review, think-before-coding.

Chasing money is the awkward part. Make it kind, quick and culturally right.

Step 0 (plan, wait for approval): (1) the three tones per language as ARB templates with placeholders `{name}`, `{amount}`, `{group}`, optional `{handle}` line — write the Egyptian-Arabic copy now and have the owner approve it (the funny tone must never shame or insult); (2) the flow: "Remind" on a suggested transfer whose receiver is the "you" member (and, decide, also for other pairs as "send to the debtor on behalf of X") -> sheet with tone chips, editable text field prefilled, optional "add my InstaPay" toggle (only if the profile has a handle) -> "Open WhatsApp" -> `https://wa.me/?text=<urlencoded>` via `url_launcher` (no phone number); fallback to the system share sheet when WhatsApp is not installed; (3) the last-used tone remembered locally; (4) no auto-send, no rate limit needed in local mode (server-mode Remind from FL14 stays unchanged).

Implement: reminder sheet, template formatter (amount via `core/money`), launcher service with fallback, ARB strings, scope guard words for local mode.

Tests: formatter tests per tone/language (placeholders filled, Western digits, handle line on/off, URL encoding of Arabic text and newlines); launcher fallback when WhatsApp is missing (fake launcher); widget tests ar/en/text scale 2.0; golden of the sheet. Manual device check (record in the PR): the wa.me link opens WhatsApp's chat picker with the text.
Constraints: no money arithmetic; no phone numbers stored; no new dependencies. Done when analyze and tests pass. Then Stop protocol; do NOT start SA10.
