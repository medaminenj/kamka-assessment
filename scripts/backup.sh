#!/bin/bash
set -euo pipefail

# ===========================
# NoteFlow — Database Backup Script
# Usage: ./scripts/backup.sh
# Backs up MySQL (local) or PostgreSQL (prod) database
# ===========================

BACKUP_DIR="./backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
CONTAINER_NAME="noteflow-db"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }
error() { echo "[ERROR] $1" >&2; exit 1; }

# Check Docker is running
command -v docker >/dev/null 2>&1 || error "Docker is not installed or not running."

# Check container is running
docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$" || \
  error "Container '${CONTAINER_NAME}' is not running. Run 'docker-compose up -d' first."

# Load .env if exists
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

# Check required vars
: "${DATABASE_PASSWORD:?DATABASE_PASSWORD is not set. Check your .env file.}"

# Create backup directory
mkdir -p "$BACKUP_DIR"

BACKUP_FILE="${BACKUP_DIR}/noteflow_${TIMESTAMP}.sql"

log "Starting database backup..."
log "Backup file: ${BACKUP_FILE}"

# Run mysqldump inside the container
# Temporarily disable exit-on-error to handle mysqldump warning gracefully
set +e
docker exec "$CONTAINER_NAME" \
  mysqldump -u root -p"${DATABASE_PASSWORD}" \
  --no-tablespaces noteflow > "$BACKUP_FILE" 2>/tmp/mysqldump_err
DUMP_EXIT=$?
set -e

if [ $DUMP_EXIT -ne 0 ]; then
  cat /tmp/mysqldump_err >&2
  error "mysqldump failed with exit code $DUMP_EXIT"
fi

# Verify backup was created and is not empty
if [ ! -s "$BACKUP_FILE" ]; then
  error "Backup file is empty or was not created. Check database connection."
fi

BACKUP_SIZE=$(du -sh "$BACKUP_FILE" | cut -f1)
log "Backup completed successfully!"
log "File: ${BACKUP_FILE}"
log "Size: ${BACKUP_SIZE}"

# Keep only last 7 backups
log "Cleaning old backups (keeping last 7)..."
ls -t "${BACKUP_DIR}"/noteflow_*.sql 2>/dev/null | tail -n +8 | xargs -r rm --
log "Done."