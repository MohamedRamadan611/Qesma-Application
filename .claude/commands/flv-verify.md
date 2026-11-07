---
description: "FLV — Independent verification of a Flutter milestone (fresh session, read-only)"
---

You are an independent verifier. You did NOT write this code; do not trust any earlier summary. Read AGENTS.md, mobile/AGENTS.md, `.claude/mobile/SCREEN_MAP.md`, docs/PHASE1_VALIDATION_GATES.md (CP3) and the prompt of the milestone given as $ARGUMENTS (`.claude/commands/fl<N>-*.md`).
Rules: do not modify source, tests, goldens, generated code, ARB files or docs. The only file you may create is `docs/gates/gate-fl<N>.md`. If something fails, report it; do not fix it. Commands that build, run, or start throwaway processes are allowed; edits to tracked files are not.

Steps:
1. **Clean build:** `cd mobile && flutter clean && flutter pub get && flutter analyze && flutter test`. Quote the REAL tail (tests run/failed/skipped). Skipped tests and `// ignore:` suppressions are findings.
2. **Contract:** `mobile/openapi.sha256` equals the hash of `docs/openapi.json`; regenerate the client into a temp folder and diff it against `mobile/packages/qesma_api` (must be identical).
3. **Run the app against the real backend** (docker compose `db`, backend with `local,fake-auth,seed` on a free port, emulator or device) and execute, for EACH item in the milestone prompt's Implement/Tests lists, the check with command and evidence (screenshot description or log excerpt): PASS / FAIL / NOT VERIFIED (say why). Never PASS from reading code alone.
4. **Adversarial probes:** kill the backend during a save and retry (exactly one expense after recovery); drop the response of a create (same key reused); two parallel 401s (one refresh); expired and revoked refresh token (session-expired dialog, no loop); stale `If-Match` (conflict dialog, input kept); 429 on sign-in; zero, negative, huge and Arabic-digit amounts; 100 items; empty and 500-expense lists; text scale 200% and RTL/LTR switch; rotate the device; background/foreground during save.
5. **Scope and money hygiene:** grep for omitted Phase 2 elements and strings; grep `lib/` for `double`, `num`, `/ 100`, `* 100`, `.round()`, `.toDouble()` outside `core/money`; list any calculation not coming from preview/balances.
6. **Diff hygiene** against the previous mobile gate tag (or the initial commit): changed goldens, changed generated code, new dependencies (each needs ADR-006), disabled tests, catch-all handlers, TODOs, files outside the milestone, secrets or tokens in code, logs or the release artifact.
7. Write `docs/gates/gate-fl<N>.md`: summary; table (check | command | evidence | PASS/FAIL/NOT VERIFIED); adversarial results; hygiene findings; verdict GO / GO WITH FIXES / NO-GO with the minimal list of fixes.
Be skeptical and specific. Do not praise. If evidence is missing, say so. Human steps (real Google account, real device, real receipts) are NOT VERIFIED unless you actually did them.
