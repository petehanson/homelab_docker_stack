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

## Adding models

```bash
docker exec -it ollama ollama pull <model>
# e.g.
docker exec -it ollama ollama pull gemma3:4b
```

The RTX 1660 Ti has 6 GB VRAM. Quantized 4b-class models fit comfortably.
