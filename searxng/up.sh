#!/bin/bash
set -e
cd "$(dirname "$0")"
docker compose --env-file ../.env -f docker-compose.yml up -d
