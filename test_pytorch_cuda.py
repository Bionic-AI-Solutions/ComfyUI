#!/usr/bin/env python3
"""Test PyTorch CUDA initialization"""
import torch
import sys
import os

print("=" * 60)
print("PyTorch CUDA Deep Diagnostic")
print("=" * 60)

print(f"\n1. Environment:")
print(f"   CUDA_VISIBLE_DEVICES: {os.environ.get('CUDA_VISIBLE_DEVICES', 'Not set')}")
print(f"   NVIDIA_VISIBLE_DEVICES: {os.environ.get('NVIDIA_VISIBLE_DEVICES', 'Not set')}")
print(f"   LD_LIBRARY_PATH: {os.environ.get('LD_LIBRARY_PATH', 'Not set')}")

print(f"\n2. PyTorch Info:")
print(f"   Version: {torch.__version__}")
print(f"   CUDA compiled: {torch.version.cuda}")
print(f"   Python: {sys.executable}")

print(f"\n3. Testing torch._C import:")
try:
    import torch._C
    print("   ✓ torch._C imported")
except Exception as e:
    print(f"   ✗ Failed: {e}")
    sys.exit(1)

print(f"\n4. Testing CUDA initialization:")
try:
    # Try to initialize CUDA
    result = torch.cuda.is_available()
    print(f"   torch.cuda.is_available(): {result}")
    
    if result:
        print(f"   ✓ CUDA is available!")
        print(f"   Device count: {torch.cuda.device_count()}")
        print(f"   Device 0: {torch.cuda.get_device_name(0)}")
    else:
        print("   ✗ CUDA not available")
        print("\n5. Attempting manual initialization:")
        try:
            torch.cuda.init()
            print("   ✓ Manual init succeeded")
        except RuntimeError as e:
            print(f"   ✗ Manual init failed: {e}")
            print("\n6. Checking if it's a device enumeration issue:")
            # Try to see if we can at least load the CUDA libraries
            import ctypes
            try:
                # Try loading libcuda.so (NVIDIA driver library)
                libcuda = ctypes.CDLL('libcuda.so.1')
                print("   ✓ libcuda.so.1 can be loaded")
                
                # Try to get device count via ctypes
                cuDeviceGetCount = libcuda.cuDeviceGetCount
                cuDeviceGetCount.argtypes = [ctypes.POINTER(ctypes.c_int)]
                cuDeviceGetCount.restype = ctypes.c_int
                
                count = ctypes.c_int()
                result = cuDeviceGetCount(ctypes.byref(count))
                if result == 0:
                    print(f"   ✓ Direct CUDA API reports {count.value} devices")
                else:
                    print(f"   ✗ Direct CUDA API failed with code {result}")
            except Exception as e:
                print(f"   ✗ Cannot access CUDA driver: {e}")
                
except Exception as e:
    print(f"   ✗ Error: {e}")
    import traceback
    traceback.print_exc()

print("\n" + "=" * 60)
