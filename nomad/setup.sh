#!/bin/bash
set -e

NOMAD_REPO_DIR="${NOMAD_REPO_DIR:-/opt/docker/project-nomad}"
NOMAD_DATA_DIR="${NOMAD_DATA_DIR:-/opt/project-nomad}"

echo "Creating data directories..."
sudo mkdir -p "$NOMAD_DATA_DIR/storage"
sudo mkdir -p "$NOMAD_DATA_DIR/mysql"
sudo mkdir -p "$NOMAD_DATA_DIR/redis"

echo "Cloning Project NOMAD repository..."
sudo mkdir -p "$(dirname "$NOMAD_REPO_DIR")"
if [ -d "$NOMAD_REPO_DIR" ]; then
    echo "Repo already exists at $NOMAD_REPO_DIR, pulling latest..."
    sudo git -C "$NOMAD_REPO_DIR" pull
else
    sudo git clone https://github.com/Crosstalk-Solutions/project-nomad.git "$NOMAD_REPO_DIR"
fi

echo ""
echo "Setup complete. Next steps:"
echo "  1. Copy nomad/docker-compose.override.yml.template to nomad/docker-compose.override.yml"
echo "  2. Edit nomad/docker-compose.override.yml with your URL and any custom paths"
echo "  3. Add NOMAD_APP_KEY, NOMAD_DB_PASSWORD, NOMAD_MYSQL_ROOT_PASSWORD to .env"
echo "  4. Run: ./nomad/up.sh"
