# CP2 review — B4 (expenses core), B5 (itemized + preview), B6 (edit, delete, revisions)

**Date:** 2026-11-07 · **Mode:** read-only review of the working tree (B4–B6 are **uncommitted**; no `gate-*` tags). Production code, config, migrations and existing tests were not changed. One test file was added: `backend/src/test/java/app/qesma/Cp2LedgerInvariantIT.java`.
**Reviewer:** the same session that wrote the code. This is a **self-review**, not the independent `V` gate. It does not satisfy any gate.
**Build evidence:** `./mvnw clean verify` (JDK 21.0.12.1, Docker, real PostgreSQL 16) → **193 unit + 122 integration tests, 0 failures, 0 skipped, BUILD SUCCESS** (includes the 6 new CP2 tests).

---

## 1. Decision summary

**Overall: GO WITH FIXES.** The ledger is sound under the checks run: every expense type records, edits and deletes correctly, a seeded random sequence keeps `sum(owed) == sum(payers) == total` and `sum(net) == 0`, and idempotency, concurrency and ownership hold when exercised together. One real defect was found (CP2-001) and must be fixed before B7, because balances sum the same totals. The CP2 gate itself is **not passed**: the real-receipt check is **NOT VERIFIED (HUMAN)** and the independent `V` verification has not been run.

**Top actions**

| Order | Finding | Action |
|:--|:--|:--|
| 1 | CP2-001 | Cap money amounts (validator + CHECK in a new migration) so totals can never overflow `long`. |
| 2 | CP2-002 | Commit B4–B6, tag, run `V` in a fresh session; fix SEC-001/COR-001 (still open from CP1). |
| 3 | HUMAN | Provide the 3 real receipts (see section 3). |

---

## 2. CP2 checks — status

| CP2 check | Status | Evidence |
|:--|:--|:--|
| Re-run every B4–B6 check | **PASS** (self-review) | Full build above. Red-flag scan clean: no `@Disabled`, `assumeTrue`, TODO/FIXME; no swallowing `catch (Exception)`; no float/double/BigDecimal/`Math.round` in `src/main`; fixtures and committed migrations V1–V4 byte-identical to `HEAD`. |
| Idempotency and concurrency together with ownership | **PASS** | `Cp2LedgerInvariantIT`: (a) stranger racing the owner with the same key → owner 201 ×6, stranger 404 ×6, no key row stored for the stranger, owner replay still served; (b) 10 parallel same-key creates + 40 stranger probes (PUT/DELETE/GET/revisions) → one expense for the key, every probe 404, version still 1; (c) 6 edits + 2 deletes + 8 stranger writes on one version → exactly one owner write wins, strangers all 404, revisions exactly `[1, 2]`; (d) create → edit → delete → replay of the original key returns the stored 201 (`Idempotency-Replayed: true`, version 1) and creates nothing. Existing separate tests: `ExpenseIdempotencyIT`, `ExpenseEditDeleteIT`, `ExpensesIT`. |
| Money invariant across create, edit, delete | **PASS** (for what exists) | Seeded run (seed `20261107`, 200 steps): 83 creates (EQUAL/EXACT/ITEMIZED), 65 edits (including split-type changes), 21 deletes, 62 live. After every step the API output was fed to the engine's `BalanceCalculator`: `sum(net) == 0`, per expense `sum(payers) == sum(owed) == total`, itemized breakdowns explain `owed`, group `totalSpentMinor` equals the live total. At the end: revisions per expense equal its version, contiguous, CREATE first, DELETE last for deleted ones, and the same sums hold directly in SQL. Limits: settlements and the balances endpoint do not exist yet (B7); the random bills never triggered the engine's negative-share rejection (covered by unit tests only). |
| **HUMAN: 3 real receipts match** | **NOT VERIFIED** | Not provided. See section 3. |

## 3. What is needed for the receipts check (HUMAN)

Three real receipts, each as: group members in order, items with who shared each, service %, tax % (and whether tax applies on the subtotal or on subtotal + service), any rounding/tip line, who paid, and the **printed total and each person's expected share**. Run each through `POST …/expenses/preview`; the check passes only if `totalMinor` equals the printed total and each `owedMinor` matches. Until then this stays NOT VERIFIED; if a receipt disagrees, resolve the rule with `/s-spec-change` before B7.

---

## 4. Findings (severity ranked)

| ID | Severity | Where | Finding | Evidence / impact | Fix |
|:--|:--|:--|:--|:--|:--|
| CP2-001 | **Major** (fixed in B7: amount cap 10^12 in validators + V8 CHECKs; regression test `BalancesSettlementsIT.manyCapSizedExpensesNoLongerBreakTheGroupViewsOrBalances`) | `ExpenseValidator.java:83-89` (no upper bound), `ExpenseRepository.java:63`, `GroupService.java:83`; spec 3.1, 7.1 | Money amounts have no upper bound, so the sum of group totals can overflow `long`. | Probe: two valid EQUAL expenses of 5 000 000 000 000 000 000 piasters each → both `201`; then `GET /groups/{id}` and `GET /groups` return **500** permanently, while the expense list still works. B7 balances sum the same values (engine `Exact.add` would reject; the SQL sum would not). Input is hostile or absurd, but a 500 that bricks a group is not an acceptable failure. | Cap `totalMinor`, item, payer, share and settlement amounts (e.g. ≤ 10¹²); add a matching CHECK in a new migration; add a test at the cap. |
| CP2-002 | **Major** (process) | repo state | B4–B6 (and the CP1 base) are uncommitted: no `gate-*` tags, no `V` reports, CI workflow never run. A clean build "from the last gate tag" is impossible. SEC-001 (default profile `local` ships a known dev secret) and COR-001 from CP1 are still open. | `git status`: 63 changed/untracked paths. | Commit in small steps, tag, run `V` for B4/B5/B6 in a fresh session, apply SEC-001/COR-001. |
| CP2-003 | Minor | `IdempotencyService.java:59-79`, `ExpenseController.java` (create) | A replay serves the response as stored at creation, including its `ETag "1"`, even after later edits or a delete (documented A26). A client that follows a replayed ETag will get 409 on its next PUT. | Test (d) above. | Keep; state it in the OpenAPI description of create; clients re-GET after a replayed 201. |
| CP2-004 | Minor | `ExpenseService.java:210` (`revisions`), V7 | No cap on the number of edits and `GET /revisions` returns every snapshot unpaged (each up to tens of KB); each create also stores the same JSON again in `idempotency_keys`. | Hypothesis (not measured): hundreds of edits → multi-MB response and table growth. | Page the endpoint (reuse `PageResponse`) before B8; consider limiting edits per expense. |
| CP2-005 | Minor | `SecurityConfig.java:49-52` | No per-user rate limit on create, preview, PUT, DELETE (limiter covers `/auth/**` only); only the 64 KB body cap. A max-size PUT writes ~1.6k child rows while holding the group lock. | Self-inflicted only (owner-only product, lock is per group). Already tracked as SEC-002 / A36. | B8: per-user limit on write endpoints. |
| CP2-006 | Minor | `Cp2LedgerInvariantIT` / `ItemizedExpensesIT` scope | The invariant evidence stops at what exists today: no settlements, no balances endpoint, and the random generator never produced an engine-rejected itemized bill. | Section 2. | Re-run the same random test against `GET /balances` once B7 exists; extend the generator with large adjustments. |
| CP2-007 | Nit | `RequestSizeLimitFilter.java` | Wraps `getInputStream()` only; `getReader()` bypasses the count. Spring's JSON converter uses the stream, so no current exposure. | — | Wrap `getReader()` too, or leave a comment. |
| CP2-008 | Nit | `ExpenseGroup` `version` | A group's ETag does not change when expenses change although `totalSpentMinor` in the same body does (A27). No conditional GET exists, so no bug today. | — | Note for the mobile client: never cache group GETs by ETag. |
| CP2-009 | Nit | `Cp2LedgerInvariantIT.explainTheHotQueries…` | Documentation test: seeds 3 000 rows into the shared database and writes `target/cp2-explain.txt`; it asserts nothing about the plans. Whole class takes ~54 s. | — | Move to a `@Tag("perf")` group if CI time matters. |

No scope creep beyond Phase 1 (spec 3.2): the size filter, metrics and OpenAPI examples were requested by B5/B6 prompts. No secrets, tokens, titles or amounts in the new log events (`expense.created|updated|deleted`, ids and version only).

## 5. Performance review (evidence-first)

Workload model: one organizer per group, ~500 expenses per group, a handful of members, human-speed writes. `EXPLAIN (ANALYZE, BUFFERS)` on 3 000 expenses in one group (report in `backend/target/cp2-explain.txt` after the run):

| Query | Plan | Time |
|:--|:--|:--|
| List page, no filter / date range | `Index Scan using ix_expenses_group_list` + `Limit`, 22 buffers | 0.12–0.13 ms |
| Page filtered by member (payer **or** participant) | same index, hashed sub-plans over `ix_expense_payers_member` / `ix_expense_splits_member`; evaluates all of that member's rows before the limit | 1.4 ms |
| Splits of a page (`IN` 20 ids) | `expense_splits_pkey` bitmap scan | 0.15 ms |
| Payers of a page | seq scan (3 002 rows total; planner choice at this size, PK exists) | 0.37 ms |
| List count; group totals | seq scan of the whole table (the group *is* the table here; `ix_expenses_group` is used when other groups exist) | 0.7 / 1.0 ms |
| Member-in-use check | `Index Only Scan ix_expense_payers_member`, 0 heap fetches | 0.06 ms |

Reading: no missing index at the modelled load; the list is O(page). Count and totals are O(group size) and the member filter is O(member history): fine at ~500, revisit if a group grows by two orders of magnitude (hypothesis, not measured). Statement counts per list call are fixed (6 for EQUAL/EXACT pages, 8 with itemized bills; `ExpenseListQueryCountIT`). The group row lock is the single serialization point for all ledger writers of a group; hold time is validation + engine + up to ~1.6k inserts, acceptable for one organizer. Advisory locks are per `(user, key)`, so they cannot block another user. Edit = bulk delete + reinsert of child rows (bounded by the same caps).

## 6. What is good

- One calculator for create, preview and edit (`ExpenseCalculator`): numbers cannot diverge; the engine is untouched.
- Version check and write are atomic under the group lock, with `UNIQUE (expense_id, version)` as a second guard; 16 parallel edits give exactly one winner.
- Key row, expense, children and revision commit or roll back together (`ExpenseAtomicityIT` now also asserts no revision remains).
- Ownership is one door (`GroupAccessService`); every probe in the combined tests got the identical 404 body.
- Database constraints tie charges and breakdowns to totals (V6), and history is append-only with version/type constraints (V7).

## 7. Recommended fix order

1. CP2-001 (amount caps + CHECK + test) — before B7.
2. CP2-002 — commit, tag, run `V` for B4–B6; SEC-001/COR-001.
3. Receipts (HUMAN) — before B7.
4. CP2-004 and CP2-005 in B8; CP2-006 when B7 lands.

## 8. Validation commands

| Purpose | Safety | Command |
|:--|:--|:--|
| Full verification | safe (local, Testcontainers) | `cd backend && ./mvnw clean verify` |
| CP2 checks only | safe | `./mvnw -o verify -Dit.test=Cp2LedgerInvariantIT -Dtest=NoSuchTest -Dsurefire.failIfNoSpecifiedTests=false` |
| Reproduce CP2-001 | safe (local only) | create two EQUAL expenses with `totalMinor` 5000000000000000000, then `GET /api/v1/groups/{gid}` → 500 |
| Confirm fixtures/migrations untouched | safe | `git diff HEAD -- fixtures backend/src/main/resources/db/migration/V1* V2* V3* V4*` |

## 9. Key unknowns

| Unknown | Decision it changes | How to resolve |
|:--|:--|:--|
| Do the 3 real receipts match? | Whether the rules (service/tax base, rounding) are right for Egyptian receipts | HUMAN, section 3 |
| Does CI pass? | Whether the pipeline is trustworthy | Push and read the run |
| Behaviour with several large groups in one database | Whether count/totals need a covering index | Re-run the EXPLAIN test with many groups |
