#!/usr/bin/env bash
set -euo pipefail

COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.yml}"
DB_SERVICE="${DB_SERVICE:-db}"
DB_NAME="${DB_NAME:-bookings}"
DB_USER="${DB_USER:-bookings}"
BACKUP_FILE="${1:-}"

if [[ -z "$BACKUP_FILE" || ! -s "$BACKUP_FILE" ]]; then
  echo "Usage: $0 backups/bookings_<timestamp>.dump" >&2
  exit 1
fi

echo "Waiting for PostgreSQL..."
docker compose -f "$COMPOSE_FILE" exec -T "$DB_SERVICE" \
  pg_isready --dbname="$DB_NAME" --username="$DB_USER" >/dev/null

echo "Recreating database $DB_NAME from $BACKUP_FILE"
docker compose -f "$COMPOSE_FILE" exec -T "$DB_SERVICE" \
  dropdb --if-exists --username="$DB_USER" "$DB_NAME"
docker compose -f "$COMPOSE_FILE" exec -T "$DB_SERVICE" \
  createdb --username="$DB_USER" "$DB_NAME"
docker compose -f "$COMPOSE_FILE" exec -T "$DB_SERVICE" \
  pg_restore --exit-on-error --no-owner --no-privileges --dbname="$DB_NAME" --username="$DB_USER" < "$BACKUP_FILE"

echo "Restore complete. Verify with: docker compose exec -T $DB_SERVICE psql -U $DB_USER -d $DB_NAME -c 'SELECT COUNT(*) FROM hotel_bookings;'"
