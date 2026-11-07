#!/bin/sh
# Restores a dump made by scripts/backup.sh into a database.
#
#   restore.sh <dump-file> <target-database> [--replace] [--live]
#
# Needs pg_restore, psql, createdb, dropdb and the PG* variables (PGHOST, PGUSER, PGPASSWORD; PGDATABASE is the LIVE
# database). By default it refuses to touch the live database: restore into a new name first, check it, then switch.
#   --replace  drop the target database first if it exists
#   --live     allow the target to be the live database (stop the backend first!)
set -eu

usage() { echo "usage: $0 <dump-file> <target-database> [--replace] [--live]" >&2; exit 2; }
[ $# -ge 2 ] || usage
FILE="$1"; TARGET="$2"; shift 2
REPLACE=0; LIVE=0
for arg in "$@"; do
  case "$arg" in
    --replace) REPLACE=1 ;;
    --live) LIVE=1 ;;
    *) usage ;;
  esac
done
: "${PGHOST:?PGHOST is required}"
: "${PGUSER:?PGUSER is required}"
: "${PGPASSWORD:?PGPASSWORD is required}"

[ -f "$FILE" ] || { echo "no such dump: $FILE" >&2; exit 2; }
if [ -n "${PGDATABASE:-}" ] && [ "$TARGET" = "$PGDATABASE" ] && [ "$LIVE" -ne 1 ]; then
  echo "refusing to restore into the live database '$TARGET' without --live (stop the backend first)" >&2
  exit 3
fi

if [ -f "$FILE.sha256" ]; then
  ( cd "$(dirname "$FILE")" && sha256sum -c "$(basename "$FILE").sha256" ) || { echo "checksum mismatch" >&2; exit 4; }
fi

if [ "$REPLACE" -eq 1 ]; then
  dropdb --if-exists "$TARGET"
fi
createdb "$TARGET"
pg_restore --no-owner --exit-on-error --dbname="$TARGET" "$FILE"
echo "restore ok: $FILE -> $TARGET"
