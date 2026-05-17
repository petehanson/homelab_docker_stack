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
# Bring everything up
./up.sh

# Individual services (run from anywhere)
./caddy/up.sh        ./caddy/down.sh
./pihole/up.sh       ./pihole/down.sh
./vaultwarden/up.sh  ./vaultwarden/down.sh
./minio/up.sh        ./minio/down.sh
./syncthing/up.sh    ./syncthing/down.sh

# Rebuild Caddy after Caddyfile or Dockerfile changes
docker compose build caddy && docker compose up -d caddy

# Reload Caddy config without restart
docker exec caddy caddy reload --config /etc/caddy/Caddyfile

# View logs
docker compose logs -f caddy
docker compose -f pihole/docker-compose.yml logs -f
```

## Configuration Setup

Files that are gitignored and must be created before first run:

- `.env` — copy from `env.template`; provides `ADMIN_USER`, `ADMIN_PASSWORD` to all stacks
- `docker-compose.override.yml` — copy from `docker-compose.override.yml.template`; sets `HOSTNAME` and DuckDNS `TOKEN` for Caddy
- `vaultwarden/docker-compose.override.yml` — host-specific volume paths for vaultwarden
- `minio/docker-compose.override.yml` — host-specific volume paths for minio
- `syncthing/docker-compose.override.yml` — host-specific volume paths for syncthing

The per-service override files follow the same pattern — only override what differs on the host machine (typically volume paths).

## Architecture

- **Caddy** (`caddy/`) — custom-built image with the `caddy-dns/duckdns` plugin. `Caddyfile` uses `{$HOSTNAME}` and `{$TOKEN}` from the override file. Routes `/vaultwarden*` by path and `pihole.*`, `minio.*` as subdomains. All traffic HTTPS.
- **Caddyfile snippet** — TLS config is defined once in the `(duckdns_tls)` snippet and imported into each site block. When adding a new service, `import duckdns_tls` instead of repeating the `tls` block.
- **`resolvers 8.8.8.8` in the TLS config** — Caddy's DNS-01 propagation check normally queries authoritative nameservers directly using Docker's internal resolver (`127.0.0.11`), which times out reaching external nameservers. Setting `resolvers 8.8.8.8` routes the propagation check through a public recursive resolver instead. Do not remove this.
- **Shared `proxy` network** — created once on the host (`docker network create proxy`). All stacks declare it as `external: true`. Caddy reaches backend containers by container name across stacks.
- **Syncthing** — uses `network_mode: host` for local device discovery; not on the `proxy` network. UI available on host port 8384.
- **Secrets** — `.env` at repo root holds shared credentials. Per-service scripts pass it via `--env-file ../.env`. Never hardcoded in compose files.
- **Data dirs** — each service stores persistent data in its own subdirectory. Tracked in git via `.empty` placeholder files; actual data is gitignored.

## Adding a New Service

1. Create `./servicename/docker-compose.yml` joining `proxy` as external
2. Add a site block to `caddy/Caddyfile` using `import duckdns_tls`
3. Reload Caddy: `docker exec caddy caddy reload --config /etc/caddy/Caddyfile`
4. Create `./servicename/up.sh` and `./servicename/down.sh` following the pattern of existing scripts
5. Add the service to the root `./up.sh`

For multi-container projects: expose only the web-facing container on `proxy`; put DB/cache on an internal-only network within that stack.
