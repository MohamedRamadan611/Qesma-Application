# fixtures/

Shared money test vectors used by the Java engine tests now and by the Dart engine in Phase 4.

## Format (`fixtures/engine/*.json`)
One file per scenario:
```json
{
  "name": "human readable title",
  "input": {
    "members":     [ { "id": "A", "sortOrder": 1 } ],
    "expenses":    [ { "type": "EQUAL | EXACT | ITEMIZED | SHARES", "payers": [ { "memberId": "A", "amountMinor": 100 } ], "...": "type-specific fields" } ],
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
- `ITEMIZED` v2 (BSA2, STANDALONE_SPEC 18, A171–A177), all optional:
  - an item gives either `amountMinor` (legacy, quantity 1) or `unitAmountMinor` with an optional `quantity` (1..999); the line is `quantity × unitAmountMinor`;
  - `discount { bps }` or `discount { amountMinor }`: one discount on the whole bill;
  - `service { bps }` or `service { amountMinor }` (the legacy `serviceBps` is still read);
  - `tax { amountMinor, base }` next to the legacy `tax { bps, base }`;
  - map the item and each charge through the engine's shape rules (`Item.of`, `ChargeSpec.of` in Java), so both forms at once, or neither, is a `VALIDATION_ERROR`.
- `SHARES` (BSA3, STANDALONE_SPEC 19, A185–A187, A194): `totalMinor`, `shareParticipants[] { memberId, shareUnits, presentFrom?, presentTo? }` (units 1..100; presence dates `YYYY-MM-DD`, inclusive, only with a period, each bound defaulting to the period bound), optional `periodFrom` / `periodTo` (both or neither, inclusive, at most 366 days). Each participant's `sortOrder` comes from `members`. Weight = `shareUnits × days present` with a period, `shareUnits` without; owed = LRM over the weights (ties to the lower `sortOrder`). Map the expense straight to the engine (`SplitCalculator.shares` in Java), which rejects every rule itself, so a rejected expense is `expected.expenses[i] = { "error": "VALIDATION_ERROR" }`. The expected keys are the usual `owed` and `totalMinor` (no extra keys).

Extra `expected.expenses[i]` keys for ITEMIZED:
- `discountMinor`: the discount total (0 without a discount);
- `discounts { memberId: n }`: each listed member's discount part (members dropped for owing 0 are not listed, like `owed`);
- `error`: the bill must be rejected with this code (for example `"VALIDATION_ERROR"`); nothing else is asserted for that expense and it does not enter the ledger.

Rules:
- All amounts are integer minor units (piasters). Percentages are integer basis points. No decimals.
- `sortOrder` decides every tie-break (Decision A9); `members` is listed in that order.
- Only the keys present under `expected` are asserted. `transfers` is an ordered list (the order the spec 7.7 greedy rule produces).
- `expected` is the single authoritative answer; every engine must reproduce it exactly.

The standalone release (`docs/STANDALONE_SPEC.md`) adds more folders next to `engine/`: `pool/` (SA10), `ride/` (SA11) and `insights/` (SA7, SA8, and SA20's `budget-*` trip-budget vectors, Dart engine only: STANDALONE_SPEC 20.3); each is defined by the prompt that adds it. Both engines (Java and the Dart port, ADR-011) must pass every engine vector.

Vectors V1–V8 come from `docs/PROJECT_SPEC.md` section 10. They are run by `FixtureTest` in the backend (Java, the reference) and by `test/fixture_test.dart` in `mobile/packages/qesma_engine` (the Dart port).

Vectors V17–V20 (A180, delivery; `docs/STANDALONE_SPEC.md` 18.6) add `deliveryMinor` on the itemized expense (an amount, absent = none) and two `expected.expenses[i]` keys: `deliveryMinor` (the total) and `deliveries { memberId: n }` (each listed member's part). Delivery is outside discount, service and tax and goes equally to the members who have an item.

Vectors V9–V16 come from `docs/STANDALONE_SPEC.md` 18.6 (BSA2). Both runners run them: `FixtureTest` (Java) and, since SA15, `test/fixture_test.dart` (Dart engine) and `test/local/backend/engine_vectors_test.dart` (the local backend over HTTP). An item and each charge are mapped through the engine shape rules (`Item.of`, `ChargeSpec.of` in both languages).

Vectors V21–V28 (BSA3, `docs/STANDALONE_SPEC.md` 19.2) are the SHARES split: V21 units 1 = EQUAL, V22 units 2 / 1 / 1, V23 rent prorated by days present, V24 a half-period presence, V25 a one-day presence, V26 scaled units with the tie to the lower `sortOrder`, V27 and V28 the rejected shapes (units, duplicates, empty, presence and period rules). `FixtureTest` (Java), the Dart `fixture_test.dart` and the local-backend `engine_vectors_test.dart` (SA18) all run them.

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
