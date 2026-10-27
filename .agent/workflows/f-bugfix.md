---
description: "F — Bug-fix prompt template"
---

Read AGENTS.md. Bug: [what happened, expected vs actual, request/response or test output, spec section if relevant].
Do NOT change code until you can explain the bug. Steps: (1) reproduce with a failing test (red) at the lowest level that shows it (engine fixture first if it is a money bug); (2) read the actual logs/outputs; (3) state one falsifiable hypothesis and verify it; (4) fix the root cause, not the symptom; (5) show the test now passing and the full suite green; (6) add the case as a permanent regression test (and a fixture in /fixtures if it is a money rule). If the fix needs a rule change, STOP and ask. Summarize cause, fix, and any similar places that might have the same bug.
