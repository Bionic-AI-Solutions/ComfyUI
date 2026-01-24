# GPU Setup for DevContainer

## Current Status

The devcontainer is configured to start **without requiring GPU access** initially. This allows the container to start even if there are NVIDIA Container Toolkit issues.

## GPU Detection

The container will automatically detect and enable GPU support if available via the `post-create.sh` script.

## If GPU is Not Available

If you see "⚠️ GPU not available in container" when the container starts, this is normal and the container will still work for development. GPU support can be enabled later.

## Enabling GPU Support

### Option 1: Fix NVIDIA Container Runtime (Recommended)

If GPU access isn't working, try these steps:

1. **Restart Docker service** (may require sudo):
   ```bash
   sudo systemctl restart docker
   ```

2. **Verify NVIDIA Container Toolkit**:
   ```bash
   nvidia-container-cli --version
   ```

3. **Test GPU access**:
   ```bash
   docker run --rm --gpus all nvidia/cuda:12.8.0-base-ubuntu22.04 nvidia-smi
   ```

### Option 2: Enable GPU in Running Container

If the container is already running, you can enable GPU by:

1. **Add GPU to runArgs** in `.devcontainer/devcontainer.json`:
   ```json
   "runArgs": [
     "--gpus=all",
     "--privileged"
   ],
   ```

2. **Rebuild and reopen** the container

### Option 3: Use NVIDIA Runtime Explicitly

You can also try using the nvidia runtime explicitly by adding to `devcontainer.json`:

```json
"runArgs": [
  "--runtime=nvidia",
  "--privileged"
],
```

## Troubleshooting

### Error: "libnvidia-ml.so.1: cannot open shared object file"

This error indicates the NVIDIA Container Toolkit can't access the NVIDIA driver libraries. Solutions:

1. **Check NVIDIA driver**:
   ```bash
   nvidia-smi
   ```

2. **Verify container toolkit**:
   ```bash
   cat /etc/docker/daemon.json | grep nvidia
   ```

3. **Restart Docker**:
   ```bash
   sudo systemctl restart docker
   ```

4. **Check runtime**:
   ```bash
   docker info | grep -i runtime
   ```

### Container Starts But GPU Not Detected

If the container starts but `nvidia-smi` doesn't work inside:

1. The container started without `--gpus=all` (this is by design for reliability)
2. GPU workloads will still work if you manually enable GPU access
3. For development, this is usually fine unless you need GPU during container startup

## Current Configuration

- **GPU in runArgs**: ❌ Removed (for reliability)
- **GPU detection**: ✅ Automatic via post-create script
- **GPU environment vars**: ✅ Set automatically if GPU detected

This configuration prioritizes **container startup reliability** over immediate GPU access. GPU can be enabled once the container is running.
