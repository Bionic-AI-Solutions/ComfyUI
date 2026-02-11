# ComfyUI Kubernetes Deployment - SUCCESS! ✅

## Deployment Status

🎉 **ComfyUI is now running on Kubernetes with full GPU support!**

### Deployment Information

**Namespace**: `comfyui`
**Pod Status**: Running (1/1 READY)
**Node**: `gpu`
**Container Runtime**: `nvidia`

### GPU Configuration

**GPU Detected**: ✅ SUCCESS
**Active GPU**: NVIDIA GeForce RTX 5090 (32GB VRAM)
**Available GPUs**:
- GPU 1: NVIDIA GeForce RTX 5090 - 32,607 MB
- GPU 2: NVIDIA RTX PRO 6000 Blackwell Workstation Edition - 97,887 MB

**CUDA Version**: 12.8
**PyTorch Version**: 2.9.0+cu128
**Driver Version**: 580.126.09

### Access Information

#### 1. Via LoadBalancer (Recommended for Direct Access)
```
http://192.168.0.211:8188
```
**Status**: ✅ Accessible (HTTP 200)

#### 2. Via Ingress (Domain Name)
```
http://confy.baisoln.com
```
**Note**: Make sure DNS is configured to point to your ingress controller

#### 3. Via Port Forward (For Testing)
```bash
kubectl port-forward -n comfyui svc/comfyui 8188:8188
# Then access at http://localhost:8188
```

#### 4. Via ClusterIP (Internal Only)
```
Service: comfyui.comfyui.svc.cluster.local:8188
IP: 10.43.136.98:8188
```

### Deployment Configuration

#### Node Affinity
- **Required**: `nvidia.com/gpu.present=true`
- **Ensures**: Pod ONLY schedules on GPU nodes
- **Tolerations**: nvidia.com/gpu:NoSchedule

#### Storage (NFS-Client)
- **Models PVC**: 100Gi - `pvc-c4fa1465-a37b-474c-8b2a-ba9fe6e7f331`
- **Input PVC**: 10Gi - `pvc-1c7c5aed-300b-46a6-9af1-72066efc2ec6`
- **Output PVC**: 50Gi - `pvc-5cc55d01-9822-455c-b5c7-54a859e5f7bc`
- **Custom Nodes PVC**: 10Gi - `pvc-c65e8a6c-163f-4fcf-bc06-3abfe90fca63`
- **User Data PVC**: 5Gi - `pvc-d487ab88-dbf8-486d-86d6-7ac50e4f173a`

#### Resources
- **CPU Request**: 2 cores
- **CPU Limit**: 4 cores
- **Memory Request**: 8Gi
- **Memory Limit**: 16Gi
- **GPU**: Access via nvidia runtime (not resource-based)

### Docker Image

**Registry**: Docker Hub
**Image**: `docker4zerocool/comfyui-k8s:latest`
**Base**: `docker4zerocool/ai-template:runtime` (Golden AI Template)
**Digest**: sha256:1af4232de4daa4b5cb44d042c668c299e7e8769dfbdf1a746cf83db21a8dac13

### Services

| Name | Type | Cluster IP | External IP | Port | Age |
|------|------|------------|-------------|------|-----|
| comfyui | ClusterIP | 10.43.136.98 | - | 8188/TCP | Running |
| comfyui-external | LoadBalancer | 10.43.187.53 | 192.168.0.211 | 8188:30206/TCP | Running |

### Ingress

**Host**: confy.baisoln.com
**Class**: nginx
**Port**: 80 (HTTP)
**TLS**: Not configured (can be enabled with cert-manager)

## Quick Commands

### Check Status
```bash
kubectl get all -n comfyui
kubectl get pods -n comfyui -o wide
kubectl get pvc -n comfyui
```

### View Logs
```bash
kubectl logs -n comfyui -l app=comfyui -f
```

### Verify GPU
```bash
# Get pod name
POD_NAME=$(kubectl get pod -n comfyui -l app=comfyui -o jsonpath='{.items[0].metadata.name}')

# Check nvidia-smi
kubectl exec -n comfyui $POD_NAME -- nvidia-smi

# Check PyTorch CUDA
kubectl exec -n comfyui $POD_NAME -- /opt/conda/envs/wan22/bin/python -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}'); print(f'GPU name: {torch.cuda.get_device_name(0)}')"
```

### Access Shell
```bash
kubectl exec -n comfyui -it $(kubectl get pod -n comfyui -l app=comfyui -o jsonpath='{.items[0].metadata.name}') -- /bin/bash
```

### Scale Deployment
```bash
# Scale to multiple replicas (if you have multiple GPUs)
kubectl scale deployment -n comfyui comfyui --replicas=2
```

### Restart Deployment
```bash
kubectl rollout restart deployment -n comfyui comfyui
```

### Delete Deployment
```bash
# Delete all resources
kubectl delete namespace comfyui

# Or delete individually
kubectl delete -f k8s/
```

## Adding Models

### Method 1: Copy from Local Machine
```bash
POD_NAME=$(kubectl get pod -n comfyui -l app=comfyui -o jsonpath='{.items[0].metadata.name}')

# Copy checkpoint model
kubectl cp ./my-model.safetensors comfyui/$POD_NAME:/app/ComfyUI/models/checkpoints/

# Copy VAE
kubectl cp ./my-vae.safetensors comfyui/$POD_NAME:/app/ComfyUI/models/vae/
```

### Method 2: Download Inside Pod
```bash
POD_NAME=$(kubectl get pod -n comfyui -l app=comfyui -o jsonpath='{.items[0].metadata.name}')

kubectl exec -n comfyui -it $POD_NAME -- bash

# Inside the pod
cd /app/ComfyUI/models/checkpoints
wget https://huggingface.co/.../model.safetensors
```

## Monitoring

### Resource Usage
```bash
kubectl top pod -n comfyui
```

### GPU Utilization
```bash
POD_NAME=$(kubectl get pod -n comfyui -l app=comfyui -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n comfyui $POD_NAME -- nvidia-smi
```

### Service Health
```bash
# Check endpoints
kubectl get endpoints -n comfyui

# Test HTTP
curl http://192.168.0.211:8188/
```

## Troubleshooting

### Pod Not Starting
```bash
kubectl describe pod -n comfyui -l app=comfyui
kubectl logs -n comfyui -l app=comfyui
```

### GPU Not Detected
```bash
# Check runtime class
kubectl get runtimeclass

# Check node labels
kubectl get nodes --show-labels | grep gpu

# Verify GPU in pod
POD_NAME=$(kubectl get pod -n comfyui -l app=comfyui -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n comfyui $POD_NAME -- nvidia-smi
```

### Service Not Accessible
```bash
# Check service
kubectl get svc -n comfyui

# Check ingress
kubectl describe ingress -n comfyui comfyui-ingress

# Port forward for testing
kubectl port-forward -n comfyui svc/comfyui 8188:8188
```

## Configuration Files

All Kubernetes manifests are in the `k8s/` directory:

- **[namespace.yaml](k8s/namespace.yaml)** - Namespace configuration
- **[configmap.yaml](k8s/configmap.yaml)** - Environment variables
- **[pvc.yaml](k8s/pvc.yaml)** - Persistent storage claims
- **[deployment.yaml](k8s/deployment.yaml)** - Main deployment with GPU support
- **[service.yaml](k8s/service.yaml)** - Services (ClusterIP, LoadBalancer)
- **[ingress.yaml](k8s/ingress.yaml)** - Ingress for domain access
- **[kustomization.yaml](k8s/kustomization.yaml)** - Kustomize configuration

Helper scripts:
- **[build-and-push.sh](k8s/build-and-push.sh)** - Build and push Docker image
- **[deploy.sh](k8s/deploy.sh)** - Deployment management script

## Next Steps

1. **Add Models**: Copy your AI models to the models PVC
2. **Test Generation**: Create a workflow and generate images
3. **Configure TLS**: Enable HTTPS with cert-manager (optional)
4. **Set up Monitoring**: Install Prometheus/Grafana for metrics (optional)
5. **Backup Strategy**: Configure regular backups of PVCs (optional)

## Performance Notes

- **GPU**: Using NVIDIA GeForce RTX 5090 (32GB VRAM)
- **Device**: cuda:0 with cudaMallocAsync
- **VRAM Mode**: NORMAL_VRAM
- **Attention**: PyTorch attention (default)
- **Async Offloading**: Enabled with 2 streams
- **Pinned Memory**: 244GB enabled

## Summary

✅ Docker image built and pushed to Docker Hub
✅ All Kubernetes resources deployed successfully
✅ Pod scheduled on GPU node with proper affinity
✅ GPU accessible via nvidia runtime
✅ ComfyUI web interface running and accessible
✅ LoadBalancer service with external IP assigned
✅ Ingress configured for domain access
✅ All PVCs bound and ready

**Access ComfyUI now at**: http://192.168.0.211:8188 🚀

---

**Deployed**: 2026-02-11
**Status**: Production Ready ✅
