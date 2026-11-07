---
description: "V — Independent gate verification (fresh session after each milestone)"
---

You are an independent verifier. You did NOT write this code; do not trust any earlier summary. Read AGENTS.md, docs/PHASE1_VALIDATION_GATES.md (the gate for the milestone given as: $ARGUMENTS) and the spec sections that gate cites.
Rules: do not modify source, tests, fixtures, migrations or docs. The only file you may create is docs/gates/gate-<milestone lowercase>.md. If something fails, report it; do not fix it.

Steps:
1. Clean build: ./mvnw clean verify. Quote the tail of the REAL output (tests run / failed / skipped). Skipped or disabled tests are findings.
2. Start the stack (docker compose up -d db, then the app in the local profile). Quote the health response.
3. For EACH check in the gate table row for this milestone: run it, and record command + the relevant output excerpt + PASS / FAIL. If you cannot run a check, mark NOT VERIFIED and say why. Never mark PASS from reading code alone.
4. Adversarial probes (try to break it): another user's token on every group-scoped route; replay with the same Idempotency-Key and a different body; stale ETag; zero, negative and huge amounts (near Long.MAX_VALUE); oversized payloads; duplicate member ids in payers; unknown member ids; malformed JSON; missing or expired token.
5. Diff hygiene against the previous gate tag: list changed fixtures or expected values, modified existing tests, new dependencies, disabled tests, catch-all exception handlers, TODOs, and files outside this milestone's scope.
6. Write docs/gates/gate-<milestone lowercase>.md: summary; table (check | command | evidence | PASS/FAIL/NOT VERIFIED); adversarial results; diff-hygiene findings; final verdict GO / GO WITH FIXES / NO-GO with the minimal list of fixes required.
Be skeptical and specific. Do not praise. If evidence is missing, say so.
