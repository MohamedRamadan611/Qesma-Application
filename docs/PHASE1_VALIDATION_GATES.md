# Phase 1 Backend — Validation Gates, Checkpoints & Verification Prompts

Purpose: know, with evidence, that each milestone works and that nothing silently broke. A passing test suite written by the same agent that wrote the code is **necessary but not sufficient**. This document adds an independent verification layer.

---

## 1. The cycle for every milestone (B0–B8)

```
Bn  build (fresh session, plan first)
 ↓
YOU run:  ./mvnw clean verify          (never trust the agent's "all tests pass")
 ↓
R   review the diff                    (fresh session; code quality, spec compliance)
 ↓
F   fix findings                       (as many rounds as needed; stop at 3 and rethink)
 ↓
X   extend scripts/smoke.sh            (from B4 onward: a real running-app check)
 ↓
V   independent gate verification      (fresh session; read-only; writes docs/gates/gate-bn.md)
 ↓
YOU do the 5-minute human check from the gate table below
 ↓
git tag gate-bn   →   next milestone
```
If V returns **NO-GO**, fix with **F**, then run **V** again in a new session. If a milestone needs more than 3 fix rounds, stop: the prompt, the spec, or the design is probably unclear. Use **S** to resolve it instead of patching.

## 2. Validation layers

| Layer | What it proves | Where |
|---|---|---|
| L1 Unit + property tests | Money rules are correct for known and random inputs | B3 engine, `/fixtures` |
| L2 Integration tests (Testcontainers) | Real PostgreSQL, migrations, authz, idempotency, concurrency | Every milestone |
| L3 Smoke script against the running app | The built artifact works end to end, not just the test harness | `scripts/smoke.sh` (prompt **X**) |
| L4 Independent verifier (prompt **V**) | A skeptical second session reproduces every claim and tries to break it | After each milestone |
| L5 Your human check | Numbers match a hand calculation; real receipts match | Gate table below |
| CI | Nothing merges red | GitHub Actions + branch protection (even solo) |

## 3. Gates (what must be demonstrably true)

Evidence is saved in `docs/gates/gate-bn.md` by prompt V. "Human check" is yours, about 5 minutes.

| Gate | Automatic checks | Must be demonstrably true | Your 5-minute human check |
|---|---|---|---|
| **G0** (B0) | `./mvnw clean verify` green; `docker compose up -d db` healthy; CI green; secret scan clean | App starts; `/actuator/health` UP with DB; API docs disabled outside the local profile; Flyway ran V1; Spring Boot version is real and pinned | Open `pom.xml` and confirm the version exists on Maven Central; confirm no `.env` is committed |
| **G3** (engine) | Fixtures V1–V8 pass; jqwik property tests pass; `grep -RnE "\b(float\|double\|Float\|Double)\b" backend/src/main/java/**/engine` returns nothing; `grep -Rn "org.springframework\|jakarta.persistence"` in `engine` returns nothing | Each rule has Javadoc citing its spec section; tie-break, zero-weight, overflow and negative-adjustment cases are tested | Verify V4 and the V5 tax tie (A gets the extra piaster) by hand; compare one fixture to the spec digit by digit; `git log -- fixtures` shows no edits after the first commit |
| **G1** (auth) | Tests green | Two simultaneous first logins create **one** user (SQL count); reusing a rotated refresh token revokes the whole family; no token appears in logs (grep the run log); protected route without token returns 401 | Run the curl login → refresh → /me flow yourself using the fake-verifier profile |
| **G2** (groups/members) | Tests green; migrations apply to an **empty** database | User B gets 404 on every verb for user A's group and members; constraints exist (`\d members`, unique index on lower name); concurrent member creation yields distinct `sort_order` | With two tokens, try to read A's group by id as B |
| **G4** (expenses core) | Tests green; smoke script green | V1, V3, V4 through the API; same `Idempotency-Key` twice → one row; 20 parallel same-key requests → one row (SQL count); list endpoint query count is bounded | Create three expenses with the smoke script and compare the balances with your own arithmetic |
| **G5** (itemized + preview) | Tests green; smoke green | V5–V8 through the API; preview returns exactly what create stores; preview persists nothing (row-count check) | **Enter 3 real restaurant receipts** (from Phase 0) and compare per-person totals with your hand calculation. This settles Decision A1 (tax base) |
| **G6** (edit/delete/revisions) | Tests green; smoke green | Stale `If-Match` → 409 and nothing changes; two parallel PUTs → exactly one 200 and one 409; create+update+delete → 3 revisions; deleted expense absent from lists and balances | Edit an expense via curl and read its revisions JSON |
| **G7** (balances/settlements) | Tests green; smoke green | V1, V2 through the API; randomized scenario keeps `sum(net)=0` and transfers zero all nets; EXPLAIN notes exist; large dataset (15 members, 500 expenses) responds within the stated bound | **Dogfood:** record one real past outing through the API and check the result against what the group actually agreed |
| **G8** (hardening/handoff) | Full acceptance list (spec section 10) PASS; table-driven IDOR test over **every** group-scoped route; `docs/openapi.json` valid and matches spec 8.2; CI green | Restore drill executed (restore a backup into a fresh DB and compare row counts); staging deploy reachable over HTTPS; smoke script green against staging | Do the restore yourself once; call staging from your phone's browser |

## 4. Three checkpoints (decide whether to continue)

| Checkpoint | After | Question | If the answer is no |
|---|---|---|---|
| **CP1 Foundation** | B0, B3, B1, B2 | Is the engine trustworthy, and are auth and ownership isolation solid? | Do not build expenses on a shaky base; fix and re-verify |
| **CP2 Ledger** | B4–B6 | Can every expense type be recorded, edited and deleted correctly, and do 3 real receipts match? | Use **S** to resolve rule disputes before B7 |
| **CP3 Backend complete** | B7, B8 | Does the acceptance list pass on staging, and can Flutter generate a client from `docs/openapi.json`? | Fix before starting mobile work |

## 5. Red flags (something is wrong)

- The agent says "all tests pass" and you can't reproduce it.
- Expected values in `/fixtures` changed, or assertions were weakened, in the same diff as the code they test. Treat that as a rule change, not a fix.
- Any `@Disabled`, `assumeTrue`, skipped tests, `catch (Exception)` that swallows, or new TODOs.
- A Flyway migration that was already committed was edited (checksum errors). Add a new migration instead.
- New dependencies or infrastructure nobody approved; diffs far outside the milestone.
- Balances off by 1 piaster, or a different tie-break than the spec.
- More queries than expected on a list endpoint (N+1).
- The summary says "done" but lists unresolved assumptions.

## 6. Add to AGENTS.md (invariants 12–13)

```markdown
12. Never change expected values in /fixtures, weaken assertions, add @Disabled/assumeTrue, or delete tests to make a test pass. If a test seems wrong, STOP and ask; treat it as a possible spec change.
13. Never edit a Flyway migration that has been committed. Add a new forward migration.
```
(The updated setup package already includes these.)

## 7. Verification prompts

### V — Independent gate verification (fresh session after each milestone)
```text
You are an independent verifier. You did NOT write this code; do not trust any earlier summary. Read AGENTS.md, docs/PHASE1_VALIDATION_GATES.md (the gate for [B#]) and the spec sections that gate cites.
Rules: do not modify source, tests, fixtures, migrations or docs. The only file you may create is docs/gates/gate-[b#].md. If something fails, report it; do not fix it.

Steps:
1. Clean build: ./mvnw clean verify. Quote the tail of the REAL output (tests run / failed / skipped). Skipped or disabled tests are findings.
2. Start the stack (docker compose up -d db, then the app in the local profile). Quote the health response.
3. For EACH check in the gate table row for this milestone: run it, and record command + the relevant output excerpt + PASS / FAIL. If you cannot run a check, mark NOT VERIFIED and say why. Never mark PASS from reading code alone.
4. Adversarial probes (try to break it): another user's token on every group-scoped route; replay with the same Idempotency-Key and a different body; stale ETag; zero, negative and huge amounts (near Long.MAX_VALUE); oversized payloads; duplicate member ids in payers; unknown member ids; malformed JSON; missing or expired token.
5. Diff hygiene against the previous gate tag: list changed fixtures or expected values, modified existing tests, new dependencies, disabled tests, catch-all exception handlers, TODOs, and files outside this milestone's scope.
6. Write docs/gates/gate-[b#].md: summary; table (check | command | evidence | PASS/FAIL/NOT VERIFIED); adversarial results; diff-hygiene findings; final verdict GO / GO WITH FIXES / NO-GO with the minimal list of fixes required.
Be skeptical and specific. Do not praise. If evidence is missing, say so.
```

### T — Traceability and test-gap analysis (run after B5, B7 and B8)
```text
Read AGENTS.md and docs/PROJECT_SPEC.md sections 7, 8.2, 8.5, 10. Do NOT change code. Build docs/gates/traceability.md: a matrix with one row per numbered spec rule (7.1–7.10), per endpoint in 8.2, per error code in 8.5, and per invariant in AGENTS.md. Columns: rule | where it is implemented (file:line) | tests that exercise it (file:method) | strength (strong = asserts exact values/behaviour; weak = only checks status or non-null; none).
Then list: rules with no test, rules with only weak tests, error codes never produced by any test, endpoints without an IDOR test, and tests that would still pass if the rule were deleted (explain why). Propose, but do not write, the missing tests in priority order.
```

### X — Smoke script (create at B4, extend at B5, B7, B8)
```text
Read AGENTS.md and backend/README.md. Create or extend scripts/smoke.sh (bash + curl + jq only, no new dependencies). It runs against BASE_URL (default http://localhost:8080) using the fake-verifier login documented in backend/README.md, with two different users.
Cover, in order, for the features that exist so far: create group; add 5 members (Mohamed, Asem, Mohsen, Youssef, Kareem); equal expense; multi-payer expense; (after B5) itemized expense for each service/tax combination plus preview parity; (after B6) edit with ETag, stale ETag conflict, delete, revisions; (after B7) balances and transfers equal the expected numbers from spec section 10, settlement, balances after settlement; user B gets 404 on user A's group; idempotent replay returns the same response without creating a duplicate.
Every step asserts exact values (amounts in minor units), prints one PASS/FAIL line, and the script exits non-zero on the first failure. Each run uses fresh data so it can be repeated. Document how to run it in backend/README.md. Do not change application code.
```

### M — Mutation-test the engine (optional, one-time at G3)
```text
Read AGENTS.md and docs/adr. Plan first and wait for my approval, because this adds a build plugin (record an ADR). Add PIT mutation testing (Maven plugin) scoped ONLY to the engine package. Run it and report the mutation score and each surviving mutant (file:line, mutation, why the tests missed it). Add or strengthen tests to kill the meaningful survivors. Do not change production logic; if a survivor reveals a real bug or an ambiguous rule, stop and report it.
```

## 8. Gate report template (`docs/gates/gate-bn.md`)

```markdown
# Gate Bn — <milestone> — <date>
Verifier session: independent (fresh context)  ·  Previous tag: gate-b(n-1)  ·  Verdict: GO / GO WITH FIXES / NO-GO

## Evidence
| Check | Command | Output excerpt | Result |
|---|---|---|---|

## Adversarial probes
| Probe | Expected | Actual | Result |
|---|---|---|---|

## Diff hygiene
- Changed fixtures / expected values: …
- Modified existing tests: …
- New dependencies: …
- Disabled/skipped tests, TODOs, swallowed exceptions: …
- Out-of-scope files: …

## Required fixes (minimal)
1. …

## Human check (done by me): ✔/✘ + notes
```

## 9. CI as an automatic gate
Enable branch protection on `main` even as a solo developer: require the CI job (`./mvnw verify`) to pass before merging. Ask B8 to add a CI job that starts Docker Compose and runs `scripts/smoke.sh`. Tag each passed gate (`gate-b0` … `gate-b8`) so V can diff against the previous known-good state and you can roll back to it.
