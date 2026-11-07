#!/bin/bash
# Dumps the Synapse Postgres database into $MATRIX_DATA_DIR/dumps and keeps the
# newest $MATRIX_BACKUP_KEEP dumps. Safe to run while the stack is up.
#
#   MATRIX_DATA_DIR=/mnt/hddpool/matrix ./matrix/backup.sh
#
# Restore into a freshly initialised (empty) postgres container:
#   docker exec -i matrix_postgres pg_restore -U synapse -d synapse --no-owner < <dump>
set -euo pipefail

MATRIX_DATA_DIR="${MATRIX_DATA_DIR:-/opt/matrix}"
MATRIX_BACKUP_KEEP="${MATRIX_BACKUP_KEEP:-14}"
CONTAINER=matrix_postgres
DUMP_DIR="$MATRIX_DATA_DIR/dumps"

if ! [[ "$MATRIX_BACKUP_KEEP" =~ ^[1-9][0-9]*$ ]]; then
    echo "ERROR: MATRIX_BACKUP_KEEP must be a positive integer, got '$MATRIX_BACKUP_KEEP'" >&2
    exit 1
fi

if [ "$(docker inspect -f '{{.State.Running}}' "$CONTAINER" 2>/dev/null)" != "true" ]; then
    echo "ERROR: container $CONTAINER is not running; start the stack with ./matrix/up.sh" >&2
    exit 1
fi

# Dumps contain every account's password hash and all room history.
umask 077
mkdir -p "$DUMP_DIR"

STAMP="$(date +%Y-%m-%dT%H%M%S)"
FINAL="$DUMP_DIR/synapse-$STAMP.dump"
# Write to a dot-prefixed temp name so a failed or interrupted dump is never
# mistaken for a good one by the rotation glob below.
TMP="$DUMP_DIR/.synapse-$STAMP.dump.partial"
trap 'rm -f "$TMP"' EXIT

echo "Dumping synapse database to $FINAL..."
docker exec "$CONTAINER" pg_dump -U synapse -Fc synapse > "$TMP"

# A dump pg_restore can't read is worse than no dump: it would push a good one
# out of the rotation.
if ! docker exec -i "$CONTAINER" pg_restore --list < "$TMP" > /dev/null; then
    echo "ERROR: pg_restore could not read the new dump; keeping existing dumps untouched" >&2
    exit 1
fi

mv "$TMP" "$FINAL"
echo "Wrote $FINAL ($(du -h "$FINAL" | cut -f1))"

# Timestamps sort lexically, so the newest dumps are at the end.
mapfile -t DUMPS < <(find "$DUMP_DIR" -maxdepth 1 -name 'synapse-*.dump' -type f | sort)
EXCESS=$(( ${#DUMPS[@]} - MATRIX_BACKUP_KEEP ))
for (( i = 0; i < EXCESS; i++ )); do
    echo "Removing old dump ${DUMPS[$i]}"
    rm -f "${DUMPS[$i]}"
done
