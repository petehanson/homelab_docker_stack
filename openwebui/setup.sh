#!/bin/bash
set -e

OPENWEBUI_DATA_DIR="${OPENWEBUI_DATA_DIR:-/opt/openwebui}"

echo "Creating data directories..."
sudo mkdir -p "$OPENWEBUI_DATA_DIR/data"

echo ""
echo "Setup complete. Next steps:"
echo "  1. Copy openwebui/docker-compose.override.yml.template to openwebui/docker-compose.override.yml"
echo "  2. Edit openwebui/docker-compose.override.yml with your volume paths"
echo "  3. Add OPENWEBUI_SECRET_KEY to .env (any random string)"
echo "  4. Optionally set OPENAI_API_KEY, OPENAI_API_BASE_URL in .env"
echo "  5. Ensure the llm stack is running: ./llm/up.sh"
echo "  6. Run: ./openwebui/up.sh"
