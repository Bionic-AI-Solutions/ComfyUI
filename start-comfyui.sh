#!/bin/bash
# Start ComfyUI with proper GPU access
# This script ensures GPU is accessible before starting ComfyUI

set -e

echo "Checking GPU access..."
/opt/conda/envs/wan22/bin/python -c "import torch; assert torch.cuda.is_available(), 'CUDA not available'; print(f'GPU check passed: {torch.cuda.device_count()} device(s) available')"

echo "Starting ComfyUI..."
exec /opt/conda/envs/wan22/bin/python main.py --listen 0.0.0.0 --port 8188 --preview-method auto --enable-manager
