#!/bin/bash
# Deploy ComfyUI to Kubernetes
# Usage: ./deploy.sh [action]
# Actions: deploy, delete, status, logs, port-forward

set -e

NAMESPACE="comfyui"
ACTION="${1:-deploy}"

function deploy() {
    echo "=========================================="
    echo "Deploying ComfyUI to Kubernetes"
    echo "=========================================="

    # Check if kubectl is available
    if ! command -v kubectl &> /dev/null; then
        echo "Error: kubectl not found. Please install kubectl first."
        exit 1
    fi

    # Check cluster connectivity
    echo "Checking cluster connectivity..."
    if ! kubectl cluster-info &> /dev/null; then
        echo "Error: Cannot connect to Kubernetes cluster."
        echo "Please configure kubectl with the correct context."
        exit 1
    fi

    # Deploy using kubectl
    echo "Applying Kubernetes manifests..."
    kubectl apply -f namespace.yaml
    kubectl apply -f configmap.yaml
    kubectl apply -f pvc.yaml
    kubectl apply -f deployment.yaml
    kubectl apply -f service.yaml

    # Optional: Deploy ingress (commented by default)
    # kubectl apply -f ingress.yaml

    echo "=========================================="
    echo "Deployment initiated!"
    echo "=========================================="
    echo ""
    echo "Check status with:"
    echo "  ./deploy.sh status"
    echo ""
    echo "View logs with:"
    echo "  ./deploy.sh logs"
    echo ""
    echo "Access ComfyUI with:"
    echo "  ./deploy.sh port-forward"
    echo "=========================================="
}

function delete() {
    echo "=========================================="
    echo "Deleting ComfyUI from Kubernetes"
    echo "=========================================="

    read -p "Are you sure you want to delete ComfyUI deployment? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        kubectl delete -f service.yaml --ignore-not-found=true
        kubectl delete -f deployment.yaml --ignore-not-found=true
        kubectl delete -f pvc.yaml --ignore-not-found=true
        kubectl delete -f configmap.yaml --ignore-not-found=true

        read -p "Do you also want to delete the namespace? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            kubectl delete -f namespace.yaml --ignore-not-found=true
            echo "Namespace deleted."
        else
            echo "Namespace kept."
        fi

        echo "=========================================="
        echo "ComfyUI deleted successfully!"
        echo "=========================================="
    else
        echo "Deletion cancelled."
    fi
}

function status() {
    echo "=========================================="
    echo "ComfyUI Status"
    echo "=========================================="

    echo -e "\n--- Namespace ---"
    kubectl get namespace ${NAMESPACE} 2>/dev/null || echo "Namespace not found"

    echo -e "\n--- Pods ---"
    kubectl get pods -n ${NAMESPACE} 2>/dev/null || echo "No pods found"

    echo -e "\n--- Services ---"
    kubectl get svc -n ${NAMESPACE} 2>/dev/null || echo "No services found"

    echo -e "\n--- PVCs ---"
    kubectl get pvc -n ${NAMESPACE} 2>/dev/null || echo "No PVCs found"

    echo -e "\n--- Deployments ---"
    kubectl get deployments -n ${NAMESPACE} 2>/dev/null || echo "No deployments found"

    # Check if pod is running
    POD_NAME=$(kubectl get pod -n ${NAMESPACE} -l app=comfyui -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    if [ ! -z "$POD_NAME" ]; then
        echo -e "\n--- Pod Details ---"
        kubectl describe pod -n ${NAMESPACE} ${POD_NAME} | grep -A 5 "Status:\|Conditions:\|Events:"

        echo -e "\n--- GPU Check ---"
        kubectl exec -n ${NAMESPACE} ${POD_NAME} -- nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader 2>/dev/null || echo "GPU check failed (pod might not be ready)"
    fi

    echo "=========================================="
}

function logs() {
    echo "=========================================="
    echo "ComfyUI Logs"
    echo "=========================================="

    POD_NAME=$(kubectl get pod -n ${NAMESPACE} -l app=comfyui -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    if [ -z "$POD_NAME" ]; then
        echo "Error: No ComfyUI pod found"
        exit 1
    fi

    echo "Following logs for pod: ${POD_NAME}"
    echo "Press Ctrl+C to stop"
    echo "=========================================="
    kubectl logs -n ${NAMESPACE} -f ${POD_NAME}
}

function port_forward() {
    echo "=========================================="
    echo "Port Forwarding to ComfyUI"
    echo "=========================================="

    POD_NAME=$(kubectl get pod -n ${NAMESPACE} -l app=comfyui -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    if [ -z "$POD_NAME" ]; then
        echo "Error: No ComfyUI pod found"
        exit 1
    fi

    echo "Forwarding port 8188 to localhost:8188"
    echo "Access ComfyUI at: http://localhost:8188"
    echo "Press Ctrl+C to stop"
    echo "=========================================="
    kubectl port-forward -n ${NAMESPACE} ${POD_NAME} 8188:8188
}

function gpu_check() {
    echo "=========================================="
    echo "GPU Verification"
    echo "=========================================="

    POD_NAME=$(kubectl get pod -n ${NAMESPACE} -l app=comfyui -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    if [ -z "$POD_NAME" ]; then
        echo "Error: No ComfyUI pod found"
        exit 1
    fi

    echo "Running nvidia-smi in pod..."
    kubectl exec -n ${NAMESPACE} -it ${POD_NAME} -- nvidia-smi

    echo -e "\n=========================================="
    echo "Checking PyTorch CUDA..."
    kubectl exec -n ${NAMESPACE} ${POD_NAME} -- /opt/conda/envs/wan22/bin/python -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}'); print(f'CUDA version: {torch.version.cuda}'); print(f'GPU count: {torch.cuda.device_count()}'); print(f'GPU name: {torch.cuda.get_device_name(0) if torch.cuda.is_available() else \"N/A\"}')"
    echo "=========================================="
}

function shell() {
    echo "=========================================="
    echo "Opening Shell in ComfyUI Pod"
    echo "=========================================="

    POD_NAME=$(kubectl get pod -n ${NAMESPACE} -l app=comfyui -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    if [ -z "$POD_NAME" ]; then
        echo "Error: No ComfyUI pod found"
        exit 1
    fi

    echo "Opening shell in pod: ${POD_NAME}"
    echo "=========================================="
    kubectl exec -n ${NAMESPACE} -it ${POD_NAME} -- /bin/bash
}

# Main script logic
case "$ACTION" in
    deploy)
        deploy
        ;;
    delete)
        delete
        ;;
    status)
        status
        ;;
    logs)
        logs
        ;;
    port-forward|pf)
        port_forward
        ;;
    gpu|gpu-check)
        gpu_check
        ;;
    shell|exec)
        shell
        ;;
    *)
        echo "ComfyUI Kubernetes Deployment Script"
        echo ""
        echo "Usage: $0 [action]"
        echo ""
        echo "Actions:"
        echo "  deploy        - Deploy ComfyUI to Kubernetes (default)"
        echo "  delete        - Delete ComfyUI from Kubernetes"
        echo "  status        - Show deployment status"
        echo "  logs          - Follow pod logs"
        echo "  port-forward  - Forward port 8188 to localhost (alias: pf)"
        echo "  gpu-check     - Verify GPU availability (alias: gpu)"
        echo "  shell         - Open shell in ComfyUI pod (alias: exec)"
        echo ""
        echo "Examples:"
        echo "  $0 deploy"
        echo "  $0 status"
        echo "  $0 port-forward"
        exit 1
        ;;
esac
