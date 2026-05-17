# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A collection of self-hosted services, each in its own Docker Compose stack, all routed through a single Caddy reverse proxy using a shared external Docker network named `proxy`. Caddy obtains valid Let's Encrypt certs via DuckDNS DNS-01 challenge for services running on private IPs.

## Stack Layout

| Stack | Compose file | Services |
|---|---|---|
| Core | `./docker-compose.yml` | Caddy (owns the `proxy` network) |
| Pi-hole | `./pihole/docker-compose.yml` | pihole |
| Vaultwarden | `./vaultwarden/docker-compose.yml` | vaultwarden |
| MinIO | `./minio/docker-compose.yml` | minio |
| Syncthing | `./syncthing/docker-compose.yml` | syncthing |

## Common Commands

```bash
# Start core (Caddy) — always first
docker compose up -d

# Start a service stack
docker compose --env-file .env -f pihole/docker-compose.yml up -d
docker compose --env-file .env -f vaultwarden/docker-compose.yml up -d
docker compose --env-file .env -f minio/docker-compose.yml up -d
docker compose -f syncthing/docker-compose.yml up -d

# Rebuild Caddy after Caddyfile or Dockerfile changes
docker compose build caddy && docker compose up -d caddy

# Reload Caddy config without restart
docker exec caddy caddy reload --config /etc/caddy/Caddyfile

# View logs
docker compose logs -f caddy
docker compose -f pihole/docker-compose.yml logs -f
```

## Configuration Setup

Two files are gitignored and must be created from templates before first run:

- `.env` — copy from `env.template`; provides `ADMIN_USER`, `ADMIN_PASSWORD` to all stacks via `--env-file`
- `docker-compose.override.yml` — copy from `docker-compose.override.yml.template`; sets `HOSTNAME` and DuckDNS `TOKEN` for Caddy

## Architecture

- **Caddy** (`caddy/`) — custom-built image with the `caddy-dns/duckdns` plugin. `Caddyfile` uses `{$HOSTNAME}` and `{$TOKEN}` from the override file. Routes `/vaultwarden*` by path and `pihole.*`, `minio.*` as subdomains. All traffic HTTPS.
- **Shared `proxy` network** — created once on the host (`docker network create proxy`). Caddy defines it; all other stacks join it as `external: true`. Caddy reaches backend containers by container name.
- **Syncthing** — uses `network_mode: host` for local device discovery; not on the `proxy` network. UI available on host port 8384.
- **Secrets** — `.env` at repo root holds shared credentials. Sub-stacks load it with `--env-file .env`. Never hardcoded in compose files.
- **Data dirs** — each service stores persistent data in its own subdirectory (`./vaultwarden/vwdata/`, `./minio/data/`, etc.). Directories tracked in git via `.empty` placeholder files.

## Adding a New Service

1. Create `./servicename/docker-compose.yml` with the service joining `proxy` as external
2. Add a Caddyfile entry pointing to the container name and port
3. Reload Caddy: `docker exec caddy caddy reload --config /etc/caddy/Caddyfile`
4. Start the stack: `docker compose --env-file ../.env -f servicename/docker-compose.yml up -d`

For multi-container projects (e.g., app + database): expose only the web-facing container on `proxy`; put DB/cache on an internal-only network within that stack.
