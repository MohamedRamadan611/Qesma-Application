---
description: "T — Traceability and test-gap analysis"
---

Read AGENTS.md and docs/PROJECT_SPEC.md sections 7, 8.2, 8.5, 10. Do NOT change code. Build docs/gates/traceability.md: a matrix with one row per numbered spec rule (7.1–7.10), per endpoint in 8.2, per error code in 8.5, and per invariant in AGENTS.md. Columns: rule | where it is implemented (file:line) | tests that exercise it (file:method) | strength (strong = asserts exact values/behaviour; weak = only checks status or non-null; none).
Then list: rules with no test, rules with only weak tests, error codes never produced by any test, endpoints without an IDOR test, and tests that would still pass if the rule were deleted (explain why). Propose, but do not write, the missing tests in priority order.
