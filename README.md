# Self-Hosted Apps

A collection of self-hosted services running behind a Caddy reverse proxy with automatic HTTPS via DuckDNS DNS-01 challenge. Each service lives in its own Docker Compose stack and connects to Caddy through a shared Docker network.

## One-Time Setup

Create the shared proxy network on the host:

```bash
docker network create proxy
```

Copy and fill in credentials:

```bash
cp env.template .env
# edit .env with ADMIN_USER, ADMIN_PASSWORD

cp docker-compose.override.yml.template docker-compose.override.yml
# edit docker-compose.override.yml with your DuckDNS HOSTNAME and TOKEN
```

## Starting Each Stack

Each stack is independent. Run from the repo root:

```bash
# Caddy (reverse proxy) — start this first
docker compose up -d

# Pi-hole (DNS / ad blocking)
docker compose --env-file .env -f pihole/docker-compose.yml up -d

# Vaultwarden (password manager)
docker compose --env-file .env -f vaultwarden/docker-compose.yml up -d

# MinIO (object storage)
docker compose --env-file .env -f minio/docker-compose.yml up -d

# Syncthing (file sync)
docker compose -f syncthing/docker-compose.yml up -d
```

## DuckDNS and Caddy

Caddy uses the DuckDNS DNS-01 ACME challenge to obtain valid Let's Encrypt certificates for services running on private IPs. The domain resolves to your local network IP — services are only reachable on the local network (or via VPN).

1. Create an account at duckdns.org and add a subdomain
2. Point the subdomain to your NAS's local IP
3. Set `HOSTNAME` and `TOKEN` in `docker-compose.override.yml`

## Vaultwarden

Vaultwarden data lives in `./vaultwarden/vwdata/`. Accessible at `https://{HOSTNAME}.duckdns.org/vaultwarden`.
