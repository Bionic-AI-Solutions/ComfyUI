#!/usr/bin/env python3
"""Test script to debug CUDA availability in PyTorch"""
import os
import sys

print("=" * 60)
print("CUDA Diagnostic Test")
print("=" * 60)

# Check environment
print("\n1. Environment Variables:")
print(f"   CUDA_VISIBLE_DEVICES: {os.environ.get('CUDA_VISIBLE_DEVICES', 'Not set')}")
print(f"   NVIDIA_VISIBLE_DEVICES: {os.environ.get('NVIDIA_VISIBLE_DEVICES', 'Not set')}")
print(f"   LD_LIBRARY_PATH: {os.environ.get('LD_LIBRARY_PATH', 'Not set')}")

# Check nvidia-smi
print("\n2. Testing nvidia-smi:")
import subprocess
try:
    result = subprocess.run(['nvidia-smi', '--query-gpu=name', '--format=csv,noheader'], 
                          capture_output=True, text=True, timeout=5)
    if result.returncode == 0:
        print(f"   ✓ nvidia-smi works: {result.stdout.strip()}")
    else:
        print(f"   ✗ nvidia-smi failed: {result.stderr}")
except Exception as e:
    print(f"   ✗ nvidia-smi error: {e}")

# Check PyTorch
print("\n3. Testing PyTorch:")
try:
    import torch
    print(f"   PyTorch version: {torch.__version__}")
    print(f"   PyTorch path: {torch.__file__}")
    
    # Check CUDA availability
    print("\n4. Testing CUDA availability:")
    try:
        cuda_available = torch.cuda.is_available()
        print(f"   torch.cuda.is_available(): {cuda_available}")
        
        if cuda_available:
            print(f"   CUDA device count: {torch.cuda.device_count()}")
            print(f"   Current device: {torch.cuda.current_device()}")
            print(f"   Device name: {torch.cuda.get_device_name(0)}")
        else:
            print("   ✗ CUDA not available")
            print("\n5. Attempting to initialize CUDA manually:")
            try:
                torch.cuda.init()
                print("   ✓ CUDA init succeeded")
            except Exception as init_error:
                print(f"   ✗ CUDA init failed: {init_error}")
                import traceback
                traceback.print_exc()
    except Exception as e:
        print(f"   ✗ Error checking CUDA: {e}")
        import traceback
        traceback.print_exc()
        
except ImportError as e:
    print(f"   ✗ PyTorch not installed: {e}")

print("\n" + "=" * 60)
