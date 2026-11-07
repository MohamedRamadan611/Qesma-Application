#!/usr/bin/env bash
# Proves that backup and restore work, end to end, on throwaway PostgreSQL containers (needs Docker only):
#   1. a source database gets the real schema (all Flyway migrations) and a small ledger,
#   2. scripts/backup.sh dumps it,
#   3. scripts/restore.sh restores the dump into a brand-new server and database,
#   4. schema, every row (checksum) and the computed balances must be identical; unsafe restores must be refused.
# Exit code 0 = the restore procedure works. Run it after every change to the schema or the scripts.
set -euo pipefail
cd "$(dirname "$0")/.."

export MSYS_NO_PATHCONV=1                       # Git Bash on Windows: do not rewrite container paths
IMAGE="postgres:16.6-alpine"
PW="restore-test-only"
SRC="qesma-rt-src-$$"
DST="qesma-rt-dst-$$"
WORK="$(mktemp -d)"
host_path() { if command -v cygpath >/dev/null 2>&1; then cygpath -w "$1"; else printf '%s' "$1"; fi; }
cleanup() { docker rm -f "$SRC" "$DST" >/dev/null 2>&1 || true; rm -rf "$WORK"; }
trap cleanup EXIT
fail() { echo "FAIL: $*" >&2; exit 1; }

start_pg() {
  docker run -d --name "$1" -e POSTGRES_PASSWORD="$PW" -e POSTGRES_USER=qesma -e POSTGRES_DB=qesma "$IMAGE" >/dev/null
  for _ in $(seq 1 60); do
    if docker exec "$1" pg_isready -h 127.0.0.1 -U qesma -d qesma >/dev/null 2>&1; then return 0; fi
    sleep 1
  done
  fail "PostgreSQL in $1 did not become ready"
}
psql_in() { docker exec -i -e PGPASSWORD="$PW" "$1" psql -h 127.0.0.1 -U qesma -d "$2" -v ON_ERROR_STOP=1 -At "${@:3}"; }

echo "== 1. source database with the real schema and a small ledger"
start_pg "$SRC"
for f in $(ls backend/src/main/resources/db/migration/V*.sql | sort -V); do
  psql_in "$SRC" qesma -q < "$f" >/dev/null || fail "migration $f"
done
psql_in "$SRC" qesma -q >/dev/null <<'SQL'
insert into users (id, auth_provider, auth_subject, email, display_name)
  values ('00000000-0000-0000-0000-0000000000a1', 'GOOGLE', 'restore-test', 'rt@example.com', 'Restore Test');
insert into expense_groups (id, owner_user_id, name, type, currency_code, member_seq)
  values ('00000000-0000-0000-0000-0000000000b1', '00000000-0000-0000-0000-0000000000a1', 'Dahab', 'TRIP', 'EGP', 3);
insert into members (id, group_id, display_name, sort_order) values
  ('00000000-0000-0000-0000-0000000000c1', '00000000-0000-0000-0000-0000000000b1', 'M', 1),
  ('00000000-0000-0000-0000-0000000000c2', '00000000-0000-0000-0000-0000000000b1', 'A', 2),
  ('00000000-0000-0000-0000-0000000000c3', '00000000-0000-0000-0000-0000000000b1', 'S', 3);
insert into expenses (id, group_id, title, split_type, total_minor, expense_date, created_by_user_id) values
  ('00000000-0000-0000-0000-0000000000d1', '00000000-0000-0000-0000-0000000000b1', 'E1', 'EXACT', 10000, '2026-10-18', '00000000-0000-0000-0000-0000000000a1'),
  ('00000000-0000-0000-0000-0000000000d2', '00000000-0000-0000-0000-0000000000b1', 'E2', 'EXACT', 3000, '2026-10-18', '00000000-0000-0000-0000-0000000000a1');
insert into expense_payers values
  ('00000000-0000-0000-0000-0000000000d1', '00000000-0000-0000-0000-0000000000c1', 10000),
  ('00000000-0000-0000-0000-0000000000d2', '00000000-0000-0000-0000-0000000000c3', 3000);
insert into expense_splits (expense_id, member_id, owed_minor) values
  ('00000000-0000-0000-0000-0000000000d1', '00000000-0000-0000-0000-0000000000c2', 5000),
  ('00000000-0000-0000-0000-0000000000d1', '00000000-0000-0000-0000-0000000000c3', 5000),
  ('00000000-0000-0000-0000-0000000000d2', '00000000-0000-0000-0000-0000000000c2', 3000);
insert into expense_revisions (id, expense_id, version, change_type, snapshot, changed_by_user_id) values
  ('00000000-0000-0000-0000-0000000000e1', '00000000-0000-0000-0000-0000000000d1', 1, 'CREATE', '{"title":"E1"}', '00000000-0000-0000-0000-0000000000a1');
insert into settlements (id, group_id, from_member_id, to_member_id, amount_minor, settled_on, note, created_by_user_id)
  values ('00000000-0000-0000-0000-0000000000f1', '00000000-0000-0000-0000-0000000000b1',
          '00000000-0000-0000-0000-0000000000c2', '00000000-0000-0000-0000-0000000000c1', 8000, '2026-10-20', 'cash',
          '00000000-0000-0000-0000-0000000000a1');
insert into idempotency_keys (user_id, key, endpoint, request_hash, response_status, response_body)
  values ('00000000-0000-0000-0000-0000000000a1', 'restore-test-key', 'POST /x', 'h', 201, '{"ok":true}');
SQL

fingerprint() {   # $1 container, $2 database -> row counts, balances and a checksum of all data
  {
    psql_in "$1" "$2" <<'SQL'
select 'rows users=' || (select count(*) from users) || ' groups=' || (select count(*) from expense_groups)
  || ' members=' || (select count(*) from members) || ' expenses=' || (select count(*) from expenses)
  || ' payers=' || (select count(*) from expense_payers) || ' splits=' || (select count(*) from expense_splits)
  || ' items=' || (select count(*) from expense_items) || ' revisions=' || (select count(*) from expense_revisions)
  || ' settlements=' || (select count(*) from settlements) || ' keys=' || (select count(*) from idempotency_keys);
select 'net ' || member_id || ' ' || (sum(paid) - sum(owed) + sum(sent) - sum(received)) from (
  select p.member_id, p.amount_minor as paid, 0 as owed, 0 as sent, 0 as received
    from expense_payers p join expenses e on e.id = p.expense_id where e.deleted_at is null
  union all select s.member_id, 0, s.owed_minor, 0, 0
    from expense_splits s join expenses e on e.id = s.expense_id where e.deleted_at is null
  union all select from_member_id, 0, 0, amount_minor, 0 from settlements where deleted_at is null
  union all select to_member_id, 0, 0, 0, amount_minor from settlements where deleted_at is null
) l group by member_id order by member_id;
SQL
    docker exec -e PGPASSWORD="$PW" "$1" pg_dump -h 127.0.0.1 -U qesma -d "$2" --data-only --inserts --no-owner \
      | grep '^INSERT' | sort | sha256sum | sed 's/^/data-sha256 /'
    docker exec -e PGPASSWORD="$PW" "$1" pg_dump -h 127.0.0.1 -U qesma -d "$2" --schema-only --no-owner \
      | grep -v '^--' | grep -v '^$' | sha256sum | sed 's/^/schema-sha256 /'
  }
}
fingerprint "$SRC" qesma > "$WORK/source.txt"
cat "$WORK/source.txt"

echo "== 2. backup with scripts/backup.sh"
docker cp "$(host_path "$PWD/scripts")" "$SRC:/scripts"
docker exec -e PGHOST=127.0.0.1 -e PGUSER=qesma -e PGPASSWORD="$PW" -e PGDATABASE=qesma -e BACKUP_DIR=/backups "$SRC" sh /scripts/backup.sh
DUMP="$(docker exec "$SRC" sh -c 'ls /backups/qesma-*.dump' | head -1 | tr -d '\r')"
docker cp "$SRC:$DUMP" "$(host_path "$WORK/backup.dump")"
docker cp "$SRC:$DUMP.sha256" "$(host_path "$WORK/backup.dump.sha256")"
# keep the file name inside the checksum file in line with the copied name
sed -i "s#qesma-[0-9TZ]*\.dump#backup.dump#" "$WORK/backup.dump.sha256"

echo "== 3. restore into a brand-new server with scripts/restore.sh"
start_pg "$DST"
docker cp "$(host_path "$PWD/scripts")" "$DST:/scripts"
docker exec "$DST" mkdir -p /restore
docker cp "$(host_path "$WORK/backup.dump")" "$DST:/restore/backup.dump"
docker cp "$(host_path "$WORK/backup.dump.sha256")" "$DST:/restore/backup.dump.sha256"
RESTORE_ENV=(-e PGHOST=127.0.0.1 -e PGUSER=qesma -e PGPASSWORD="$PW" -e PGDATABASE=qesma)

if docker exec "${RESTORE_ENV[@]}" "$DST" sh /scripts/restore.sh /restore/backup.dump qesma >/dev/null 2>&1; then
  fail "restore into the live database was NOT refused"
fi
echo "ok: restoring into the live database is refused without --live"

docker exec "$DST" sh -c 'cp /restore/backup.dump /restore/corrupt.dump && cp /restore/backup.dump.sha256 /restore/corrupt.dump.sha256 && sed -i "s/backup.dump/corrupt.dump/" /restore/corrupt.dump.sha256 && echo x >> /restore/corrupt.dump'
if docker exec "${RESTORE_ENV[@]}" "$DST" sh /scripts/restore.sh /restore/corrupt.dump qesma_corrupt >/dev/null 2>&1; then
  fail "a corrupted dump was NOT refused"
fi
echo "ok: a dump whose checksum does not match is refused"

docker exec "${RESTORE_ENV[@]}" "$DST" sh /scripts/restore.sh /restore/backup.dump qesma_restored

echo "== 4. compare"
fingerprint "$DST" qesma_restored > "$WORK/restored.txt"
cat "$WORK/restored.txt"
diff "$WORK/source.txt" "$WORK/restored.txt" || fail "the restored database differs from the source"
echo "PASS: backup and restore reproduce schema, all rows and balances exactly"
