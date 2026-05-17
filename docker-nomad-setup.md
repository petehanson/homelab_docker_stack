# Docker Multi-Stack Setup with Caddy + Project NOMAD

## Summary

The question was how to best add larger multi-container projects (like Project NOMAD) to a NAS that already runs a main `docker-compose.yml` with Caddy as a reverse proxy.

**The answer: keep large projects in their own separate compose stacks, and connect them to Caddy via a shared external Docker network.**

Merging everything into one compose file creates a fragile monolith — one `docker compose down` affects all services, updates to one project risk destabilizing others, and the file becomes unmanageable. Project NOMAD itself signals this intent by declaring `name: project-nomad` at the top of its compose file.

---

## Implementation Steps

### Step 1: Create the Shared Proxy Network

Run this once on the NAS host. This network will be the bridge between Caddy and any services in separate stacks that need to be publicly reachable.

```bash
docker network create proxy
```

---

### Step 2: Update Your Main `docker-compose.yml`

Declare the `proxy` network as external and ensure Caddy is attached to it.

```yaml
services:
  caddy:
    image: caddy:latest
    container_name: caddy
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - caddy_data:/data
      - caddy_config:/config
    networks:
      - proxy
      # add any other internal networks Caddy needs here

  # ... your other services

networks:
  proxy:
    external: true
```

---

### Step 3: Clone Project NOMAD

Clone the full repository — not just the compose file — because the `updater` service has a local build context (`./sidecar-updater/Dockerfile`) that must be present.

```bash
cd /opt/docker
git clone https://github.com/Crosstalk-Solutions/project-nomad.git
cd project-nomad/install
```

---

### Step 4: Modify the NOMAD Compose File

Edit `management_compose.yaml` to:

1. Add the external `proxy` network and an internal-only `nomad_internal` network.
2. Attach only `admin` and `dozzle` to `proxy` (Caddy doesn't need to see MySQL or Redis).
3. **Remove host port bindings** from `admin`, `dozzle`, `mysql`, and `redis` — Caddy handles ingress; MySQL and Redis should never be exposed to the host.

```yaml
name: project-nomad

networks:
  proxy:
    external: true
  nomad_internal:
    driver: bridge

services:
  admin:
    image: ghcr.io/crosstalk-solutions/project-nomad:latest
    pull_policy: always
    container_name: nomad_admin
    restart: unless-stopped
    extra_hosts:
      - "host.docker.internal:host-gateway"
    # No ports: block — Caddy reverse proxies this
    volumes:
      - /opt/project-nomad/storage:/app/storage
      - /tmp/nomad-disk-info.json:/app/storage/nomad-disk-info.json
      - /var/run/docker.sock:/var/run/docker.sock
      - ./entrypoint.sh:/usr/local/bin/entrypoint.sh
      - ./wait-for-it.sh:/usr/local/bin/wait-for-it.sh
      - nomad-update-shared:/app/update-shared
    environment:
      - NODE_ENV=production
      - PORT=8080
      - LOG_LEVEL=debug
      - APP_KEY=your_secure_app_key
      - HOST=0.0.0.0
      - URL=https://nomad.yourdomain.com
      - DB_HOST=mysql
      - DB_PORT=3306
      - DB_DATABASE=nomad
      - DB_USER=nomad_user
      - DB_PASSWORD=your_secure_db_password
      - DB_NAME=nomad
      - DB_SSL=false
      - REDIS_HOST=redis
      - REDIS_PORT=6379
    depends_on:
      mysql:
        condition: service_healthy
      redis:
        condition: service_healthy
    entrypoint: ["/usr/local/bin/entrypoint.sh"]
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/api/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - proxy
      - nomad_internal

  dozzle:
    image: amir20/dozzle:v10.0
    container_name: nomad_dozzle
    restart: unless-stopped
    # No ports: block — Caddy reverse proxies this
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - DOZZLE_ENABLE_ACTIONS=true
      - DOZZLE_ENABLE_SHELL=true
    networks:
      - proxy
      - nomad_internal

  mysql:
    image: mysql:8.0
    container_name: nomad_mysql
    restart: unless-stopped
    # No ports: block — must not be exposed to host
    environment:
      - MYSQL_ROOT_PASSWORD=your_secure_root_password
      - MYSQL_DATABASE=nomad
      - MYSQL_USER=nomad_user
      - MYSQL_PASSWORD=your_secure_db_password
    volumes:
      - /opt/project-nomad/mysql:/var/lib/mysql
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - nomad_internal

  redis:
    image: redis:7-alpine
    container_name: nomad_redis
    restart: unless-stopped
    # No ports: block — must not be exposed to host
    volumes:
      - /opt/project-nomad/redis:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - nomad_internal

  updater:
    build:
      context: ./sidecar-updater
      dockerfile: Dockerfile
    container_name: nomad_updater
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /opt/project-nomad:/opt/project-nomad
      - nomad-update-shared:/shared
    networks:
      - nomad_internal

volumes:
  nomad-update-shared:
    driver: local
```

---

### Step 5: Create Required Host Directories

```bash
sudo mkdir -p /opt/project-nomad/storage
sudo mkdir -p /opt/project-nomad/mysql
sudo mkdir -p /opt/project-nomad/redis
```

---

### Step 6: Add Caddy Reverse Proxy Entries

In your `Caddyfile`, add entries for the NOMAD admin UI and Dozzle. Because both services share the `proxy` Docker network with Caddy, they're reachable by container name.

```
nomad.yourdomain.com {
    reverse_proxy nomad_admin:8080
}

dozzle.yourdomain.com {
    reverse_proxy nomad_dozzle:8080
}
```

Reload Caddy after saving:

```bash
docker exec caddy caddy reload --config /etc/caddy/Caddyfile
```

---

### Step 7: Start the NOMAD Stack

```bash
cd /opt/docker/project-nomad/install
docker compose -f management_compose.yaml up -d
```

---

### Step 8: Verify

```bash
# Check all NOMAD containers are running and healthy
docker compose -f management_compose.yaml ps

# Confirm nomad_admin and nomad_dozzle are on the proxy network
docker network inspect proxy | grep -A3 "nomad"

# Tail logs if anything looks off
docker compose -f management_compose.yaml logs -f admin
```

---

## Directory Layout (Recommended)

```
/opt/docker/
  main/
    docker-compose.yml       # Caddy + your core services
    Caddyfile
  project-nomad/
    install/
      management_compose.yaml
      entrypoint.sh
      wait-for-it.sh
      sidecar-updater/
        Dockerfile
        ...
```

---

## General Rule for Future Projects

| Scenario | Approach |
|---|---|
| Single container, simple service | Add to main compose |
| Multi-container project with its own DB/cache | Separate compose stack |
| Needs Caddy routing | Attach public-facing containers to `proxy` network |
| Internal services (DB, cache, queues) | Internal-only network, never on `proxy` |

For each new separate stack, the pattern is always the same: create an internal network for inter-service communication, attach only the web-facing service(s) to `proxy`, and add a Caddy entry pointing to the container name and port.
