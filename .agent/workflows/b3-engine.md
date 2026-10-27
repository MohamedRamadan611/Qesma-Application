---
description: "B3 — Split engine (pure Java)"
---

Read AGENTS.md, docs/PROJECT_SPEC.md sections 2, 6 (only the money columns), 7 (all), 10 (all). This prompt builds ONLY the `engine` package in /backend: pure Java 21, no Spring, no JPA, no I/O. It is the most critical code in the project.

Step 0 (plan, wait for my approval): propose the engine API (types and method signatures), the validation/exception design (typed exceptions mapping later to the spec's error codes), and the fixture JSON format. Keep it small and boring.

Then implement with TESTS FIRST:
1. Types: member reference (id + sortOrder), money as long minor units, bps as int. Immutable records.
2. Largest Remainder Method (spec 7.1): exact shares with Math.multiplyExact/BigInteger (never floating point); floor + distribute remaining units by largest fractional remainder; tie-break lower sortOrder; zero total weight => equal weights; negative totals allocate abs and re-apply sign. round_half_up for bps amounts.
3. EQUAL (7.2), EXACT (7.3) with the exact validations and typed errors (SPLIT_TOTAL_MISMATCH etc.).
4. Payers validation (7.5): >=1 payer, amounts > 0, no duplicate member, sum == total (PAYERS_TOTAL_MISMATCH). Payers need not be participants.
5. ITEMIZED (7.4): item shares by LRM among assignees; optional service (own bps); optional tax (own bps, base SUBTOTAL or SUBTOTAL_PLUS_SERVICE, default SUBTOTAL_PLUS_SERVICE); optional signed adjustment allocated by LRM on item subtotals; every combination (service only / tax only / both / neither) must work; members with owed == 0 are dropped; total must be > 0; return per-member breakdown (items, service, tax, adjustment, owed) plus subtotal/service/tax totals.
6. Balances (7.6): nets from expenses (payers, splits) and settlements; invariant sum(net) == 0.
7. Simplification (7.7): the deterministic greedy algorithm with the exact tie-breaks.
8. Shared fixtures: create /fixtures/engine/*.json for ALL vectors V1–V8 from spec section 10 with exact expected numbers (minor units), plus a JUnit test that loads and runs every fixture. Fixture format: { name, input, expected } so a future Dart engine can reuse them.
9. Extra example tests worth writing: remainder ties, zero weights, item shared by 7 people, negative adjustment, tax base variants, rejecting mismatched payers/exacts, large amounts (1,250,000.50 EGP), overflow protection.
10. Property tests with jqwik: LRM parts sum exactly to the total and each part is within 1 minor unit of its exact share; sum(owed) == total; sum(net) == 0 after random sequences of expenses and settlements; applying the simplified transfers zeroes all nets; results are deterministic for the same input.

Constraints: follow AGENTS.md; no Spring imports anywhere under engine; no floating point; no randomness without a fixed seed in non-property tests; do not touch the database or HTTP layers.
Done when: all V1–V8 fixtures pass, property tests pass over thousands of cases, and I can read each rule in code next to its spec section number (reference the spec section in Javadoc). Then follow the Stop protocol.
