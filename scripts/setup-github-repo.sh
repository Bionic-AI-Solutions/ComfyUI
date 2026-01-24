#!/bin/bash
# Script to create GitHub repository and push code

set -e

echo "🚀 Setting up GitHub repository for gpu-devcontainer..."

# Check if authenticated
if ! gh auth status &>/dev/null; then
    echo "❌ GitHub CLI is not authenticated."
    echo ""
    echo "Please authenticate by running:"
    echo "  gh auth login"
    echo ""
    echo "Or set GITHUB_TOKEN environment variable:"
    echo "  export GITHUB_TOKEN=your_token_here"
    echo "  gh auth login --with-token <<< \"\$GITHUB_TOKEN\""
    exit 1
fi

echo "✅ GitHub CLI authenticated"

# Create repository in Bionic-AI-Solutions org
echo "📦 Creating repository in Bionic-AI-Solutions organization..."
gh repo create Bionic-AI-Solutions/gpu-devcontainer \
    --public \
    --description "GPU-accelerated devcontainer with NVIDIA CUDA 12.8 support, Docker-in-Docker, and Kubernetes access" \
    --source=. \
    --remote=origin \
    --push

echo ""
echo "✅ Repository created and code pushed successfully!"
echo "📍 Repository URL: https://github.com/Bionic-AI-Solutions/gpu-devcontainer"
