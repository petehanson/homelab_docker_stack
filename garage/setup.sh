#!/bin/bash
set -e

GARAGE_DATA_DIR="${GARAGE_DATA_DIR:-/opt/garage}"

echo "Creating data directories..."
sudo mkdir -p "$GARAGE_DATA_DIR/meta"
sudo mkdir -p "$GARAGE_DATA_DIR/data"

echo ""
echo "Setup complete. Next steps:"
echo "  1. Copy garage/docker-compose.override.yml.template to garage/docker-compose.override.yml"
echo "     and adjust paths if GARAGE_DATA_DIR was overridden above."
echo "  2. Copy garage/garage.toml.template to garage/garage.toml"
echo "     and replace rpc_secret, admin_token, metrics_token with separate outputs of:"
echo "       openssl rand -hex 32"
echo "  3. Run: ./garage/up.sh"
echo "  4. Bootstrap the single-node cluster layout (one-time):"
echo "       docker exec garage /garage status"
echo "       docker exec garage /garage layout assign -z dc1 -c 1 <node_id_from_status>"
echo "       docker exec garage /garage layout apply --version 1"
echo "  5. Create an S3 access key and bucket:"
echo "       docker exec garage /garage key create backup-key"
echo "       docker exec garage /garage bucket create my-bucket"
echo "       docker exec garage /garage bucket allow --read --write --owner my-bucket --key backup-key"
