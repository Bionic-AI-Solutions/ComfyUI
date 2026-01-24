#!/bin/bash
# Script to fix CUDA access in the devcontainer
# This can be run inside the container to verify GPU access

echo "=== CUDA Fix Diagnostic Script ==="
echo ""

# Check if we're in a container
if [ -f /.dockerenv ]; then
    echo "✓ Running inside Docker container"
else
    echo "✗ Not in a container"
    exit 1
fi

# Check nvidia-smi
echo ""
echo "1. Checking nvidia-smi..."
if command -v nvidia-smi &> /dev/null; then
    nvidia-smi --query-gpu=name --format=csv,noheader | head -1
    echo "   ✓ nvidia-smi works"
else
    echo "   ✗ nvidia-smi not found"
fi

# Check NVIDIA devices
echo ""
echo "2. Checking NVIDIA devices..."
if [ -e /dev/nvidia0 ]; then
    ls -1 /dev/nvidia* | wc -l | xargs echo "   Found devices:"
    echo "   ✓ NVIDIA devices accessible"
else
    echo "   ✗ No NVIDIA devices found"
fi

# Check environment
echo ""
echo "3. Checking environment variables..."
echo "   CUDA_VISIBLE_DEVICES: ${CUDA_VISIBLE_DEVICES:-not set}"
echo "   NVIDIA_VISIBLE_DEVICES: ${NVIDIA_VISIBLE_DEVICES:-not set}"
echo "   LD_LIBRARY_PATH: ${LD_LIBRARY_PATH:-not set}"

# Check PyTorch
echo ""
echo "4. Checking PyTorch CUDA..."
cd /workspaces/comfyUI/ComfyUI 2>/dev/null || cd /workspace/ComfyUI 2>/dev/null || { echo "   ✗ ComfyUI directory not found"; exit 1; }

if [ -f venv/bin/activate ]; then
    source venv/bin/activate
    python -c "
import torch
print(f'   PyTorch version: {torch.__version__}')
print(f'   CUDA available: {torch.cuda.is_available()}')
if torch.cuda.is_available():
    print(f'   CUDA device count: {torch.cuda.device_count()}')
    print(f'   Device 0: {torch.cuda.get_device_name(0)}')
else:
    print('   ✗ CUDA not available in PyTorch')
    print('   This is the problem!')
" 2>&1
else
    echo "   ✗ ComfyUI venv not found"
fi

echo ""
echo "=== Diagnostic Complete ==="
echo ""
echo "If PyTorch CUDA is not available but nvidia-smi works,"
echo "you need to rebuild the devcontainer with --gpus=all flag."
echo ""
echo "In VS Code:"
echo "1. Press F1 -> 'Dev Containers: Rebuild Container'"
echo "2. Or close and reopen the devcontainer"
