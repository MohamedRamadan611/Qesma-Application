# fixtures/

Shared money test vectors used by the Java engine tests now and by the Dart engine in Phase 4.

## Format (`fixtures/engine/*.json`)
One file per scenario:
```json
{
  "name": "human readable title",
  "input": {
    "members":     [ { "id": "A", "sortOrder": 1 } ],
    "expenses":    [ { "type": "EQUAL | EXACT | ITEMIZED", "payers": [ { "memberId": "A", "amountMinor": 100 } ], "...": "type-specific fields" } ],
    "settlements": [ { "fromMemberId": "A", "toMemberId": "B", "amountMinor": 100 } ]
  },
  "expected": {
    "expenses":  [ { "owed": { "A": 100 }, "totalMinor": 100, "subtotalMinor": 0, "serviceMinor": 0, "taxMinor": 0 } ],
    "nets":      { "A": 0 },
    "transfers": [ { "fromMemberId": "A", "toMemberId": "B", "amountMinor": 100 } ]
  }
}
```
Type-specific expense fields:
- `EQUAL`: `totalMinor`, `participantMemberIds[]`
- `EXACT`: `totalMinor`, `shares[] { memberId, amountMinor }`
- `ITEMIZED`: `items[] { name, amountMinor, assigneeMemberIds[] }`, optional `serviceBps`, optional `tax { bps, base }`, `adjustmentMinor`

Rules:
- All amounts are integer minor units (piasters). Percentages are integer basis points. No decimals.
- `sortOrder` decides every tie-break (Decision A9); `members` is listed in that order.
- Only the keys present under `expected` are asserted. `transfers` is an ordered list (the order the spec 7.7 greedy rule produces).
- `expected` is the single authoritative answer; every engine must reproduce it exactly.

Vectors V1–V8 come from `docs/PROJECT_SPEC.md` section 10. They are run by `FixtureTest` in the backend.
