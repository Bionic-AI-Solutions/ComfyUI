# ComfyUI Kubernetes Deployment Guide

Complete Kubernetes deployment for ComfyUI with GPU support, based on the golden AI template (`docker4zerocool/ai-template:runtime`).

## What's Included

### Docker Configuration
- [Dockerfile.k8s](Dockerfile.k8s) - Production-ready Dockerfile using golden AI template with CUDA 12.8.0

### Kubernetes Manifests (in `k8s/` directory)
- [namespace.yaml](k8s/namespace.yaml) - Dedicated namespace for ComfyUI
- [configmap.yaml](k8s/configmap.yaml) - Environment variables configuration
- [pvc.yaml](k8s/pvc.yaml) - Persistent storage for models, inputs, outputs, custom nodes
- [deployment.yaml](k8s/deployment.yaml) - Main deployment with GPU support
- [service.yaml](k8s/service.yaml) - ClusterIP and LoadBalancer services
- [ingress.yaml](k8s/ingress.yaml) - Ingress configuration for `confy.baisoln.com`
- [kustomization.yaml](k8s/kustomization.yaml) - Kustomize configuration for easy deployment

### Helper Scripts
- [build-and-push.sh](k8s/build-and-push.sh) - Build and push Docker image
- [deploy.sh](k8s/deploy.sh) - Deploy, manage, and troubleshoot the Kubernetes deployment

## Quick Start

### 1. Build and Push Docker Image

```bash
cd k8s

# Option 1: Build and push to Docker Hub
./build-and-push.sh yourusername/comfyui-k8s latest

# Option 2: Build and push to private registry
./build-and-push.sh registry.yourcompany.com/comfyui-k8s v1.0

# Option 3: Build and push to GCR
./build-and-push.sh gcr.io/your-project/comfyui-k8s latest
```

### 2. Update Image Reference

Edit `k8s/kustomization.yaml`:

```yaml
images:
  - name: comfyui-k8s
    newName: yourusername/comfyui-k8s  # Your actual registry
    newTag: latest
```

### 3. Configure GPU Node Selector

Check your GPU node labels:

```bash
kubectl get nodes --show-labels | grep gpu
```

Update `k8s/deployment.yaml` if needed:

```yaml
nodeSelector:
  nvidia.com/gpu: "true"  # Common label
  # Or use your cluster-specific label
```

### 4. Deploy to Kubernetes

```bash
cd k8s

# Deploy everything
./deploy.sh deploy

# Or manually
kubectl apply -f namespace.yaml
kubectl apply -f configmap.yaml
kubectl apply -f pvc.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f ingress.yaml
```

### 5. Check Status

```bash
# Check deployment status
./deploy.sh status

# Follow logs
./deploy.sh logs

# Verify GPU
./deploy.sh gpu-check
```

### 6. Access ComfyUI

#### Option A: Port Forward (Development)
```bash
./deploy.sh port-forward
# Access at http://localhost:8188
```

#### Option B: LoadBalancer (Production)
```bash
kubectl get svc -n comfyui comfyui-external
# Access at http://<EXTERNAL-IP>:8188
```

#### Option C: Ingress (Recommended)
```bash
# Make sure your DNS points to your ingress controller
# Access at http://confy.baisoln.com
```

## Deployment Architecture

```
┌─────────────────────────────────────────────────────┐
│                    Kubernetes                        │
│                                                      │
│  ┌────────────────────────────────────────────┐    │
│  │         Namespace: comfyui                  │    │
│  │                                              │    │
│  │  ┌──────────────────────────────────────┐  │    │
│  │  │  Ingress: confy.baisoln.com          │  │    │
│  │  │  (nginx ingress controller)          │  │    │
│  │  └──────────┬───────────────────────────┘  │    │
│  │             │                               │    │
│  │  ┌──────────▼───────────────────────────┐  │    │
│  │  │  Service: comfyui (ClusterIP)        │  │    │
│  │  │  Port: 8188                           │  │    │
│  │  └──────────┬───────────────────────────┘  │    │
│  │             │                               │    │
│  │  ┌──────────▼───────────────────────────┐  │    │
│  │  │  Deployment: comfyui                 │  │    │
│  │  │  - 1 replica (GPU workload)          │  │    │
│  │  │  - nvidia.com/gpu: 1                 │  │    │
│  │  │  - CUDA 12.8.0 (golden template)     │  │    │
│  │  │                                       │  │    │
│  │  │  Pod:                                 │  │    │
│  │  │  ┌─────────────────────────────┐     │  │    │
│  │  │  │ ComfyUI Container           │     │  │    │
│  │  │  │ - GPU: NVIDIA Tesla/etc     │     │  │    │
│  │  │  │ - Memory: 8-16Gi            │     │  │    │
│  │  │  │ - CPU: 2-4 cores            │     │  │    │
│  │  │  └─────────────────────────────┘     │  │    │
│  │  └──────────┬───────────────────────────┘  │    │
│  │             │                               │    │
│  │  ┌──────────▼───────────────────────────┐  │    │
│  │  │  Persistent Volume Claims            │  │    │
│  │  │  - models (100Gi)                    │  │    │
│  │  │  - input (10Gi)                      │  │    │
│  │  │  - output (50Gi)                     │  │    │
│  │  │  - custom-nodes (10Gi)               │  │    │
│  │  │  - user-data (5Gi)                   │  │    │
│  │  └──────────────────────────────────────┘  │    │
│  └──────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
```

## Key Features

### GPU Support
- Uses golden AI template: `docker4zerocool/ai-template:runtime`
- CUDA 12.8.0 pre-installed
- PyTorch 2.9.0+cu128 with CUDA support
- Proper GPU resource allocation and node selection
- NVIDIA entrypoint for proper CUDA initialization

### Storage
- **Models PVC (100Gi)**: Stores all AI models (checkpoints, VAEs, LoRAs, etc.)
- **Input PVC (10Gi)**: Input images and files
- **Output PVC (50Gi)**: Generated images and outputs
- **Custom Nodes PVC (10Gi)**: Custom ComfyUI nodes
- **User Data PVC (5Gi)**: User workflows and settings

### High Availability
- Health checks (liveness, readiness, startup probes)
- Automatic pod restart on failure
- Resource limits to prevent resource exhaustion
- Session affinity for WebSocket connections

### Security
- Dedicated namespace
- ConfigMap for environment variables
- Optional: Non-root user (commented in Dockerfile)
- Optional: TLS/HTTPS via Ingress with cert-manager

### Networking
- **ClusterIP Service**: Internal cluster access
- **LoadBalancer Service**: External cloud load balancer access
- **NodePort Service**: Alternative external access (commented)
- **Ingress**: Domain-based access at `confy.baisoln.com`

## Configuration

### Adjust Storage Sizes

Edit `k8s/pvc.yaml`:

```yaml
spec:
  resources:
    requests:
      storage: 200Gi  # Increase model storage
```

### Adjust Resource Limits

Edit `k8s/deployment.yaml`:

```yaml
resources:
  requests:
    memory: "16Gi"   # More memory
    cpu: "4"         # More CPU
    nvidia.com/gpu: "2"  # Multiple GPUs
  limits:
    memory: "32Gi"
    cpu: "8"
    nvidia.com/gpu: "2"
```

### Enable HTTPS/TLS

Edit `k8s/ingress.yaml` and uncomment TLS section:

```yaml
annotations:
  cert-manager.io/cluster-issuer: "letsencrypt-prod"  # Uncomment

tls:  # Uncomment
- hosts:
  - confy.baisoln.com
  secretName: comfyui-tls-cert
```

Make sure cert-manager is installed in your cluster.

## Helper Script Commands

The `deploy.sh` script provides convenient commands:

```bash
# Deploy ComfyUI
./deploy.sh deploy

# Check status (pods, services, PVCs, GPU)
./deploy.sh status

# View logs (follow mode)
./deploy.sh logs

# Port forward to localhost:8188
./deploy.sh port-forward

# Verify GPU availability
./deploy.sh gpu-check

# Open shell in ComfyUI pod
./deploy.sh shell

# Delete deployment
./deploy.sh delete
```

## Troubleshooting

### Pod Not Starting

```bash
# Check pod events
kubectl describe pod -n comfyui -l app=comfyui

# Common issues:
# - Image pull errors: Verify image name and registry access
# - GPU not available: Check node selector and GPU device plugin
# - PVC binding: Check storage class availability
```

### GPU Not Detected

```bash
# Verify NVIDIA device plugin
kubectl get pods -n kube-system | grep nvidia

# Check GPU on nodes
kubectl describe nodes | grep -A 10 "Allocatable:"

# Test GPU in pod
./deploy.sh gpu-check
```

### Cannot Access via Ingress

```bash
# Verify ingress controller is installed
kubectl get pods -n ingress-nginx  # For nginx ingress

# Check ingress status
kubectl describe ingress -n comfyui comfyui-ingress

# Verify DNS points to ingress controller
nslookup confy.baisoln.com

# Check ingress controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
```

### Storage Issues

```bash
# Check PVC status
kubectl get pvc -n comfyui

# Check if PVs are bound
kubectl get pv | grep comfyui

# Describe PVC for details
kubectl describe pvc -n comfyui comfyui-models-pvc
```

## Adding Models

### Method 1: Copy from Local Machine

```bash
# Get pod name
POD_NAME=$(kubectl get pod -n comfyui -l app=comfyui -o jsonpath='{.items[0].metadata.name}')

# Copy model file
kubectl cp ./my-model.safetensors comfyui/$POD_NAME:/app/ComfyUI/models/checkpoints/
```

### Method 2: Download Inside Pod

```bash
# Open shell
./deploy.sh shell

# Download model
cd /app/ComfyUI/models/checkpoints
wget https://huggingface.co/.../model.safetensors
```

### Method 3: Pre-populate PVC

Create an init container in the deployment to download models on first run.

## Scaling Considerations

### Single GPU Per Pod
GPU workloads typically run one replica per GPU. To scale:

```bash
# If you have multiple GPU nodes
kubectl scale deployment -n comfyui comfyui --replicas=3
```

### Multi-GPU Pod
For a single pod with multiple GPUs, update deployment:

```yaml
resources:
  requests:
    nvidia.com/gpu: "2"
  limits:
    nvidia.com/gpu: "2"
```

## Monitoring

### Basic Monitoring

```bash
# Resource usage
kubectl top pod -n comfyui

# GPU utilization
./deploy.sh gpu-check
```

### Advanced Monitoring

Install Prometheus and Grafana for advanced metrics:
- GPU utilization
- Memory usage
- Request latency
- Generation queue length

## Production Checklist

- [ ] Build and push Docker image to registry
- [ ] Update image reference in kustomization.yaml or deployment.yaml
- [ ] Configure GPU node selector for your cluster
- [ ] Adjust storage sizes based on your needs
- [ ] Set appropriate resource limits
- [ ] Configure ingress with your domain (confy.baisoln.com)
- [ ] Enable TLS/HTTPS with cert-manager
- [ ] Set up monitoring and alerting
- [ ] Configure backup strategy for PVCs
- [ ] Test GPU availability in pod
- [ ] Verify ComfyUI web interface is accessible
- [ ] Test image generation workflow
- [ ] Set up log aggregation
- [ ] Document model management process
- [ ] Plan for model updates and versioning

## Next Steps

1. **Build the image**: `cd k8s && ./build-and-push.sh your-registry/comfyui-k8s latest`
2. **Update references**: Edit `k8s/kustomization.yaml` with your image name
3. **Deploy**: `./deploy.sh deploy`
4. **Verify**: `./deploy.sh status` and `./deploy.sh gpu-check`
5. **Access**: `./deploy.sh port-forward` or via ingress at `http://confy.baisoln.com`
6. **Add models**: Copy or download your AI models
7. **Test**: Generate an image to verify everything works

## Resources

- [Detailed README](k8s/README.md) - Comprehensive documentation
- [ComfyUI GitHub](https://github.com/comfyanonymous/ComfyUI)
- [Golden AI Template](https://hub.docker.com/r/docker4zerocool/ai-template)
- [Kubernetes GPU Docs](https://kubernetes.io/docs/tasks/manage-gpus/scheduling-gpus/)
- [NVIDIA GPU Operator](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/)

## Support

For issues, check:
- Pod logs: `./deploy.sh logs`
- Pod status: `./deploy.sh status`
- GPU availability: `./deploy.sh gpu-check`
- [Detailed troubleshooting guide](k8s/README.md#troubleshooting)
