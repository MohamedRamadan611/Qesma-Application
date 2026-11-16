---
description: "SA14 (update 1) — Egyptian Arabic voice entry: speak 'title + amount', confirm the transcript, prefill the expense form"
---

Read AGENTS.md, mobile/AGENTS.md, docs/STANDALONE_SPEC.md (voice entry) and Decision Log entries, ADR-012 (`speech_to_text` version — verify it on pub.dev and record it if missing), `lib/core/money/money.dart`, `lib/features/expenses/` (form), and the `speech_to_text` package documentation (locales, `onDevice`, supported on-device languages, Android pause timeout, permissions). Prerequisite: SA13 released (1.0.0 on Play) and the owner decided to ship update 1. Skills (max 4): think-before-coding, test-driven-development, ux-copy, accessibility-review.

Step 0 (plan, wait for approval): (1) recognizer: locale ar-EG (fallback ar), `onDevice` when the device supports it, otherwise tell the user audio goes to Google's speech service (privacy policy update); microphone permission flow; (2) a pure **Egyptian number-words parser** (`core/money` or a new pure file): digits (Western and Arabic-Indic), words (واحد..عشرة، عشرين..تسعين، مية/ميت، ميتين، تلتمية..تسعمية، ألف/ألفين/آلاف، مليون), "و" joins, "ونص" / "وربع" (half/quarter pound -> piasters by integer rules), "جنيه"/"ج" suffixes, mixed text like "عشا ٣٥٠ جنيه" -> title "عشا", amount 35000; ambiguous input -> no amount, the user types it; (3) UX: mic button in the expense form, listening sheet with the live transcript, "Use" fills title + amount only (participants and payers are chosen as usual), never saves; (4) failure modes: no permission, no recognizer, language not available, silence timeout.

Implement: dependency (ADR-012), parser, voice sheet, form integration, ARB strings, privacy policy update, scope guard words.

Tests (first): parser table tests (at least 60 real phrasings collected with the owner, including mistakes and mixed digits), property test that parsed amounts are within 0..10^12 and never use `double`; widget tests ar/en/text scale 2.0 with a fake recognizer; permission-denied flow. Manual device check on two Android phones recorded in `docs/gates/`.
Constraints: integer money only; title + amount only; no AI service. Done when analyze and tests pass. Then Stop protocol.
