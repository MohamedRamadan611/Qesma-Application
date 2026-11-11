#!/usr/bin/env bash
# Qesma HTTP-edge performance probe: bash + curl + jq only. Seeds a large group through the public API, then times the read
# endpoints the mobile app uses. Local/staging with the fake verifier only (profiles local,fake-auth): NEVER production.
#
#   BASE_URL=http://localhost:8080 ./scripts/perf-seed.sh
#
# Environment:
#   EXPENSES=500   expenses in the big group           MEMBERS=15   members of the big group (2..100)
#   SETTLEMENTS=200  settlements in the big group      OTHER_GROUPS=0  extra small groups first (multi-group case)
#   CALLS=25       timed calls per endpoint            USER_SUFFIX=   fixed suffix to reuse one account (default: fresh per run)
#
# Prints a timing table (curl time_total, includes the network): p50 / p95 / max per endpoint, and the ids the phone needs.
# Seeding is not timed. Only /auth/** is rate limited (one login here). Exit code is non-zero if any request fails.
set -uo pipefail

BASE_URL="${BASE_URL:-http://localhost:8080}"
API="$BASE_URL/api/v1"
EXPENSES="${EXPENSES:-500}"; MEMBERS="${MEMBERS:-15}"; SETTLEMENTS="${SETTLEMENTS:-200}"
OTHER_GROUPS="${OTHER_GROUPS:-0}"; CALLS="${CALLS:-25}"
RUN="${USER_SUFFIX:-$(date +%s)-$RANDOM}"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

for tool in curl jq awk sort; do command -v "$tool" >/dev/null 2>&1 || { echo "missing tool: $tool"; exit 2; }; done
[ "$MEMBERS" -ge 2 ] && [ "$MEMBERS" -le 100 ] || { echo "MEMBERS must be 2..100"; exit 2; }

die() { echo "ERROR: $*" >&2; exit 1; }
uuid() {
  if command -v uuidgen >/dev/null 2>&1; then uuidgen
  elif [ -r /proc/sys/kernel/random/uuid ]; then cat /proc/sys/kernel/random/uuid
  else
    local h; h="$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n')"
    printf '%s-%s-4%s-%x%s-%s\n' "${h:0:8}" "${h:8:4}" "${h:13:3}" "$(( 0x${h:16:1} & 3 | 8 ))" "${h:17:3}" "${h:20:12}"
  fi
}

# call METHOD PATH [JSON] [extra header] -> prints "<status> <time_total>"; body in $TMP/body
call() {
  local method="$1" path="$2" data="${3:-}" extra="${4:-}"
  local args=(-s -o "$TMP/body" -w '%{http_code} %{time_total}' -X "$method" "$API$path" -H "Authorization: Bearer $TOKEN")
  [ -n "$data" ] && args+=(-H 'Content-Type: application/json' --data "$data")
  [ -n "$extra" ] && args+=(-H "$extra")
  curl "${args[@]}"
}
must() { # must <expected status> METHOD PATH [JSON] [extra header] -> the body
  local want="$1"; shift
  local out; out="$(call "$@")" || die "curl failed: $*"
  [ "${out%% *}" = "$want" ] || die "$2 $3 answered ${out%% *} (wanted $want): $(head -c 300 "$TMP/body")"
  cat "$TMP/body"
}

echo "== Qesma perf probe against $BASE_URL (run $RUN): $EXPENSES expenses, $MEMBERS members, $SETTLEMENTS settlements, $OTHER_GROUPS extra groups"

out="$(curl -s -X POST "$API/auth/google" -H 'Content-Type: application/json' -d "{\"idToken\":\"fake:perf-$RUN:perf-$RUN@example.com:Perf\"}")"
TOKEN="$(printf '%s' "$out" | jq -r .accessToken)"; [ -n "$TOKEN" ] && [ "$TOKEN" != null ] || die "login failed (fake-auth profile on?): $out"

new_group() { must 201 POST /groups "{\"name\":\"$1 $RUN\",\"type\":\"TRIP\"}"; }

# ---- optional: many small groups so the multi-group query plans are exercised (perf-notes open point) -----------------
if [ "$OTHER_GROUPS" -gt 0 ]; then
  echo "-- creating $OTHER_GROUPS small groups (3 members, 5 expenses each)"
  for g in $(seq 1 "$OTHER_GROUPS"); do
    body="$(new_group "Small $g")"; gid="$(printf '%s' "$body" | jq -r .id)"; owner="$(printf '%s' "$body" | jq -r '.members[0].id')"
    ids="$owner"
    for n in A B; do ids="$ids $(must 201 POST "/groups/$gid/members" "{\"displayName\":\"$n\"}" | jq -r .id)"; done
    set -- $ids; a="$1"; b="$2"; c="$3"
    for e in 1 2 3 4 5; do
      must 201 POST "/groups/$gid/expenses" "{\"title\":\"E$e\",\"expenseDate\":\"2026-10-18\",\"splitType\":\"EQUAL\",\"totalMinor\":$((e*1000+7)),\"participantMemberIds\":[\"$a\",\"$b\",\"$c\"],\"payers\":[{\"memberId\":\"$a\",\"amountMinor\":$((e*1000+7))}]}" "Idempotency-Key: $(uuid)" >/dev/null
    done
    [ $((g % 20)) -eq 0 ] && echo "   $g groups"
  done
fi

# ---- the big group ---------------------------------------------------------------------------------------------------
body="$(new_group "Perf big")"; GID="$(printf '%s' "$body" | jq -r .id)"
IDS=("$(printf '%s' "$body" | jq -r '.members[0].id')")
for n in $(seq 2 "$MEMBERS"); do IDS+=("$(must 201 POST "/groups/$GID/members" "{\"displayName\":\"Member $n\"}" | jq -r .id)"); done
echo "-- group $GID with ${#IDS[@]} members; creating $EXPENSES expenses"

START=$SECONDS; LAST_EXPENSE=""
for e in $(seq 1 "$EXPENSES"); do
  p1="${IDS[$(( e % MEMBERS ))]}"; p2="${IDS[$(( (e + 1) % MEMBERS ))]}"; p3="${IDS[$(( (e + 2) % MEMBERS ))]}"
  total=$(( 10000 + e * 37 ))
  case $(( e % 3 )) in
    0) split="\"splitType\":\"EQUAL\",\"participantMemberIds\":[\"$p1\",\"$p2\",\"$p3\"]"; payers="[{\"memberId\":\"$p1\",\"amountMinor\":$total}]" ;;
    1) half=$(( total / 2 )); rest=$(( total - half ))
       split="\"splitType\":\"EQUAL\",\"participantMemberIds\":[\"$p1\",\"$p2\",\"$p3\"]"
       payers="[{\"memberId\":\"$p1\",\"amountMinor\":$half},{\"memberId\":\"$p2\",\"amountMinor\":$rest}]" ;;
    2) a=$(( total / 3 )); b=$(( total / 3 )); c=$(( total - a - b ))
       split="\"splitType\":\"EXACT\",\"shares\":[{\"memberId\":\"$p1\",\"amountMinor\":$a},{\"memberId\":\"$p2\",\"amountMinor\":$b},{\"memberId\":\"$p3\",\"amountMinor\":$c}]"
       payers="[{\"memberId\":\"$p3\",\"amountMinor\":$total}]" ;;
  esac
  day=$(( 1 + e % 28 ))
  LAST_EXPENSE="$(must 201 POST "/groups/$GID/expenses" "{\"title\":\"Perf expense $e\",\"expenseDate\":\"2026-10-$(printf '%02d' $day)\",$split,\"totalMinor\":$total,\"payers\":$payers}" "Idempotency-Key: $(uuid)" | jq -r .id)"
  [ $((e % 100)) -eq 0 ] && echo "   $e expenses ($((SECONDS - START)) s)"
done

echo "-- creating $SETTLEMENTS settlements"
for s in $(seq 1 "$SETTLEMENTS"); do
  from="${IDS[$(( s % MEMBERS ))]}"; to="${IDS[$(( (s + 3) % MEMBERS ))]}"
  [ "$from" = "$to" ] && to="${IDS[$(( (s + 4) % MEMBERS ))]}"
  must 201 POST "/groups/$GID/settlements" "{\"fromMemberId\":\"$from\",\"toMemberId\":\"$to\",\"amountMinor\":$((100 + s)),\"settledOn\":\"2026-10-20\"}" "Idempotency-Key: $(uuid)" >/dev/null
done

# ---- correctness first: the ledger must still sum to zero ------------------------------------------------------------
sum="$(must 200 GET "/groups/$GID/balances" | jq '[.nets[].netMinor] | add')"
[ "$sum" = 0 ] || die "balances do not sum to zero: $sum"
total_exp="$(must 200 GET "/groups/$GID/expenses?page=0&size=20" | jq -r .totalElements)"
[ "$total_exp" = "$EXPENSES" ] || die "expected $EXPENSES expenses, the server counts $total_exp"
echo "-- seeded: ledger sums to 0, $total_exp expenses"

# ---- timings ---------------------------------------------------------------------------------------------------------
LASTPAGE=$(( (EXPENSES - 1) / 20 ))
time_endpoint() { # time_endpoint <label> <path>
  local label="$1" path="$2" times=() i out
  for i in $(seq 1 "$CALLS"); do
    out="$(call GET "$path")" || die "curl failed for $path"
    [ "${out%% *}" = 200 ] || die "$path answered ${out%% *}"
    times+=("${out##* }")
  done
  printf '%s\n' "${times[@]}" | sort -n | awk -v n="$CALLS" -v label="$label" \
    '{ t[NR] = $1 * 1000 } END { i50 = int((n * 50 + 99) / 100); i95 = int((n * 95 + 99) / 100); printf "%-44s %8.1f %8.1f %8.1f\n", label, t[i50], t[i95], t[n] }'
}
echo
printf '%-44s %8s %8s %8s   (ms, %s calls each)\n' endpoint p50 p95 max "$CALLS"
time_endpoint "GET /groups (list)" "/groups?page=0&size=20"
time_endpoint "GET /groups/{gid}" "/groups/$GID"
time_endpoint "GET expenses page 0 (20)" "/groups/$GID/expenses?page=0&size=20"
time_endpoint "GET expenses last page" "/groups/$GID/expenses?page=$LASTPAGE&size=20"
time_endpoint "GET expense detail" "/groups/$GID/expenses/$LAST_EXPENSE"
time_endpoint "GET expense revisions" "/groups/$GID/expenses/$LAST_EXPENSE/revisions"
time_endpoint "GET balances" "/groups/$GID/balances"
time_endpoint "GET settlements (page 0)" "/groups/$GID/settlements?page=0&size=20"

echo
echo "== done. For the phone: sign in with the debug fake token 'fake:perf-$RUN:perf-$RUN@example.com:Perf' (debug builds only), group $GID"
