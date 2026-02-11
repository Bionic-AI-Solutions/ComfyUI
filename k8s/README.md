# ComfyUI Kubernetes Deployment

Complete Kubernetes deployment configuration for ComfyUI with GPU support, based on the golden AI template (`docker4zerocool/ai-template:runtime`).

## Features

- **GPU Support**: Utilizes NVIDIA GPU with CUDA 12.8.0 from golden AI template
- **Persistent Storage**: Separate PVCs for models, inputs, outputs, custom nodes, and user data
- **Auto-scaling Ready**: Configured with health checks and resource limits
- **Production Ready**: Includes liveness, readiness, and startup probes
- **Flexible Access**: ClusterIP, LoadBalancer, NodePort, and Ingress options
- **Easy Deployment**: Kustomize support for environment-specific configurations

## Prerequisites

### Cluster Requirements

1. **Kubernetes Cluster** with NVIDIA GPU support
   - GPU nodes with NVIDIA drivers installed
   - NVIDIA Device Plugin for Kubernetes deployed
   - GPU nodes properly labeled (e.g., `nvidia.com/gpu=true`)

2. **Storage Class** configured for PersistentVolumes
   - Default storage class or update PVC manifests with your storage class name

3. **Container Registry** access
   - Docker Hub, GCR, ECR, or private registry

### Tools Required

- `kubectl` CLI tool
- `docker` or `podman` for building images
- `kustomize` (optional, built into kubectl v1.14+)

## Quick Start

### 1. Build and Push Docker Image

```bash
# Build the Docker image
docker build -f Dockerfile.k8s -t your-registry/comfyui-k8s:latest .

# Push to your container registry
docker push your-registry/comfyui-k8s:latest

# Example for Docker Hub
docker build -f Dockerfile.k8s -t yourusername/comfyui-k8s:latest .
docker push yourusername/comfyui-k8s:latest

# Example for GCR (Google Container Registry)
docker build -f Dockerfile.k8s -t gcr.io/your-project/comfyui-k8s:latest .
docker push gcr.io/your-project/comfyui-k8s:latest
```

### 2. Update Image Reference

Edit [kustomization.yaml](kustomization.yaml) and update the image name:

```yaml
images:
  - name: comfyui-k8s
    newName: your-registry/comfyui-k8s  # Your actual registry
    newTag: latest
```

Or edit [deployment.yaml](deployment.yaml) directly:

```yaml
containers:
- name: comfyui
  image: your-registry/comfyui-k8s:latest
```

### 3. Configure GPU Node Selector

Verify your GPU nodes' labels:

```bash
kubectl get nodes --show-labels | grep gpu
```

Update [deployment.yaml](deployment.yaml) `nodeSelector` section based on your cluster:

```yaml
nodeSelector:
  nvidia.com/gpu: "true"  # Common label
  # Or use cloud-specific labels:
  # cloud.google.com/gke-accelerator: nvidia-tesla-v100  # GKE
  # node.kubernetes.io/instance-type: p3.2xlarge          # EKS
  # accelerator: nvidia-tesla-v100                        # AKS
```

### 4. Update Storage Configuration

Edit [pvc.yaml](pvc.yaml) to adjust storage sizes and storage class:

```yaml
spec:
  storageClassName: fast-ssd  # Change to your storage class
  resources:
    requests:
      storage: 100Gi  # Adjust size as needed
```

Available storage classes:

```bash
kubectl get storageclass
```

### 5. Deploy to Kubernetes

#### Option A: Using kubectl

```bash
# Apply all manifests
kubectl apply -f k8s/

# Or apply in order
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/pvc.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
# kubectl apply -f k8s/ingress.yaml  # Optional
```

#### Option B: Using Kustomize

```bash
# Deploy using kustomize
kubectl apply -k k8s/

# Or preview before applying
kubectl kustomize k8s/ | less
kubectl kustomize k8s/ | kubectl apply -f -
```

### 6. Verify Deployment

```bash
# Check namespace
kubectl get namespace comfyui

# Check all resources
kubectl get all -n comfyui

# Check PVCs
kubectl get pvc -n comfyui

# Check pod status and GPU allocation
kubectl describe pod -n comfyui -l app=comfyui

# Check logs
kubectl logs -n comfyui -l app=comfyui -f

# Verify GPU is available in the pod
kubectl exec -n comfyui -it $(kubectl get pod -n comfyui -l app=comfyui -o jsonpath='{.items[0].metadata.name}') -- nvidia-smi

# Verify PyTorch CUDA
kubectl exec -n comfyui -it $(kubectl get pod -n comfyui -l app=comfyui -o jsonpath='{.items[0].metadata.name}') -- /opt/conda/envs/wan22/bin/python -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}')"
```

### 7. Access ComfyUI

#### Option A: Port Forward (Development/Testing)

```bash
# Forward port 8188 to local machine
kubectl port-forward -n comfyui svc/comfyui 8188:8188

# Access at http://localhost:8188
```

#### Option B: LoadBalancer (Cloud Clusters)

```bash
# Get external IP
kubectl get svc -n comfyui comfyui-external

# Wait for EXTERNAL-IP to be assigned
# Access at http://<EXTERNAL-IP>:8188
```

#### Option C: NodePort

```bash
# Uncomment NodePort service in service.yaml and apply
kubectl apply -f k8s/service.yaml

# Get node IP and NodePort
kubectl get nodes -o wide
kubectl get svc -n comfyui comfyui-nodeport

# Access at http://<NODE-IP>:30188
```

#### Option D: Ingress (Recommended for Production)

```bash
# Configure and uncomment ingress.yaml
# Update domain name
# Apply ingress
kubectl apply -f k8s/ingress.yaml

# Access at http://comfyui.yourdomain.com
```

## Configuration

### Environment Variables

Edit [configmap.yaml](configmap.yaml) to customize:

```yaml
data:
  PYTHONUNBUFFERED: "1"
  CUDA_DEVICE_ORDER: "PCI_BUS_ID"
  NVIDIA_VISIBLE_DEVICES: "all"
  COMFYUI_PORT: "8188"
```

### Resource Limits

Edit [deployment.yaml](deployment.yaml) resources section:

```yaml
resources:
  requests:
    memory: "8Gi"
    cpu: "2"
    nvidia.com/gpu: "1"
  limits:
    memory: "16Gi"
    cpu: "4"
    nvidia.com/gpu: "1"
```

### Scaling

ComfyUI with GPU is typically run as a single replica due to GPU resource constraints:

```bash
# Scale manually (if you have multiple GPUs)
kubectl scale deployment -n comfyui comfyui --replicas=2
```

### Health Checks

The deployment includes three types of probes:

- **Startup Probe**: Allows up to 5 minutes for initial startup
- **Liveness Probe**: Restarts container if ComfyUI becomes unresponsive
- **Readiness Probe**: Removes pod from service if not ready to serve traffic

Adjust timeouts in [deployment.yaml](deployment.yaml) if needed.

## Storage Management

### Model Storage

Models are stored in the `comfyui-models-pvc` PVC. To add models:

#### Method 1: Copy from Local Machine

```bash
# Get pod name
POD_NAME=$(kubectl get pod -n comfyui -l app=comfyui -o jsonpath='{.items[0].metadata.name}')

# Copy checkpoint model
kubectl cp ./my-model.safetensors comfyui/$POD_NAME:/app/ComfyUI/models/checkpoints/

# Copy VAE model
kubectl cp ./my-vae.safetensors comfyui/$POD_NAME:/app/ComfyUI/models/vae/
```

#### Method 2: Direct Access to PVC

```bash
# Create a temporary pod with PVC mounted
kubectl run -n comfyui temp-pod --image=ubuntu --restart=Never --overrides='
{
  "spec": {
    "containers": [{
      "name": "temp-pod",
      "image": "ubuntu",
      "command": ["sleep", "3600"],
      "volumeMounts": [{
        "name": "models",
        "mountPath": "/models"
      }]
    }],
    "volumes": [{
      "name": "models",
      "persistentVolumeClaim": {
        "claimName": "comfyui-models-pvc"
      }
    }]
  }
}'

# Copy files to the PVC
kubectl cp ./models/checkpoints/ comfyui/temp-pod:/models/checkpoints/

# Delete temp pod
kubectl delete pod -n comfyui temp-pod
```

#### Method 3: Use Init Container

Add an init container to the deployment to download models on startup.

### Backup and Restore

```bash
# Backup PVC data
kubectl exec -n comfyui $(kubectl get pod -n comfyui -l app=comfyui -o jsonpath='{.items[0].metadata.name}') -- tar czf - /app/ComfyUI/models > models-backup.tar.gz

# Restore PVC data
kubectl exec -n comfyui -i $(kubectl get pod -n comfyui -l app=comfyui -o jsonpath='{.items[0].metadata.name}') -- tar xzf - -C / < models-backup.tar.gz
```

## Troubleshooting

### Pod Not Starting

```bash
# Check pod events
kubectl describe pod -n comfyui -l app=comfyui

# Common issues:
# - Image pull errors: Check image name and registry access
# - GPU not available: Check node selector and GPU device plugin
# - PVC binding issues: Check storage class and PV provisioning
```

### GPU Not Detected

```bash
# Verify NVIDIA device plugin is running
kubectl get pods -n kube-system | grep nvidia

# Check GPU resources on nodes
kubectl describe nodes | grep -A 10 "Allocatable:"

# Check pod GPU allocation
kubectl describe pod -n comfyui -l app=comfyui | grep -i gpu

# Exec into pod and check nvidia-smi
kubectl exec -n comfyui -it $(kubectl get pod -n comfyui -l app=comfyui -o jsonpath='{.items[0].metadata.name}') -- nvidia-smi
```

### PVC Not Binding

```bash
# Check PVC status
kubectl get pvc -n comfyui

# Check PV provisioning
kubectl get pv

# Describe PVC for details
kubectl describe pvc -n comfyui comfyui-models-pvc

# Common fixes:
# - Update storageClassName in pvc.yaml
# - Ensure storage provisioner is installed
# - Check PV capacity and availability
```

### Image Pull Errors

```bash
# Check image pull status
kubectl describe pod -n comfyui -l app=comfyui | grep -A 10 "Events:"

# Verify image exists
docker pull your-registry/comfyui-k8s:latest

# Create image pull secret if using private registry
kubectl create secret docker-registry regcred \
  --docker-server=your-registry \
  --docker-username=your-username \
  --docker-password=your-password \
  --docker-email=your-email \
  -n comfyui

# Add to deployment.yaml:
# spec:
#   imagePullSecrets:
#   - name: regcred
```

### Performance Issues

```bash
# Check resource usage
kubectl top pod -n comfyui

# Check GPU utilization
kubectl exec -n comfyui -it $(kubectl get pod -n comfyui -l app=comfyui -o jsonpath='{.items[0].metadata.name}') -- nvidia-smi

# Increase resource limits in deployment.yaml if needed
```

### Network/Service Issues

```bash
# Test service connectivity
kubectl run -n comfyui test-pod --image=curlimages/curl --rm -it --restart=Never -- curl http://comfyui:8188

# Check service endpoints
kubectl get endpoints -n comfyui comfyui

# Check ingress (if using)
kubectl describe ingress -n comfyui comfyui-ingress
```

## Cleanup

```bash
# Delete all resources
kubectl delete namespace comfyui

# Or delete individually
kubectl delete -f k8s/

# Or using kustomize
kubectl delete -k k8s/

# Note: PVCs and PVs might need manual deletion if using retain policy
kubectl get pv | grep comfyui
kubectl delete pv <pv-name>
```

## Advanced Configuration

### Using Secrets for Sensitive Data

```bash
# Create secret for API keys or passwords
kubectl create secret generic comfyui-secrets \
  --from-literal=api-key=your-api-key \
  -n comfyui

# Reference in deployment
envFrom:
- secretRef:
    name: comfyui-secrets
```

### Multiple GPU Support

```yaml
# In deployment.yaml
resources:
  requests:
    nvidia.com/gpu: "2"  # Request 2 GPUs
  limits:
    nvidia.com/gpu: "2"
```

### GPU Node Affinity (Advanced)

```yaml
# In deployment.yaml
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: nvidia.com/gpu.product
          operator: In
          values:
          - Tesla-V100-SXM2-16GB
          - Tesla-T4
```

### Horizontal Pod Autoscaler

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: comfyui-hpa
  namespace: comfyui
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: comfyui
  minReplicas: 1
  maxReplicas: 3
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

## Monitoring

### Prometheus Metrics

Add Prometheus annotations to deployment:

```yaml
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8188"
    prometheus.io/path: "/metrics"
```

### Grafana Dashboard

Import ComfyUI metrics to Grafana for visualization.

## Security Best Practices

1. **Use non-root user** in Dockerfile (commented out by default, uncomment if needed)
2. **Enable RBAC** for service accounts
3. **Use Network Policies** to restrict pod communication
4. **Implement Pod Security Policies**
5. **Use secrets** for sensitive data
6. **Enable TLS** for Ingress
7. **Regularly update** base images and dependencies

## References

- [ComfyUI GitHub](https://github.com/comfyanonymous/ComfyUI)
- [NVIDIA GPU Operator](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/getting-started.html)
- [Kubernetes GPU Documentation](https://kubernetes.io/docs/tasks/manage-gpus/scheduling-gpus/)
- [Golden AI Template](https://hub.docker.com/r/docker4zerocool/ai-template)

## Support

For issues specific to:
- **ComfyUI**: Check [ComfyUI repository](https://github.com/comfyanonymous/ComfyUI/issues)
- **Kubernetes**: Check [Kubernetes documentation](https://kubernetes.io/docs/)
- **NVIDIA GPU**: Check [NVIDIA GPU Operator docs](https://docs.nvidia.com/datacenter/cloud-native/)
