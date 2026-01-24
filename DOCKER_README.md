# ComfyUI Docker Setup

This repository contains Docker configurations to run ComfyUI in a containerized environment with support for both GPU (NVIDIA CUDA) and CPU modes.

## Features

- **GPU Support**: Uses golden image `docker4zerocool/ai-template:runtime` with CUDA 12.8.0
- **CPU Support**: Standalone CPU-only version for systems without GPU
- **Pre-configured**: PyTorch with CUDA support already included in GPU image
- **ComfyUI Manager**: Pre-installed for easy custom node management
- **Volume Mounts**: Persistent storage for models, inputs, outputs, and custom nodes

## Prerequisites

### For GPU Mode:
- NVIDIA GPU with appropriate drivers installed
- NVIDIA Container Toolkit or nvidia-docker2 installed
- Docker with GPU support configured

### For CPU Mode:
- Docker installed (no GPU required)

## Quick Start

### 1. Clone and Navigate
```bash
cd /workspace
```

### 2. Create Environment File (Optional)
```bash
cp .env.example .env
# Edit .env to customize port if needed (default: 8188)
```

### 3. Start ComfyUI

#### GPU Mode (Recommended if you have NVIDIA GPU):
```bash
docker-compose up -d comfyui-gpu
```

#### CPU Mode:
```bash
docker-compose up -d comfyui-cpu
```

### 4. Access ComfyUI
Open your browser and navigate to:
```
http://localhost:8188
```

## Docker Compose Services

### `comfyui-gpu`
- **Base Image**: `docker4zerocool/ai-template:runtime`
- **CUDA**: 12.8.0
- **PyTorch**: 2.9.0+cu128 (pre-installed)
- **Runtime**: nvidia
- **Port**: 8188 (configurable via `.env`)

### `comfyui-cpu`
- **Base Image**: `python:3.12-slim`
- **PyTorch**: CPU-only version
- **Port**: 8188 (configurable via `.env`)

## Volume Mounts

The following directories are mounted as volumes for persistence:

- `./ComfyUI/models` - Model files (checkpoints, VAEs, LoRAs, etc.)
- `./ComfyUI/input` - Input images
- `./ComfyUI/output` - Generated images
- `./ComfyUI/custom_nodes` - Custom nodes
- `./ComfyUI/user` - User-specific data (optional)

## Building Images

### Build GPU Image:
```bash
docker build --target gpu -t comfyui-gpu:latest -f Dockerfile .
```

### Build CPU Image:
```bash
docker build --target cpu -t comfyui-cpu:latest -f Dockerfile .
```

## Running with Docker (without docker-compose)

### GPU Mode:
```bash
docker run -d \
  --name comfyui-gpu \
  --runtime=nvidia \
  --gpus=all \
  -p 8188:8188 \
  -v $(pwd)/ComfyUI/models:/app/ComfyUI/models \
  -v $(pwd)/ComfyUI/input:/app/ComfyUI/input \
  -v $(pwd)/ComfyUI/output:/app/ComfyUI/output \
  -v $(pwd)/ComfyUI/custom_nodes:/app/ComfyUI/custom_nodes \
  -e CUDA_VISIBLE_DEVICES=all \
  -e NVIDIA_VISIBLE_DEVICES=all \
  -e NVIDIA_DRIVER_CAPABILITIES=compute,utility \
  comfyui-gpu:latest
```

### CPU Mode:
```bash
docker run -d \
  --name comfyui-cpu \
  -p 8188:8188 \
  -v $(pwd)/ComfyUI/models:/app/ComfyUI/models \
  -v $(pwd)/ComfyUI/input:/app/ComfyUI/input \
  -v $(pwd)/ComfyUI/output:/app/ComfyUI/output \
  -v $(pwd)/ComfyUI/custom_nodes:/app/ComfyUI/custom_nodes \
  comfyui-cpu:latest
```

## Verifying GPU Support

To verify that CUDA is working in the GPU container:

```bash
# Check GPU availability
docker exec comfyui-gpu nvidia-smi

# Check PyTorch CUDA
docker exec comfyui-gpu /opt/conda/envs/wan22/bin/python -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}, Devices: {torch.cuda.device_count()}')"
```

Expected output:
```
CUDA available: True, Devices: 1
```

## Stopping Services

```bash
# Stop GPU service
docker-compose stop comfyui-gpu

# Stop CPU service
docker-compose stop comfyui-cpu

# Stop and remove containers
docker-compose down
```

## Logs

View container logs:
```bash
# GPU logs
docker-compose logs -f comfyui-gpu

# CPU logs
docker-compose logs -f comfyui-cpu
```

## Troubleshooting

### GPU Not Detected

1. **Check NVIDIA drivers on host**:
   ```bash
   nvidia-smi
   ```

2. **Verify NVIDIA Container Toolkit**:
   ```bash
   nvidia-container-cli info
   ```

3. **Check Docker runtime**:
   ```bash
   docker info | grep -i runtime
   ```

4. **Restart Docker** (if needed):
   ```bash
   sudo systemctl restart docker
   ```

### Port Already in Use

If port 8188 is already in use, change it in `.env`:
```bash
COMFYUI_PORT=8189
```

Then restart the service:
```bash
docker-compose up -d comfyui-gpu
```

### Permission Issues

If you encounter permission issues with mounted volumes:
```bash
# Fix permissions for ComfyUI directories
sudo chown -R $USER:$USER ComfyUI/models ComfyUI/input ComfyUI/output ComfyUI/custom_nodes
```

### Container Won't Start

Check logs for errors:
```bash
docker-compose logs comfyui-gpu
```

Common issues:
- Missing models directory (will be created automatically)
- Port conflicts
- GPU runtime not available (for GPU mode)

## Model Management

### Adding Models

Place your models in the appropriate directories:

- **Checkpoints**: `ComfyUI/models/checkpoints/`
- **VAEs**: `ComfyUI/models/vae/`
- **LoRAs**: `ComfyUI/models/loras/`
- **Embeddings**: `ComfyUI/models/embeddings/`
- **ControlNet**: `ComfyUI/models/controlnet/`
- **Upscale Models**: `ComfyUI/models/upscale_models/`

### Using ComfyUI Manager

ComfyUI Manager is pre-installed and enabled. Access it through the ComfyUI web interface to:
- Install custom nodes
- Update ComfyUI
- Manage models
- Install workflows

## Environment Variables

You can customize the following via `.env`:

- `COMFYUI_PORT` - Port to expose ComfyUI (default: 8188)

Additional environment variables can be added to `docker-compose.yml` if needed.

## Health Checks

Both services include health checks that verify the ComfyUI server is responding:

```bash
# Check health status
docker ps
# Look for "healthy" status

# Manual health check
curl http://localhost:8188/
```

## Updating

To update ComfyUI:

1. Pull latest changes:
   ```bash
   git pull
   ```

2. Rebuild images:
   ```bash
   docker-compose build --no-cache comfyui-gpu
   # or
   docker-compose build --no-cache comfyui-cpu
   ```

3. Restart service:
   ```bash
   docker-compose up -d comfyui-gpu
   ```

## Support

For ComfyUI-specific issues, refer to:
- [ComfyUI GitHub](https://github.com/comfyanonymous/ComfyUI)
- [ComfyUI Documentation](https://github.com/comfyanonymous/ComfyUI#readme)

For Docker-specific issues, check:
- Docker logs: `docker-compose logs`
- Container status: `docker ps -a`
- Health checks: `docker inspect <container-name> | grep -A 10 Health`
