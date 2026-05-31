#!/bin/bash
set -e

ROOT="$(cd "$(dirname "$0")" && pwd)"

echo "Stopping nomad..."
docker compose -f "$ROOT/nomad/docker-compose.yml" down

echo "Stopping openwebui..."
docker compose -f "$ROOT/openwebui/docker-compose.yml" down

echo "Stopping immich..."
docker compose -f "$ROOT/immich/docker-compose.yml" down

echo "Stopping syncthing..."
docker compose -f "$ROOT/syncthing/docker-compose.yml" down

echo "Stopping minio..."
docker compose -f "$ROOT/minio/docker-compose.yml" down

echo "Stopping vaultwarden..."
docker compose -f "$ROOT/vaultwarden/docker-compose.yml" down

echo "Stopping pihole..."
docker compose -f "$ROOT/pihole/docker-compose.yml" down

echo "Stopping caddy..."
docker compose -f "$ROOT/docker-compose.yml" down

echo "All services down."
