# GPU Setup for DevContainer

## Current Status

✅ **GPU support is now enabled by default** in the devcontainer configuration. The container is configured with `--gpus=all` in `runArgs`.

## GPU Detection

The container will automatically detect and enable GPU support via the `post-create.sh` script. If GPU is available, you should see:

```
✅ GPU detected:
NVIDIA GeForce RTX 5090, 580.95.05, 12.0
✅ GPU support enabled (sm_120 compute capability supported)
   GPU access verified - NVIDIA Container Toolkit is working correctly
```

## If GPU is Not Available

If you see "❌ ERROR: GPU not available in container" when the container starts:

1. **Check host NVIDIA drivers**:
   ```bash
   nvidia-smi
   ```

2. **Verify NVIDIA Container Toolkit**:
   ```bash
   nvidia-container-cli --version
   docker run --rm --gpus=all ubuntu:22.04 nvidia-smi
   ```

3. **Restart Docker service** (may require sudo):
   ```bash
   sudo systemctl restart docker
   ```

4. **Check NVIDIA Container Runtime config**:
   ```bash
   cat /etc/nvidia-container-runtime/config.toml | grep root
   ```
   The `root` setting should be commented out (use default `/`).

## Configuration

### Current Setup

- **GPU in runArgs**: ✅ Enabled (`--gpus=all`)
- **GPU detection**: ✅ Automatic via post-create script
- **GPU environment vars**: ✅ Set automatically if GPU detected
- **Base image**: `docker4zerocool/ai-template:runtime` (CUDA 12.8.0, sm_120 support)

### Runtime Options

The devcontainer uses `--gpus=all` which is the modern Docker approach. This works with the NVIDIA Container Toolkit when properly configured.

## Troubleshooting

### Error: "libnvidia-ml.so.1: cannot open shared object file"

This error indicates the NVIDIA Container Toolkit can't access the NVIDIA driver libraries. 

**Root Cause (Fixed)**: The `/etc/nvidia-container-runtime/config.toml` had `root = "/run/nvidia/driver"` set, but the directory wasn't properly populated.

**Solution**: Comment out the custom root setting:
```bash
sudo sed -i 's|^root = "/run/nvidia/driver"|#root = "/run/nvidia/driver"|' /etc/nvidia-container-runtime/config.toml
sudo systemctl restart docker
```

### Container Starts But GPU Not Detected

If the container starts but `nvidia-smi` doesn't work inside:

1. Verify the container was started with `--gpus=all` (check `devcontainer.json`)
2. Check host GPU: `nvidia-smi` (on host)
3. Test GPU access: `docker run --rm --gpus=all ubuntu:22.04 nvidia-smi`
4. Restart Docker: `sudo systemctl restart docker`

### Verification Commands

Test GPU access from host:
```bash
# Test with golden image
docker run --rm --gpus=all docker4zerocool/ai-template:runtime nvidia-smi

# Test with standard Ubuntu
docker run --rm --gpus=all ubuntu:22.04 nvidia-smi
```

Test GPU access from devcontainer:
```bash
# Inside the devcontainer
nvidia-smi
python3 -c "import torch; print(f'CUDA: {torch.cuda.is_available()}, Devices: {torch.cuda.device_count()}')"
```

## Recent Fix (Jan 24, 2026)

The NVIDIA Container Toolkit issue was resolved by commenting out the custom `root` setting in `/etc/nvidia-container-runtime/config.toml`. The toolkit now uses the default root (`/`) which correctly locates NVIDIA libraries in `/usr/lib/x86_64-linux-gnu/`.

**What was fixed**:
- Commented out `root = "/run/nvidia/driver"` in config
- Restored default behavior (root = `/`)
- GPU access now works for all containers

## Current Configuration

- **GPU in runArgs**: ✅ Enabled (`--gpus=all`)
- **GPU detection**: ✅ Automatic via post-create script
- **GPU environment vars**: ✅ Set automatically if GPU detected
- **Host NVIDIA Container Toolkit**: ✅ Fixed and working
