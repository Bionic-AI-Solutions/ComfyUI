# GPU DevContainer

This devcontainer is configured for GPU-accelerated development with NVIDIA CUDA support, Docker-in-Docker, and Kubernetes access.

## Features

- **Base Image**: `docker4zerocool/ai-template:runtime`
  - CUDA 12.8.0
  - NVIDIA GPU support
  - Compute capability 12.0 (sm_120) support
  - Pre-configured Python environment with conda (wan22 environment)

- **Tools Included**:
  - `wget` - File download utility
  - `docker` - Docker CLI (connects to host Docker daemon)
  - `kubectl` - Kubernetes CLI (v1.35.0)
  - Standard development tools (git, vim, curl, etc.)

- **Mounted Resources**:
  - Host workspace folder (mounted for hot reload)
  - Host Docker socket (`/var/run/docker.sock`) for Docker-in-Docker
  - Kubernetes config (`~/.kube/config`) from host
  - MCP configuration (`~/.cursor/mcp.json`) from host
  - Cursor rules directory (`~/.cursor/rules`) from host

## Usage

1. Open the workspace in VS Code or Cursor
2. When prompted, click "Reopen in Container" or use the command palette:
   - `Dev Containers: Reopen in Container`
3. The container will build and start automatically

## Configuration

### Environment Variables

The devcontainer sets the following environment variables:
- `CUDA_VISIBLE_DEVICES=all`
- `NVIDIA_VISIBLE_DEVICES=all`
- `NVIDIA_DRIVER_CAPABILITIES=compute,utility`
- `KUBECONFIG=/home/devuser/.kube/config`
- `DOCKER_HOST=unix:///var/run/docker.sock`

### User

The container runs as `devuser` with sudo privileges and docker group membership.

### Python Environment

The default Python interpreter is located at:
```
/opt/conda/envs/wan22/bin/python
```

To activate the conda environment:
```bash
conda activate wan22
```

## Verifying Setup

After the container starts, verify the setup:

```bash
# Check CUDA
nvidia-smi

# Check Docker (should connect to host)
docker ps

# Check kubectl
kubectl version --client
kubectl get nodes

# Check wget
wget --version
```

## Hot Reload Support

The workspace folder is mounted (not copied) from the host, so any changes you make on the host or in the container will be immediately visible in both places. This enables hot reload functionality for development.

## Troubleshooting

### Docker Permission Issues

If you encounter permission issues with Docker:
```bash
sudo chmod 666 /var/run/docker.sock
```

### Kubernetes Access Issues

If kubectl can't access the cluster:
1. Verify the kubeconfig is mounted: `ls -la ~/.kube/config`
2. Check permissions: `chmod 600 ~/.kube/config`
3. Verify KUBECONFIG env var: `echo $KUBECONFIG`

### GPU Not Available

If GPU is not detected:
1. Ensure the host has NVIDIA drivers installed
2. Verify nvidia-container-toolkit is installed on the host
3. Check that `--gpus=all` is in the runArgs (already configured)

## Build Test

To test the Docker build manually:
```bash
cd /home/skadam/git/gpu-devcontainer
docker build -t gpu-devcontainer-test -f .devcontainer/Dockerfile .
```
