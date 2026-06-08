#!/bin/bash
set -e

OLLAMA_DATA_DIR="${OLLAMA_DATA_DIR:-/mnt/hddpool/models/ollama}"

echo "Creating data directories..."
sudo mkdir -p "$OLLAMA_DATA_DIR"

echo ""
echo "Setup complete. Next steps:"
echo "  1. Copy llm/docker-compose.override.yml.template to llm/docker-compose.override.yml"
echo "  2. Edit if you need a different volume path or GPU access"
echo "  3. Run: ./llm/up.sh"
echo ""
echo "Ollama will be reachable at:"
echo "  - http://ollama:11434          (from other Docker containers on the proxy network)"
echo "  - http://<host-ip>:11434       (from LAN devices)"
echo "  - https://ollama.<hostname>    (via Caddy, once DNS resolves)"
