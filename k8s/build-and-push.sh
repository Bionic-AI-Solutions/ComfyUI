#!/bin/bash
# Build and Push ComfyUI Docker Image for Kubernetes
# Usage: ./build-and-push.sh [registry/image-name] [tag]

set -e

# Default values
DEFAULT_IMAGE="comfyui-k8s"
DEFAULT_TAG="latest"

# Get arguments or use defaults
IMAGE_NAME="${1:-$DEFAULT_IMAGE}"
TAG="${2:-$DEFAULT_TAG}"
FULL_IMAGE="${IMAGE_NAME}:${TAG}"

echo "=========================================="
echo "Building ComfyUI Kubernetes Image"
echo "=========================================="
echo "Image: ${FULL_IMAGE}"
echo "Dockerfile: ../Dockerfile.k8s"
echo "=========================================="

# Check if Dockerfile exists
if [ ! -f "../Dockerfile.k8s" ]; then
    echo "Error: Dockerfile.k8s not found in parent directory"
    exit 1
fi

# Build the image
echo "Building Docker image..."
docker build -f ../Dockerfile.k8s -t "${FULL_IMAGE}" ..

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "=========================================="
    echo "Build successful!"
    echo "=========================================="

    # Ask if user wants to push
    read -p "Do you want to push the image to registry? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Pushing image to registry..."
        docker push "${FULL_IMAGE}"

        if [ $? -eq 0 ]; then
            echo "=========================================="
            echo "Push successful!"
            echo "=========================================="
            echo "Image: ${FULL_IMAGE}"
            echo ""
            echo "Next steps:"
            echo "1. Update k8s/kustomization.yaml with the image name:"
            echo "   newName: ${IMAGE_NAME}"
            echo "   newTag: ${TAG}"
            echo ""
            echo "2. Deploy to Kubernetes:"
            echo "   kubectl apply -k k8s/"
            echo "   # or"
            echo "   ./deploy.sh"
            echo "=========================================="
        else
            echo "Error: Failed to push image"
            exit 1
        fi
    else
        echo "Skipping push. Image is available locally as: ${FULL_IMAGE}"
        echo ""
        echo "To push later, run:"
        echo "  docker push ${FULL_IMAGE}"
    fi
else
    echo "Error: Build failed"
    exit 1
fi
