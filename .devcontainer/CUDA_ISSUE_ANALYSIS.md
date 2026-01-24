# CUDA Issue Analysis - Docker Compose vs Direct Docker Run

## Problem

PyTorch cannot detect CUDA in the devcontainer even though:
- ✅ nvidia-smi works
- ✅ NVIDIA devices are mounted (`/dev/nvidia*`)
- ✅ CUDA libraries are accessible
- ✅ Environment variables are set correctly
- ✅ Container uses nvidia runtime or has DeviceRequests

## Key Findings

### Working AI Containers Configuration
- **docker-compose.yml**: `runtime: nvidia` (no deploy section)
- **Actual container**: `Runtime: runc` with `DeviceRequests: {"Driver": "nvidia", "Count": 1}`
- **PyTorch CUDA**: ✅ Works (containers use Triton Server, not direct PyTorch)

### Our DevContainer Configuration
- **docker-compose.yml**: `runtime: nvidia` (tried with/without deploy section)
- **Actual container**: `Runtime: nvidia` with `DeviceRequests: null` or incorrect
- **PyTorch CUDA**: ❌ Fails - "No CUDA GPUs are available"

### Direct Docker Run (WORKS!)
```bash
docker run --gpus=all docker4zerocool/ai-template:runtime ...
```
- **Runtime**: `runc`
- **DeviceRequests**: `{"Driver": "", "Count": -1, ...}` (Driver empty but works!)
- **PyTorch CUDA**: ✅ Works - `torch.cuda.is_available() = True`

## Root Cause

Docker Compose v1.29.2 is not properly handling GPU requests for devcontainers:
1. When using `runtime: nvidia`, Docker Compose keeps it as `nvidia` runtime instead of converting to `runc` + DeviceRequests
2. When using `deploy.resources.reservations.devices`, DeviceRequests is set but PyTorch still cant
