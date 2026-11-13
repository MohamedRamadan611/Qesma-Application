# balances fixtures

* `group_v1`, `balances_v1`, `balances_v2`, `balances_v3_settled`, `settlement_created`, `settlements_*`: responses **captured from the real backend** (FL7/B7, balances in the B13 shape: `pendingMinor`, `hasDispute`, `openSettlementIds`).
* `balances_v4_pending`, `balances_v5_disputed`, `settlements_by_status` (FL13): **shaped by the B13 contract** (`docs/openapi.json`, decisions A83-A88), not captured. Nets are exactly V1's (a pending or disputed payment never moves them, A83); the transfers keep V1's `amountMinor`. They mirror the B13 seed (one PENDING and one DISPUTED payment from Asem to Mohamed, A89). Replace them with captures when the two-user smoke (B19/FL18) runs against a real backend.
