#!/bin/sh
# Daily PostgreSQL backup (custom format). Runs inside the "backup" container of docker-compose.prod.yml, or anywhere
# with pg_dump and the PG* variables set. Writes <dir>/qesma-<UTC timestamp>.dump plus a .sha256 file, verifies the
# dump can be read back, and deletes dumps older than BACKUP_RETENTION_DAYS.
set -eu

: "${PGHOST:?PGHOST is required}"
: "${PGUSER:?PGUSER is required}"
: "${PGPASSWORD:?PGPASSWORD is required}"
: "${PGDATABASE:?PGDATABASE is required}"
DIR="${BACKUP_DIR:-/backups}"
KEEP_DAYS="${BACKUP_RETENTION_DAYS:-14}"

mkdir -p "$DIR"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
FILE="$DIR/qesma-$STAMP.dump"

# Write to a temporary name first so a crashed dump never looks like a good backup.
pg_dump --format=custom --no-owner --file="$FILE.part"
mv "$FILE.part" "$FILE"
( cd "$DIR" && sha256sum "$(basename "$FILE")" > "$(basename "$FILE").sha256" )

# A backup that cannot be listed is not a backup.
pg_restore --list "$FILE" > /dev/null

find "$DIR" -name 'qesma-*.dump' -mtime +"$KEEP_DAYS" -delete
find "$DIR" -name 'qesma-*.dump.sha256' -mtime +"$KEEP_DAYS" -delete
echo "backup ok: $FILE ($(wc -c < "$FILE") bytes)"
