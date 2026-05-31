#!/bin/bash
set -e

ROOT="$(cd "$(dirname "$0")" && pwd)"

echo "Starting caddy..."
docker compose -f "$ROOT/docker-compose.yml" up -d

echo "Starting pihole..."
docker compose --env-file "$ROOT/.env" -f "$ROOT/pihole/docker-compose.yml" up -d

echo "Starting vaultwarden..."
docker compose --env-file "$ROOT/.env" -f "$ROOT/vaultwarden/docker-compose.yml" -f "$ROOT/vaultwarden/docker-compose.override.yml" up -d

echo "Starting minio..."
docker compose --env-file "$ROOT/.env" -f "$ROOT/minio/docker-compose.yml" -f "$ROOT/minio/docker-compose.override.yml" up -d

echo "Starting syncthing..."
docker compose -f "$ROOT/syncthing/docker-compose.yml" -f "$ROOT/syncthing/docker-compose.override.yml" up -d

echo "Starting immich..."
docker compose --env-file "$ROOT/.env" -f "$ROOT/immich/docker-compose.yml" -f "$ROOT/immich/docker-compose.override.yml" up -d

echo "Starting openwebui..."
docker compose --env-file "$ROOT/.env" -f "$ROOT/openwebui/docker-compose.yml" -f "$ROOT/openwebui/docker-compose.override.yml" up -d

echo "Starting nomad..."
docker compose --env-file "$ROOT/.env" -f "$ROOT/nomad/docker-compose.yml" -f "$ROOT/nomad/docker-compose.override.yml" up -d

echo "All services up."
