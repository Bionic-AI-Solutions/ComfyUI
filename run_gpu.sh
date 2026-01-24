#!/bin/bash
set -e  # Exit on error

cd ComfyUI
source venv/bin/activate

# Check if CUDA is available before starting
echo "Checking for CUDA availability..."
python -c "
import torch
import sys

if not torch.cuda.is_available():
    print('ERROR: CUDA is not available!', file=sys.stderr)
    print('', file=sys.stderr)
    print('This script requires CUDA-enabled GPU to run.', file=sys.stderr)
    print('If you want to run in CPU mode, please use: ./run_cpu.sh', file=sys.stderr)
    print('', file=sys.stderr)
    print('CUDA check details:', file=sys.stderr)
    print(f'  torch.cuda.is_available(): {torch.cuda.is_available()}', file=sys.stderr)
    try:
        print(f'  torch.cuda.device_count(): {torch.cuda.device_count()}', file=sys.stderr)
    except:
        print('  torch.cuda.device_count(): N/A (error getting device count)', file=sys.stderr)
    sys.exit(1)
else:
    device_count = torch.cuda.device_count()
    print(f'CUDA is available! Found {device_count} GPU(s)')
    for i in range(device_count):
        print(f'  GPU {i}: {torch.cuda.get_device_name(i)}')
"

if [ $? -ne 0 ]; then
    echo ""
    echo "Aborting: CUDA is required for GPU mode."
    exit 1
fi

echo ""
echo "Starting ComfyUI in GPU mode..."
python main.py --preview-method auto
