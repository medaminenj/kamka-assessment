#!/bin/bash
set -euo pipefail

# ===========================
# NoteFlow — Deploy Script
# Usage: ./scripts/deploy.sh
# ===========================

COMPOSE_FILE="docker-compose.yml"
HEALTH_URL="http://localhost:8080/actuator/health"
MAX_RETRIES=12
RETRY_INTERVAL=5

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }
error() { echo "[ERROR] $1" >&2; }

# Check .env exists
if [ ! -f .env ]; then
  error ".env file not found. Copy .env.example to .env and fill in values."
  exit 1
fi

log "Starting deployment..."

# Pull latest images (if using registry)
log "Pulling latest images..."
docker-compose -f "$COMPOSE_FILE" pull --quiet 2>/dev/null || true

# Rebuild and restart
log "Building and starting services..."
docker-compose -f "$COMPOSE_FILE" up -d --build

# Wait for backend health check
log "Waiting for backend to be healthy..."
for i in $(seq 1 $MAX_RETRIES); do
  if wget -qO- "$HEALTH_URL" 2>/dev/null | grep -q '"status":"UP"'; then
    log "Backend is healthy!"
    break
  fi
  if [ "$i" -eq "$MAX_RETRIES" ]; then
    error "Backend failed to become healthy after $((MAX_RETRIES * RETRY_INTERVAL))s. Rolling back..."
    docker-compose -f "$COMPOSE_FILE" down
    exit 1
  fi
  log "Attempt $i/$MAX_RETRIES — waiting ${RETRY_INTERVAL}s..."
  sleep "$RETRY_INTERVAL"
done

log "Deployment successful!"
log "Frontend:   http://localhost:80"
log "Backend:    http://localhost:8080"
log "Grafana:    http://localhost:3000"
log "Prometheus: http://localhost:9090"
