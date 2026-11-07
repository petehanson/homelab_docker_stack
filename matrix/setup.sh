#!/bin/bash
set -e
cd "$(dirname "$0")"

MATRIX_DATA_DIR="${MATRIX_DATA_DIR:-/opt/matrix}"
ENV_FILE="../.env"

env_get() {
    grep -E "^$1=" "$ENV_FILE" | tail -n 1 | cut -d= -f2-
}

if [ ! -f "$ENV_FILE" ]; then
    echo "ERROR: $ENV_FILE not found. Copy env.template to .env first." >&2
    exit 1
fi

HOSTNAME_VAL="$(env_get HOSTNAME)"
DB_PASSWORD="$(env_get MATRIX_DB_PASSWORD)"

if [ -z "$HOSTNAME_VAL" ] || [ "$HOSTNAME_VAL" = "yourhostname" ]; then
    echo "ERROR: HOSTNAME is unset or still the placeholder in $ENV_FILE" >&2
    exit 1
fi
if [ -z "$DB_PASSWORD" ] || [ "$DB_PASSWORD" = "your_matrix_db_password" ]; then
    echo "ERROR: MATRIX_DB_PASSWORD is unset or still the placeholder in $ENV_FILE" >&2
    echo "       Generate one with: openssl rand -hex 32" >&2
    exit 1
fi
# The password is embedded in a single-quoted YAML string and a sed replacement.
if [[ "$DB_PASSWORD" =~ [\'\\\|\&] ]]; then
    echo "ERROR: MATRIX_DB_PASSWORD must not contain ' \\ | or &. Use: openssl rand -hex 32" >&2
    exit 1
fi

SERVER_NAME="$HOSTNAME_VAL.duckdns.org"

echo "Creating data directories..."
sudo mkdir -p "$MATRIX_DATA_DIR/synapse"
sudo mkdir -p "$MATRIX_DATA_DIR/postgres"

if [ -f "$MATRIX_DATA_DIR/synapse/homeserver.yaml" ]; then
    echo "Synapse config already exists at $MATRIX_DATA_DIR/synapse/homeserver.yaml, skipping generate."
else
    echo "Generating Synapse config and signing key for server_name $SERVER_NAME..."
    docker run --rm \
        -v "$MATRIX_DATA_DIR/synapse:/data" \
        -e SYNAPSE_SERVER_NAME="$SERVER_NAME" \
        -e SYNAPSE_REPORT_STATS=no \
        matrixdotorg/synapse:latest generate
fi

render() {
    local template="$1" out="$2"
    if [ -f "$out" ]; then
        echo "$out already exists, leaving it alone."
        return
    fi
    sed -e "s|__HOSTNAME__|$HOSTNAME_VAL|g" \
        -e "s|__MATRIX_DB_PASSWORD__|$DB_PASSWORD|g" \
        "$template" > "$out"
    echo "Wrote $out"
}

render homeserver.local.yaml.template homeserver.local.yaml
render element-config.json.template element-config.json

echo ""
echo "Setup complete. Next steps:"
echo "  1. Copy matrix/docker-compose.override.yml.template to matrix/docker-compose.override.yml"
echo "     (edit volume paths if not using $MATRIX_DATA_DIR)"
echo "  2. Reload Caddy: docker exec caddy caddy reload --config /etc/caddy/Caddyfile"
echo "  3. Run: ./matrix/up.sh"
echo "  4. Create your admin user:"
echo "     docker exec -it matrix_synapse register_new_matrix_user -c /data/homeserver.yaml --admin http://localhost:8008"
echo "  5. Open https://element.$SERVER_NAME and sign in"
