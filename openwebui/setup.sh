#!/bin/bash
set -e

OPENWEBUI_DATA_DIR="${OPENWEBUI_DATA_DIR:-/opt/openwebui}"

echo "Creating data directories..."
sudo mkdir -p "$OPENWEBUI_DATA_DIR/data"
sudo mkdir -p "$OPENWEBUI_DATA_DIR/ollama"

echo ""
echo "Setup complete. Next steps:"
echo "  1. Copy openwebui/docker-compose.override.yml.template to openwebui/docker-compose.override.yml"
echo "  2. Edit openwebui/docker-compose.override.yml with your volume paths"
echo "  3. Add OPENWEBUI_SECRET_KEY to .env (any random string)"
echo "  4. Optionally set OLLAMA_BASE_URL, OPENAI_API_KEY, OPENAI_API_BASE_URL in .env"
echo "  5. Run: ./openwebui/up.sh"
