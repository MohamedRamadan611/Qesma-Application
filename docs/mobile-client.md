# Mobile client handoff (Dart / dio)

The contract is **`docs/openapi.json`** (OpenAPI 3.0.1). It is produced by the backend itself (test `OpenApiExportIT`), so it cannot drift from the code: CI fails if the committed file differs from what the app generates. No Flutter or Dart code is generated or committed by the backend.

## 1. Generate the client

Verified with `openapitools/openapi-generator-cli:v7.8.0` (the generation itself ran without errors; `build_runner` was **not** run because there is no Flutter project yet).

```bash
# from the repository root
docker run --rm -v "${PWD}:/local" openapitools/openapi-generator-cli:v7.8.0 generate \
  -i /local/docs/openapi.json \
  -g dart-dio \
  -o /local/mobile/packages/qesma_api \
  --additional-properties=pubName=qesma_api,pubVersion=1.0.0,serializationLibrary=built_value

cd mobile/packages/qesma_api
dart pub get
dart run build_runner build     # built_value serializers
```

Check the file first (this is also a CI job):

```bash
docker run --rm -v "${PWD}:/local" openapitools/openapi-generator-cli:v7.8.0 validate -i /local/docs/openapi.json
```

`mobile/tool/generate_api.sh` runs all of the above (and refreshes `mobile/openapi.sha256`). The generated paths already include `/api/v1`, so the app's `API_BASE_URL` is the server origin only.

The generator names the HTTP-GET helper `callGet` (a Dart reserved word); that warning is harmless.

## 2. Regenerate after a backend change

```bash
cd backend
./mvnw -o verify -Dit.test=OpenApiExportIT -Dtest=NoSuchTest -Dsurefire.failIfNoSpecifiedTests=false -Dopenapi.write=true
```
Commit the updated `docs/openapi.json`, then re-run the client generation above.

## 2b. Operation names

Every operation has an explicit, stable `operationId` (the Dart method name): `signInWithGoogle`, `refreshSession`, `signOut`, `getMe`, `updateMe`, `listGroups`, `createGroup`, `getGroup`, `updateGroup`, `deleteGroup`, `addMember`, `renameMember`, `deleteMember`, `listExpenses`, `createExpense`, `previewExpense`, `getExpense`, `updateExpense`, `deleteExpense`, `listExpenseRevisions`, `getBalances`, `listSettlements`, `createSettlement`, `deleteSettlement`. They live in one table (`OpenApiConfig.OPERATION_IDS`); a new endpoint without an entry fails the OpenAPI export, and `ApiContractCoverageIT` checks they are unique and well formed. Renaming one is a breaking change for the generated client.

B10/B11 added nine operations (the contract has 40): `createInvite`, `listInvites`, `revokeInvite`, `getInvitePreview`, `joinGroup`, `listJoinRequests`, `approveJoinRequest`, `rejectJoinRequest`, `unlinkMember`. The generated client in `mobile/packages/qesma_api` was regenerated for them in FL10 (`mobile/openapi.sha256` matches).

## 3. Rules a client must follow

| Topic | Rule |
|:--|:--|
| Base URL | `https://<your domain>/api/v1` (the document uses relative paths). |
| Auth | `POST /auth/google` with the Google ID token → `accessToken` (15 min), `refreshToken` (30 days). Send `Authorization: Bearer <accessToken>`. |
| Refresh | `POST /auth/refresh` returns a NEW refresh token every time; store it and drop the old one. Using an old refresh token again ends the whole session (reuse detection): never retry a refresh with a token you already used. |
| Money | Every field ending in `Minor` is an **integer in piasters** (1 EGP = 100), `int64` in the schema (maximum 10^12, which is also safe in JavaScript numbers). Never use `double`. Percentages are integer basis points (`bps`, 1200 = 12.00%). |
| Calculations | The backend is authoritative. Do not compute splits or balances on the device: call `POST /groups/{gid}/expenses/preview` while the user edits (no key needed, nothing saved) and `GET /groups/{gid}/balances`. |
| Creating things | `POST` expenses and settlements need `Idempotency-Key` (a UUID you generate once per user action). If the request times out or fails to reach you, retry with **the same key and the same body**: the first answer is returned (`Idempotency-Replayed: true`) and nothing is duplicated. A different body with the same key is `422 IDEMPOTENCY_KEY_REUSED`. Keys last 24 hours. A replay returns the answer as it was at creation: re-read the expense afterwards. |
| Editing | `PUT`/`PATCH`/`DELETE` of expenses and `PATCH` of groups need `If-Match: "<version>"` taken from the `ETag` of your last read. `409 VERSION_CONFLICT` means someone changed it: re-read, merge, retry. `428` means the header was missing. Send the explicit participant list when editing (members who joined later are never added silently). |
| Errors | `application/problem+json` with a stable `code` (see the `Problem` schema for the full list) and a `requestId`: show your own localized text per `code`, never the English `title`. Quote `requestId` in bug reports. |
| Not found | Another user's data answers `404 NOT_FOUND`, identical to a missing id. There is no 403. |
| Paging | List endpoints take `page` (0-based) and `size` (max 100) and return `{items, page, size, totalElements, totalPages}`. |
| Rate limit | Auth endpoints answer `429 RATE_LIMITED` after 10 requests/minute per IP. |

## 4. Development data and login without Google

Run the backend with the profiles `local,fake-auth,seed` (see `backend/README.md`). It creates the Dahab trip from `docs/STITCH_PROMPTS.md` (5 members, 3 expenses, the documented balances). Sign in by sending this fake ID token to `POST /auth/google`:

```
fake:dahab:mohamed@example.com:محمد
```

`fake-auth` is refused together with the `prod` profile.

## B11 (invitations) contract changes
New operations (regenerate the client): `createInvite`, `listInvites`, `revokeInvite` (group-scoped, Owner/Admin), `getInvitePreview` (`GET /invites/{code}`), `joinGroup` (`POST /invites/{code}/join`: **201 JOINED or 202 PENDING_APPROVAL**, so the generated method must accept both), `listJoinRequests`, `approveJoinRequest`, `rejectJoinRequest`, `unlinkMember`. New error codes: `INVITE_EXPIRED` (410), `INVITE_REVOKED` (410), `ALREADY_MEMBER` (409), `MEMBER_ALREADY_CLAIMED` (409); `403 FORBIDDEN` also appears on the group-scoped invite operations. The invite code has no separate link token: the link is `https://<host>/join/<code>`.
