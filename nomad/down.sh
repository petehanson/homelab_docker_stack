#!/bin/bash
set -e
cd "$(dirname "$0")"

mapfile -t NOMAD_CONTAINERS < <(docker ps --filter "name=nomad_" --format "{{.Names}}")
if [ ${#NOMAD_CONTAINERS[@]} -gt 0 ]; then
  echo "Stopping nomad-managed containers: ${NOMAD_CONTAINERS[*]}"
  docker stop "${NOMAD_CONTAINERS[@]}"
fi

docker compose -f docker-compose.yml down
