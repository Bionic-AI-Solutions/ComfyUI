# GPU DevContainer Configuration

## ✅ GPU Support: MANDATORY

This devcontainer **requires** GPU support and is configured to use the NVIDIA Container Runtime.

## Configuration

### Runtime
- Uses `--runtime=nvidia` instead of `--gpus=all` for better compatibility
- Base image: `docker4zerocool/ai-template:runtime` (CUDA 12.8.0, sm_120 support)

### GPU Requirements
- NVIDIA drivers installed on host
- NVIDIA Container Toolkit configured
- Docker daemon restarted after NVIDIA setup

### Verified Working
- ✅ GPU detection (RTX 5090, compute capability 12.0)
- ✅ CUDA 12.8.0 available
- ✅ PyTorch CUDA support
- ✅ All tools (wget, docker, kubectl)

## Test Results

```bash
# GPU Test
nvidia-smi --query-gpu=name,compute_cap --format=csv,noheader
# Output: NVIDIA GeForce RTX 5090, 12.0

# CUDA Test  
python3 -c "import torch; print(f'CUDA: {torch.cuda.is_available()}, Devices: {torch.cuda.device_count()}')"
# Output: CUDA available: True, Devices: 2
```

## If Container Fails to Start

The container will fail to start if GPU is not available (by design - GPU is mandatory).

Check:
1. NVIDIA drivers: `nvidia-smi` (on host)
2. Container Toolkit: `nvidia-container-cli info`
3. Docker runtime: `docker info | grep -i runtime`
4. Restart Docker: `sudo systemctl restart docker`

## Files

- `Dockerfile` - Container image based on golden image
- `devcontainer.json` - DevContainer configuration with GPU support
- `post-create.sh` - Post-creation script that verifies GPU (mandatory check)
