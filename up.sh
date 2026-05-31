#!/bin/bash
set -e

ROOT="$(cd "$(dirname "$0")" && pwd)"

echo "Starting caddy..."
"$ROOT/caddy/up.sh"

echo "Starting pihole..."
"$ROOT/pihole/up.sh"

echo "Starting vaultwarden..."
"$ROOT/vaultwarden/up.sh"

echo "Starting minio..."
"$ROOT/minio/up.sh"

echo "Starting syncthing..."
"$ROOT/syncthing/up.sh"

echo "Starting immich..."
"$ROOT/immich/up.sh"

echo "Starting openwebui..."
"$ROOT/openwebui/up.sh"

echo "Starting nomad..."
"$ROOT/nomad/up.sh"

echo "All services up."
