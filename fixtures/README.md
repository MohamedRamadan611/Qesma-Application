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

The standalone release (`docs/STANDALONE_SPEC.md`) adds more folders next to `engine/`: `pool/` (SA10), `ride/` (SA11) and `insights/` (SA7, SA8); each is defined by the prompt that adds it. Both engines (Java and the Dart port, ADR-011) must pass every engine vector.

Vectors V1–V8 come from `docs/PROJECT_SPEC.md` section 10. They are run by `FixtureTest` in the backend (Java, the reference) and by `test/fixture_test.dart` in `mobile/packages/qesma_engine` (the Dart port).

## Parity rule (ADR-011)
- Both engines must pass every vector in `engine/`. A vector that one engine fails is a bug in that engine, never a reason to edit `expected`. Java is the reference.
- Any change in engine behaviour adds a new vector (or a new `expected` key) that pins it. A vector is never edited quietly to fit new behaviour.
- When the Java engine changes, the new vector and the matching Dart change go in the same commit, so both runners stay green at every commit.
- Run them with `./mvnw -q test -Dtest=FixtureTest` (from `backend/`) and `dart test test/fixture_test.dart` (from `mobile/packages/qesma_engine/`).

## Ride vectors (`fixtures/ride/*.json`, SA11, Dart-only)
Run by `test/ride/ride_fixture_test.dart` in `mobile/packages/qesma_engine` (STANDALONE_SPEC 11, A139-A141, A168). The Java engine is frozen for the standalone release, so these are not run by `FixtureTest`.
```json
{ "name": "...", "kind": "fuel",
  "input": { "distanceTenthsKm": 1000, "consumptionTenths": 81, "pricePerLitreMinor": 1375, "tollsMinor": [2500],
             "driver": { "id": "A", "sortOrder": 0 }, "driverIncluded": true, "passengers": [ { "id": "B", "sortOrder": 1 } ] },
  "expected": { "fuelMinor": 11138, "tollsMinor": 2500, "totalMinor": 13638, "payerMemberId": "A", "shares": { "A": 6819, "B": 6819 } } }
{ "name": "...", "kind": "multiStop",
  "input": { "fareMinor": 10000, "legDistancesTenthsKm": [50, 30],
             "riders": [ { "memberId": "A", "sortOrder": 0, "boardStop": 0, "leaveStop": 2 } ] },
  "expected": { "legFaresMinor": [5000, 5000], "shares": { "A": 10000 } } }
```
A rejected input has `"expected": { "error": "VALIDATION_ERROR" }`. Distances are tenths of km, consumption tenths of L/100 km, money in piasters.
