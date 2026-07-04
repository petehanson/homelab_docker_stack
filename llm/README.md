# LLM Stack

Runs [Ollama](https://ollama.com) as a shared inference service accessible to:

- Other Docker containers on the `proxy` network at `http://ollama:11434`
- LAN devices at `http://<host-ip>:11434`
- Externally via Caddy at `https://ollama.<hostname>.duckdns.org`

Model files are stored at `/mnt/hddpool/models/ollama`.

## Setup

```bash
./llm/setup.sh
cp llm/docker-compose.override.yml.template llm/docker-compose.override.yml
# Edit override if needed (volume path, GPU config)
./llm/up.sh
```

## Nvidia GPU Acceleration

Without GPU passthrough, Ollama runs on CPU. On a test with `gemma3:4b`, CPU usage
hit ~600% — enabling the GPU drops this significantly and improves inference speed.

### Host prerequisites

1. Install the Nvidia Container Toolkit:
   ```bash
   # Arch Linux
   sudo pacman -S nvidia-container-toolkit
   sudo nvidia-ctk runtime configure --runtime=docker
   sudo systemctl restart docker
   ```

2. Verify the host driver sees the GPU:
   ```bash
   nvidia-smi
   ```

### Enable GPU in the compose override

In `llm/docker-compose.override.yml`, uncomment the Nvidia deploy block:

```yaml
services:
  ollama:
    volumes:
      - /mnt/hddpool/models/ollama:/root/.ollama
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
```

Restart the stack after:

```bash
./llm/down.sh && ./llm/up.sh
```

## Monitoring GPU usage

Use `nvtop` to watch GPU utilization. If it defaults to the Intel integrated GPU instead
of the Nvidia card, press `F2` in the nvtop UI to open setup and toggle which devices
are displayed. Run `nvtop --help` to check your version for a `-d`/`--device` flag
if you prefer to filter at launch.

`nvidia-smi dmon` is a lightweight alternative for watching utilization per-second.

## Adding models to Ollama

```bash
docker exec -it ollama ollama pull <model>
# e.g.
docker exec -it ollama ollama pull gemma3:4b
```

The RTX 1660 Ti has 6 GB VRAM. Quantized 4b-class models fit comfortably.

## llama.cpp (server-vulkan) model containers

For models that run better served directly by llama.cpp (e.g. large MoE models
on the R9700 Pro via Vulkan), each model gets its own container running
[`ghcr.io/ggml-org/llama.cpp:server-vulkan`](https://github.com/ggml-org/llama.cpp).
`llama-qwen` in `docker-compose.yml` is the example — it mirrors a working
standalone `docker run` invocation, just wired into this stack.

Unlike ollama, these containers do **not** publish port 8080 to the host —
every llama.cpp container listens on the same internal port, so publishing
would collide across models. Instead they join the `proxy` network only and
are reached at:

- `http://llama-qwen:8080` from other containers on the `proxy` network
- `https://llama-qwen.<hostname>.duckdns.org` externally, via Caddy

These models are large and not something you want auto-starting with the
rest of the stack, so they sit behind the `llama` Compose profile — `up.sh`
(and a plain `docker compose up`) skips them. Start one manually:

```bash
cd llm
docker compose -f docker-compose.yml -f docker-compose.override.yml --profile llama up -d llama-qwen
```

Once started, `restart: unless-stopped` keeps it running (including across
host reboots) until you explicitly stop or down it:

```bash
docker compose -f docker-compose.yml -f docker-compose.override.yml stop llama-qwen
# or
docker compose -f docker-compose.yml -f docker-compose.override.yml --profile llama down
```

### Adding another model

1. In `docker-compose.yml`, copy the `llama-qwen` service block, rename the
   service and `container_name` (e.g. `llama-mistral`), and update the
   `command` list's `-m /models/<file>.gguf` and any other llama.cpp flags
   for that model.
2. In `docker-compose.override.yml`, add a matching entry pointing the
   `/models` volume at that model's actual path on disk.
3. In `caddy/Caddyfile`, copy the `@llama_qwen` matcher/handle block, giving
   it a unique matcher name, subdomain, and `reverse_proxy <container>:8080`
   target.
4. Reload Caddy: `docker exec caddy caddy reload --config /etc/caddy/Caddyfile`
5. `./llm/down.sh && ./llm/up.sh` (or `docker compose up -d <service>` from
   `llm/`) to start the new container.

### GPU access

The R9700 Pro only needs `/dev/dri` passed through (Vulkan doesn't use the
ROCm `/dev/kfd` device the way ollama's `rocm` image does), plus membership
in the host's `render` and `video` groups. Confirm the actual GIDs on your
host — they can differ per machine:

```bash
getent group render video
```
