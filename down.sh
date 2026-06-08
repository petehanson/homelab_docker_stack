#!/bin/bash
set -e

ROOT="$(cd "$(dirname "$0")" && pwd)"

echo "Stopping nomad..."
"$ROOT/nomad/down.sh"

echo "Stopping openwebui..."
"$ROOT/openwebui/down.sh"

echo "Stopping llm..."
"$ROOT/llm/down.sh"

echo "Stopping immich..."
"$ROOT/immich/down.sh"

echo "Stopping syncthing..."
"$ROOT/syncthing/down.sh"

echo "Stopping minio..."
"$ROOT/minio/down.sh"

echo "Stopping vaultwarden..."
"$ROOT/vaultwarden/down.sh"

echo "Stopping pihole..."
"$ROOT/pihole/down.sh"

echo "Stopping caddy..."
"$ROOT/caddy/down.sh"

echo "All services down."
