#!/usr/bin/env bash
set -euo pipefail

COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.yml}"
BACKUP_DIR="${BACKUP_DIR:-backups}"
DB_SERVICE="${DB_SERVICE:-db}"
DB_NAME="${DB_NAME:-bookings}"
DB_USER="${DB_USER:-bookings}"

mkdir -p "$BACKUP_DIR"
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
backup_file="$BACKUP_DIR/${DB_NAME}_${timestamp}.dump"

echo "Creating $backup_file"
docker compose -f "$COMPOSE_FILE" exec -T "$DB_SERVICE" \
  pg_dump --format=custom --no-owner --no-privileges --dbname="$DB_NAME" --username="$DB_USER" > "$backup_file"

test -s "$backup_file"
echo "Backup complete: $backup_file"
