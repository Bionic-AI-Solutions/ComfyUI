# GPU and Golden Image Test Results

## ✅ Golden Image Verification

The golden image `docker4zerocool/ai-template:runtime` has been tested and **CUDA is working correctly**:

```bash
docker run --rm --runtime=nvidia --gpus=all docker4zerocool/ai-template:runtime \
  /opt/conda/envs/wan22/bin/python -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}')"
```

**Results:**
- ✅ PyTorch: 2.9.0+cu128
- ✅ CUDA available: True
- ✅ CUDA version: 12.8
- ✅ Device count: 2
- ✅ Device name: NVIDIA RTX PRO 6000 Blackwell Workstation Edition
- ✅ Successfully created CUDA tensor on GPU

## ✅ Dockerfile Verification

The Dockerfile correctly uses the golden image:
```dockerfile
FROM docker4zerocool/ai-template:runtime AS gpu
```

## ⚠️ Docker Compose Issue

Docker Compose is not properly passing GPU access to the container, even with:
- `runtime: nvidia`
- `deploy.resources.reservations.devices` with nvidia driver

The container shows DeviceRequests are set correctly, but CUDA is not accessible inside the container.

## ✅ Working Solution: Direct Docker Run

Use this command to run ComfyUI with GPU support:

```bash
docker run -d \
  --name comfyui-gpu \
  --runtime=nvidia \
  --gpus=all \
  -p 8188:8188 \
  -v $(pwd)/ComfyUI/models:/app/ComfyUI/models \
  -v $(pwd)/ComfyUI/input:/app/ComfyUI/input \
  -v $(pwd)/ComfyUI/output:/app/ComfyUI/output \
  -v $(pwd)/ComfyUI/custom_nodes:/app/ComfyUI/custom_nodes \
  -e CUDA_VISIBLE_DEVICES=all \
  -e NVIDIA_VISIBLE_DEVICES=all \
  -e NVIDIA_DRIVER_CAPABILITIES=compute,utility \
  workspace-comfyui-gpu \
  /opt/conda/envs/wan22/bin/python main.py --listen 0.0.0.0 --port 8188 --preview-method auto --enable-manager
```

Then access ComfyUI at: `http://localhost:8188`

## Summary

- ✅ Golden image has working CUDA
- ✅ Dockerfile uses golden image correctly  
- ⚠️ Docker Compose GPU configuration needs fixing
- ✅ Direct docker run works perfectly
