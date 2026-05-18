#!/bin/bash
set -e

IMMICH_DATA_DIR="${IMMICH_DATA_DIR:-/opt/immich}"

echo "Creating data directories..."
sudo mkdir -p "$IMMICH_DATA_DIR/uploads"
sudo mkdir -p "$IMMICH_DATA_DIR/model-cache"
sudo mkdir -p "$IMMICH_DATA_DIR/postgres"

echo ""
echo "Setup complete. Next steps:"
echo "  1. Copy immich/docker-compose.override.yml.template to immich/docker-compose.override.yml"
echo "  2. Edit immich/docker-compose.override.yml with your volume paths"
echo "  3. Add IMMICH_DB_PASSWORD to .env"
echo "  4. Run: ./immich/up.sh"
