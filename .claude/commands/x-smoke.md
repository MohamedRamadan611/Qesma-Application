---
description: "X — Create/extend scripts/smoke.sh"
---

Read AGENTS.md and backend/README.md. Create or extend scripts/smoke.sh (bash + curl + jq only, no new dependencies). It runs against BASE_URL (default http://localhost:8080) using the fake-verifier login documented in backend/README.md, with two different users.
Cover, in order, for the features that exist so far: create group; add 5 members (Mohamed, Asem, Mohsen, Youssef, Kareem); equal expense; multi-payer expense; (after B5) itemized expense for each service/tax combination plus preview parity; (after B6) edit with ETag, stale ETag conflict, delete, revisions; (after B7) balances and transfers equal the expected numbers from spec section 10, settlement, balances after settlement; user B gets 404 on user A's group; idempotent replay returns the same response without creating a duplicate.
Every step asserts exact values (amounts in minor units), prints one PASS/FAIL line, and the script exits non-zero on the first failure. Each run uses fresh data so it can be repeated. Document how to run it in backend/README.md. Do not change application code.
