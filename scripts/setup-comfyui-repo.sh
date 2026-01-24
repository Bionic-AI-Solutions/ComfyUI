#!/bin/bash
# Script to create GitHub repository and push ComfyUI code

set -e

echo "🚀 Setting up GitHub repository for ComfyUI..."

# Check if authenticated
if ! gh auth status &>/dev/null 2>&1; then
    echo "❌ GitHub CLI is not authenticated or not installed."
    echo ""
    echo "Please authenticate by running:"
    echo "  gh auth login"
    echo ""
    echo "Or install GitHub CLI first:"
    echo "  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg"
    echo "  echo \"deb [arch=\$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main\" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null"
    echo "  sudo apt update && sudo apt install gh"
    echo "  gh auth login"
    exit 1
fi

echo "✅ GitHub CLI authenticated"

# Create repository in Bionic-AI-Solutions org
echo "📦 Creating repository in Bionic-AI-Solutions organization..."
gh repo create Bionic-AI-Solutions/ComfyUI \
    --public \
    --description "ComfyUI with GPU acceleration, Docker support, and centralized model management" \
    --source=. \
    --remote=origin \
    --push

echo ""
echo "✅ Repository created and code pushed successfully!"
echo "📍 Repository URL: https://github.com/Bionic-AI-Solutions/ComfyUI"
