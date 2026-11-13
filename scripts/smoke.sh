#!/usr/bin/env bash
# Qesma smoke test: bash + curl + jq only. Runs the Phase 1 flow against a running backend and asserts exact values
# (amounts in minor units, spec section 10 vectors). Exits non-zero on the first failure. Fresh data on every run.
#
#   BASE_URL=http://localhost:8080 ./scripts/smoke.sh
#
# The backend must run with the fake verifier (local,fake-auth profiles, see backend/README.md). Never point this at production.
# Auth endpoints are rate limited (default 10 requests per minute per IP): a default run uses 9. Wait a minute between runs.
# SMOKE_DAHAB=1 adds the seeded Dahab trip check (profile "seed"; one more auth request, so wait a minute before it).
set -uo pipefail

BASE_URL="${BASE_URL:-http://localhost:8080}"
API="$BASE_URL/api/v1"
RUN="$(date +%s)-$RANDOM"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

for tool in curl jq; do
  command -v "$tool" >/dev/null 2>&1 || { echo "FAIL missing tool: $tool"; exit 2; }
done

STEP=0
STATUS=""; BODY=""; HDRS=""

pass() { STEP=$((STEP + 1)); printf 'PASS %02d %s\n' "$STEP" "$1"; }
fail() { STEP=$((STEP + 1)); printf 'FAIL %02d %s\n' "$STEP" "$1"; [ -n "${2:-}" ] && printf '     %s\n' "$2"; [ -n "$BODY" ] && printf '     last response: %s %s\n' "$STATUS" "$(printf '%s' "$BODY" | head -c 600)"; exit 1; }

# expect <description> <expected> <actual>
expect() { if [ "$2" = "$3" ]; then pass "$1"; else fail "$1" "expected [$2] got [$3]"; fi; }

# req METHOD PATH TOKEN [JSON_BODY] [extra header ...]  -> sets STATUS, BODY, HDRS
req() {
  local method="$1" path="$2" token="$3" data="${4:-}"; shift 4 2>/dev/null || shift $#
  local args=(-s -o "$TMP/body" -D "$TMP/hdrs" -w '%{http_code}' -X "$method" "$API$path")
  [ -n "$token" ] && args+=(-H "Authorization: Bearer $token")
  if [ -n "$data" ]; then args+=(-H 'Content-Type: application/json' --data "$data"); fi
  local h; for h in "$@"; do args+=(-H "$h"); done
  STATUS="$(curl "${args[@]}")" || fail "curl $method $path" "connection failed to $BASE_URL"
  BODY="$(cat "$TMP/body")"
  HDRS="$(tr -d '\r' < "$TMP/hdrs")"
}
j() { printf '%s' "$BODY" | jq -r "$1"; }
header() { printf '%s\n' "$HDRS" | awk -v k="$(printf '%s' "$1" | tr 'A-Z' 'a-z')" 'BEGIN{FS=": "} tolower($1)==k {print $2; exit}'; }
uuid() { # RFC 4122 v4 UUID: uuidgen, else the kernel source, else random bytes from /dev/urandom
  if command -v uuidgen >/dev/null 2>&1; then uuidgen
  elif [ -r /proc/sys/kernel/random/uuid ]; then cat /proc/sys/kernel/random/uuid
  else
    local h; h="$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n')"
    printf '%s-%s-4%s-%x%s-%s\n' "${h:0:8}" "${h:8:4}" "${h:13:3}" "$(( 0x${h:16:1} & 3 | 8 ))" "${h:17:3}" "${h:20:12}"
  fi
}

login() { # login <subject> <name> -> access token
  req POST /auth/google "" "{\"idToken\":\"fake:smoke-$RUN-$1:smoke-$RUN-$1@example.com:$2\"}"
  [ "$STATUS" = 200 ] || fail "login $1" "status $STATUS"
  j .accessToken
}

new_group() { # new_group <token> <name> -> sets GID and leaves BODY = the create response (no subshell: BODY must survive)
  req POST /groups "$1" "{\"name\":\"$2 $RUN\",\"type\":\"TRIP\"}"
  [ "$STATUS" = 201 ] || fail "create group" "status $STATUS"
  GID="$(j .id)"
}

# five members: the owner member is renamed to Mohamed, then four more are added. Sets M A S Y K.
five_members() { # five_members <token> <gid>
  req GET "/groups/$2" "$1"
  local owner; owner="$(j '.members[0].id')"
  req PATCH "/groups/$2/members/$owner" "$1" '{"displayName":"Mohamed"}'
  [ "$STATUS" = 200 ] || fail "rename owner member" "status $STATUS"
  M="$owner"
  local n; for n in Asem Mohsen Youssef Kareem; do
    req POST "/groups/$2/members" "$1" "{\"displayName\":\"$n\"}"
    [ "$STATUS" = 201 ] || fail "add member $n" "status $STATUS"
    case "$n" in Asem) A="$(j .id)";; Mohsen) S="$(j .id)";; Youssef) Y="$(j .id)";; Kareem) K="$(j .id)";; esac
  done
}

net_of() { printf '%s' "$BODY" | jq -r --arg m "$1" '(.nets[] | select(.memberId==$m) | .netMinor) // 0'; }
# transfers as a sorted set: the spec fixes which transfers exist, not the order the engine prints them in
transfers() { printf '%s' "$BODY" | jq -c '[.transfers[] | [.fromMemberId,.toMemberId,.amountMinor]] | sort'; }
owed_of() { printf '%s' "$1" | jq -r --arg m "$2" '(.shares // .members)[] | select(.memberId==$m) | .owedMinor'; }

echo "== Qesma smoke against $BASE_URL (run $RUN)"

# ---- two users ---------------------------------------------------------------------------------------------------
TA="$(login a "Smoke A")"; TB="$(login b "Smoke B")"
[ -n "$TA" ] && [ -n "$TB" ] && [ "$TA" != "$TB" ] && pass "two different users signed in" || fail "two different users signed in"

# ---- 1. group + 5 members ----------------------------------------------------------------------------------------
new_group "$TA" "Smoke equal"; G1="$GID"
expect "create group: owner is already member #1 (isYou)" "true" "$(j '.members[0].isYou')"
expect "create group: yourNetMinor is 0" "0" "$(j '.yourNetMinor')"
five_members "$TA" "$G1"
req GET "/groups/$G1" "$TA"
expect "group has 5 members in order" "Mohamed,Asem,Mohsen,Youssef,Kareem" "$(j '[.members[].displayName] | join(",")')"
req POST "/groups/$G1/members" "$TA" '{"displayName":"Asem"}'
expect "duplicate member name is rejected (409 DUPLICATE_MEMBER_NAME)" "409 DUPLICATE_MEMBER_NAME" "$STATUS $(j .code)"
req DELETE "/groups/$G1/members/$M" "$TA"
expect "owner member cannot be deleted (409 OWNER_MEMBER_PROTECTED)" "409 OWNER_MEMBER_PROTECTED" "$STATUS $(j .code)"

# ---- 2. equal expense (V3: 100.00 among M, A, S -> 33.34 / 33.33 / 33.33) ----------------------------------------
EQ="{\"title\":\"Equal\",\"expenseDate\":\"2026-10-18\",\"splitType\":\"EQUAL\",\"totalMinor\":10000,
      \"participantMemberIds\":[\"$M\",\"$A\",\"$S\"],\"payers\":[{\"memberId\":\"$M\",\"amountMinor\":10000}]}"
KEY="$(uuid)"
req POST "/groups/$G1/expenses" "$TA" "$EQ" "Idempotency-Key: $KEY"
expect "equal expense created (201)" "201" "$STATUS"
E_EQ="$(j .id)"; FIRST_BODY="$BODY"
expect "equal split owed M/A/S = 3334/3333/3333" "3334,3333,3333" "$(owed_of "$BODY" "$M"),$(owed_of "$BODY" "$A"),$(owed_of "$BODY" "$S")"
req GET "/groups/$G1/balances" "$TA"
expect "equal expense nets M/A/S = +6666/-3333/-3333" "6666,-3333,-3333" "$(net_of "$M"),$(net_of "$A"),$(net_of "$S")"

# ---- 3. idempotent replay ----------------------------------------------------------------------------------------
req POST "/groups/$G1/expenses" "$TA" "$EQ" "Idempotency-Key: $KEY"
expect "replay returns the same expense id" "$E_EQ" "$(j .id)"
expect "replay is flagged Idempotency-Replayed: true" "true" "$(header Idempotency-Replayed)"
req GET "/groups/$G1/expenses?page=0&size=20" "$TA"
expect "replay created no duplicate (1 expense)" "1" "$(j '.totalElements')"
req POST "/groups/$G1/expenses" "$TA" "${EQ/10000/20000}" "Idempotency-Key: $KEY"
expect "same key with a different body is 422 IDEMPOTENCY_KEY_REUSED" "422 IDEMPOTENCY_KEY_REUSED" "$STATUS $(j .code)"

# ---- 4. authorization: user B gets 404, never 403 ---------------------------------------------------------------
req GET "/groups/$G1" "$TB"
expect "user B: GET group is 404" "404" "$STATUS"
req GET "/groups/$G1/balances" "$TB"
expect "user B: GET balances is 404" "404" "$STATUS"
req POST "/groups/$G1/expenses" "$TB" "$EQ" "Idempotency-Key: $(uuid)"
expect "user B: POST expense is 404" "404" "$STATUS"
req DELETE "/groups/$G1" "$TB"
expect "user B: DELETE group is 404" "404" "$STATUS"

# ---- 5. multi-payer (V4: 500.00, M pays 300.00, A pays 200.00, equal among M, A, S, Y) --------------------------------
new_group "$TA" "Smoke multipayer"; G2="$GID"; five_members "$TA" "$G2"
req POST "/groups/$G2/expenses" "$TA" "{\"title\":\"Multi\",\"expenseDate\":\"2026-10-18\",\"splitType\":\"EQUAL\",\"totalMinor\":50000,
  \"participantMemberIds\":[\"$M\",\"$A\",\"$S\",\"$Y\"],
  \"payers\":[{\"memberId\":\"$M\",\"amountMinor\":30000},{\"memberId\":\"$A\",\"amountMinor\":20000}]}" "Idempotency-Key: $(uuid)"
expect "multi-payer expense created (201)" "201" "$STATUS"
req POST "/groups/$G2/expenses" "$TA" "{\"title\":\"Bad\",\"expenseDate\":\"2026-10-18\",\"splitType\":\"EQUAL\",\"totalMinor\":50000,
  \"payers\":[{\"memberId\":\"$M\",\"amountMinor\":30000}]}" "Idempotency-Key: $(uuid)"
expect "payers not adding to the total: 422 PAYERS_TOTAL_MISMATCH" "422 PAYERS_TOTAL_MISMATCH" "$STATUS $(j .code)"
req GET "/groups/$G2/balances" "$TA"
expect "V4 nets M/A/S/Y/K = 17500/7500/-12500/-12500/0" "17500,7500,-12500,-12500,0" "$(net_of "$M"),$(net_of "$A"),$(net_of "$S"),$(net_of "$Y"),$(net_of "$K")"
expect "V4 transfers S>M 12500, Y>M 5000, Y>A 7500" \
  "$(jq -cn --arg m "$M" --arg a "$A" --arg s "$S" --arg y "$Y" '[[$s,$m,12500],[$y,$m,5000],[$y,$a,7500]] | sort')" "$(transfers)"

# ---- 6. itemized: V5..V8 with preview parity (A=M, B=A, C=S) --------------------------------------------------------
new_group "$TA" "Smoke itemized"; G3="$GID"; five_members "$TA" "$G3"
bill() { # bill <service-json|null> <tax-json|null> <totalMinor>
  printf '{"title":"Seafood","expenseDate":"2026-10-18","splitType":"ITEMIZED","payers":[{"memberId":"%s","amountMinor":%s}],
    "items":[{"name":"Pizza","amountMinor":20000,"assigneeMemberIds":["%s","%s"]},
             {"name":"Pasta","amountMinor":15000,"assigneeMemberIds":["%s"]},
             {"name":"Drinks","amountMinor":9000,"assigneeMemberIds":["%s","%s","%s"]}],
    "service":%s,"tax":%s,"adjustmentMinor":0}' "$M" "$3" "$M" "$A" "$S" "$M" "$A" "$S" "$1" "$2"
}
itemized_case() { # itemized_case <label> <service> <tax> <total> <owedM> <owedA> <owedS>
  local body; body="$(bill "$2" "$3" "$4")"
  req POST "/groups/$G3/expenses/preview" "$TA" "$body"
  expect "$1 preview: status 200" "200" "$STATUS"
  expect "$1 preview: total and owed M/A/S" "$4,$5,$6,$7" "$(j .totalMinor),$(owed_of "$BODY" "$M"),$(owed_of "$BODY" "$A"),$(owed_of "$BODY" "$S")"
  expect "$1 preview: payers match" "true" "$(j .payersTotalMatches)"
  local preview_owed; preview_owed="$(j '[.members[] | [.memberId,.owedMinor]] | sort')"
  req POST "/groups/$G3/expenses" "$TA" "$body" "Idempotency-Key: $(uuid)"
  expect "$1 saved: status 201" "201" "$STATUS"
  expect "$1 saved: total and owed M/A/S" "$4,$5,$6,$7" "$(j .totalMinor),$(owed_of "$BODY" "$M"),$(owed_of "$BODY" "$A"),$(owed_of "$BODY" "$S")"
  expect "$1 parity: preview equals saved shares" "$preview_owed" "$(j '[.shares[] | [.memberId,.owedMinor]] | sort')"
  LAST_ID="$(j .id)"
}
itemized_case "V5 service+tax" '{"bps":1200}' '{"bps":1400,"base":"SUBTOTAL_PLUS_SERVICE"}' 56179 16599 16598 22982
V5_ID="$LAST_ID"
itemized_case "V6 service only" '{"bps":1200}' null 49280 14560 14560 20160
itemized_case "V7 tax only"     null '{"bps":1400,"base":"SUBTOTAL"}' 50160 14820 14820 20520
itemized_case "V8 neither"      null null 44000 13000 13000 18000

# ---- 7. edit with ETag, stale ETag, delete, revisions (on the V5 expense) ---------------------------------------------
req GET "/groups/$G3/expenses/$V5_ID" "$TA"
expect "expense ETag is \"1\"" '"1"' "$(header ETag)"
EDIT="$(bill '{"bps":1200}' null 49280)"
req PUT "/groups/$G3/expenses/$V5_ID" "$TA" "$EDIT"
expect "edit without If-Match is 428" "428" "$STATUS"
req PUT "/groups/$G3/expenses/$V5_ID" "$TA" "$EDIT" 'If-Match: "1"'
expect "edit with the current ETag: 200 and ETag \"2\"" "200 \"2\"" "$STATUS $(header ETag)"
expect "edited expense total is 49280" "49280" "$(j .totalMinor)"
req PUT "/groups/$G3/expenses/$V5_ID" "$TA" "$EDIT" 'If-Match: "1"'
expect "edit with a stale ETag: 409 VERSION_CONFLICT" "409 VERSION_CONFLICT" "$STATUS $(j .code)"
req DELETE "/groups/$G3/expenses/$V5_ID" "$TA" "" 'If-Match: "2"'
expect "delete expense (soft): 204" "204" "$STATUS"
req GET "/groups/$G3/expenses/$V5_ID" "$TA"
expect "deleted expense detail is 404" "404" "$STATUS"
req GET "/groups/$G3/expenses/$V5_ID/revisions" "$TA"
expect "revisions keep the history CREATE,UPDATE,DELETE" "CREATE,UPDATE,DELETE" "$(printf '%s' "$BODY" | jq -r '(if type == "array" then . else .items end) | map(.changeType) | join(",")')"

# ---- 8. V1 + V2: exact splits, balances, settlement -------------------------------------------------------------------
new_group "$TA" "Smoke vectors"; G4="$GID"; five_members "$TA" "$G4"
req POST "/groups/$G4/expenses" "$TA" "{\"title\":\"E1\",\"expenseDate\":\"2026-10-18\",\"splitType\":\"EXACT\",\"totalMinor\":10000,
  \"shares\":[{\"memberId\":\"$A\",\"amountMinor\":5000},{\"memberId\":\"$S\",\"amountMinor\":5000}],
  \"payers\":[{\"memberId\":\"$M\",\"amountMinor\":10000}]}" "Idempotency-Key: $(uuid)"
expect "V1 E1 created (201)" "201" "$STATUS"
req POST "/groups/$G4/expenses" "$TA" "{\"title\":\"E2\",\"expenseDate\":\"2026-10-18\",\"splitType\":\"EXACT\",\"totalMinor\":3000,
  \"shares\":[{\"memberId\":\"$A\",\"amountMinor\":3000}],
  \"payers\":[{\"memberId\":\"$S\",\"amountMinor\":3000}]}" "Idempotency-Key: $(uuid)"
expect "V1 E2 created (201)" "201" "$STATUS"
req GET "/groups/$G4/balances" "$TA"
expect "V1 nets M/S/A = +10000/-2000/-8000" "10000,-2000,-8000" "$(net_of "$M"),$(net_of "$S"),$(net_of "$A")"
expect "V1 transfers A>M 8000, S>M 2000" "$(jq -cn --arg m "$M" --arg a "$A" --arg s "$S" '[[$a,$m,8000],[$s,$m,2000]] | sort')" "$(transfers)"
req GET "/groups" "$TA"
expect "group list: yourNetMinor for the owner (Mohamed) is +10000" "10000" "$(printf '%s' "$BODY" | jq -r --arg g "$G4" '.items[] | select(.id==$g) | .yourNetMinor')"
req POST "/groups/$G4/settlements" "$TA" "{\"fromMemberId\":\"$A\",\"toMemberId\":\"$M\",\"amountMinor\":8000,\"settledOn\":\"2026-10-20\",\"note\":\"cash\"}" "Idempotency-Key: $(uuid)"
expect "V2 settlement A>M 8000 recorded (201)" "201" "$STATUS"
req GET "/groups/$G4/balances" "$TA"
expect "V2 nets M/S/A = +2000/-2000/0" "2000,-2000,0" "$(net_of "$M"),$(net_of "$S"),$(net_of "$A")"
expect "V2 transfers S>M 2000" "$(jq -cn --arg m "$M" --arg s "$S" '[[$s,$m,2000]] | sort')" "$(transfers)"

# ---- 9. password accounts (ADR-008): username + password, no email -----------------------------------------------------
PW_NAME="Smoke.$RUN"; PW_LOWER="$(printf '%s' "$PW_NAME" | tr 'A-Z' 'a-z')"
PW1="correct horse battery"; PW2="a brand new passphrase"
req POST /auth/register "" "{\"username\":\"$PW_NAME\",\"password\":\"$PW1\",\"displayName\":\"Smoke Pw\"}"
expect "register: 201, username lower-cased, hasPassword, no email" "201 $PW_LOWER true null" "$STATUS $(j .user.username) $(j .user.hasPassword) $(j .user.email)"
PW_ID="$(j .user.id)"; TP="$(j .accessToken)"
[ -n "$TP" ] && [ "$TP" != null ] && pass "register returns an access token" || fail "register returns an access token"
req POST /auth/login "" "{\"username\":\"$PW_NAME\",\"password\":\"$PW1\"}"
expect "login with the same username (any case) and password: 200, same user" "200 $PW_ID" "$STATUS $(j .user.id)"
req POST /auth/login "" "{\"username\":\"$PW_LOWER\",\"password\":\"not the password\"}"
WRONG="$STATUS $(j .code)"
req POST /auth/login "" "{\"username\":\"nobody.$RUN\",\"password\":\"$PW1\"}"
expect "wrong password and unknown username give the same 401 answer" "$WRONG" "$STATUS $(j .code)"
expect "that answer is 401 UNAUTHORIZED" "401 UNAUTHORIZED" "$WRONG"
req POST /auth/register "" "{\"username\":\"$PW_LOWER\",\"password\":\"another passphrase\"}"
expect "a taken username with another password: 409 USERNAME_TAKEN" "409 USERNAME_TAKEN" "$STATUS $(j .code)"
req POST /auth/register "" "{\"username\":\"weak.$RUN\",\"password\":\"password1\"}"
expect "a common password is refused: 422 VALIDATION_ERROR" "422 VALIDATION_ERROR" "$STATUS $(j .code)"
req GET /me "$TP"
expect "GET /me for the password user" "200 $PW_LOWER" "$STATUS $(j .username)"
new_group "$TP" "Smoke password"; GP="$GID"
req GET "/groups/$GP" "$TA"
expect "the password user's group is 404 for user A (owner-only)" "404" "$STATUS"
req POST /me/password "$TP" "{\"currentPassword\":\"wrong current\",\"newPassword\":\"$PW2\"}"
expect "change password with a wrong current password: 422 (the session is not ended)" "422" "$STATUS"
req GET /me "$TP"
expect "the session still works after the refused change" "200" "$STATUS"
req POST /me/password "$TP" "{\"currentPassword\":\"$PW1\",\"newPassword\":\"$PW2\"}"
expect "change password: 200 with fresh tokens" "200 true" "$STATUS $(j '(.accessToken | length) > 20')"
TP2="$(j .accessToken)"
req GET /me "$TP2"
expect "the fresh access token works" "200 $PW_ID" "$STATUS $(j .id)"
req POST /auth/login "" "{\"username\":\"$PW_LOWER\",\"password\":\"$PW1\"}"
expect "the old password no longer works: 401" "401" "$STATUS"

# ---- 10. optional: the seeded Dahab trip (profile seed): the documented balances ---------------------------------------
if [ "${SMOKE_DAHAB:-0}" = 1 ]; then
  req POST /auth/google "" '{"idToken":"fake:dahab:mohamed@example.com:Mohamed"}'
  [ "$STATUS" = 200 ] || fail "login as the seeded Dahab owner" "is the backend running with the seed profile?"
  TD="$(j .accessToken)"
  req GET "/groups?page=0&size=20" "$TD"
  DG="$(printf '%s' "$BODY" | jq -r '[.items[] | select(.memberCount == 4)][0].id // empty')"
  [ -n "$DG" ] && pass "the seeded Dahab group is listed (4 active members, one left)" || fail "the seeded Dahab group is listed (4 active members, one left)"
  req GET "/groups/$DG/balances" "$TD"
  expect "Dahab nets (sorted) -72000,-72000,-68803,101401,111402" "-72000,-72000,-68803,101401,111402" "$(j '[.nets[].netMinor] | sort | join(",")')"
  expect "Dahab: the documented four transfers" "4" "$(j '.transfers | length')"
  expect "Dahab: transfers move exactly what the creditors are owed (212803)" "212803" "$(j '[.transfers[].amountMinor] | add')"
else
  printf 'SKIP    Dahab seed check (set SMOKE_DAHAB=1 with the seed profile)\n'
fi

echo "== all $STEP checks passed"
