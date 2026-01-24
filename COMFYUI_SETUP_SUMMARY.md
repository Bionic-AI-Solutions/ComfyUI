# ComfyUI Docker Setup Summary

## ✅ Completed Setup

1. **Golden Image Verified**: `docker4zerocool/ai-template:runtime` has working CUDA
2. **Model Storage**: Created `/mnt/ai-models/comfyui/models/` with all required directories
3. **Dockerfile**: Uses golden image, properly configured
4. **Docker Compose**: Configured with `runtime: nvidia` (same as other AI containers)

## ⚠️ Current Issue

Docker Compose is not properly passing GPU access to the container, even though:
- Configuration matches other working AI containers (`runtime: nvidia`)
- Direct `docker run` with `--runtime=nvidia --gpus=all` works perfectly
- Golden image has CUDA support verified

## ✅ Working Solution

Use direct docker run command (same pattern as other AI containers):

```bash
docker run -d \
  --name comfyui-gpu \
  --runtime=nvidia \
  -p 8188:8188 \
  -v /mnt/ai-models/comfyui/models:/app/ComfyUI/models \
  -v $(pwd)/ComfyUI/input:/app/ComfyUI/input \
  -v $(pwd)/ComfyUI/output:/app/ComfyUI/output \
  -v $(pwd)/ComfyUI/custom_nodes:/app/ComfyUI/custom_nodes \
  -e CUDA_VISIBLE_DEVICES=all \
  -e NVIDIA_VISIBLE_DEVICES=all \
  -e NVIDIA_DRIVER_CAPABILITIES=compute,utility \
  workspace-comfyui-gpu \
  /opt/conda/envs/wan22/bin/python main.py --listen 0.0.0.0 --port 8188 --preview-method auto --enable-manager
```

## Model Storage

Models are stored in `/mnt/ai-models/comfyui/models/` with the following structure:
- `checkpoints/` - Main model checkpoints
- `vae/` - VAE models
- `loras/` - LoRA models
- `embeddings/` - Text embeddings
- `controlnet/` - ControlNet models
- `upscale_models/` - Upscaling models
- And all other ComfyUI model directories

## Access

Once running, access ComfyUI at: `http://localhost:8188`

## Verification

To verify GPU access:
```bash
docker exec comfyui-gpu /opt/conda/envs/wan22/bin/python -c "import torch; print(f'CUDA: {torch.cuda.is_available()}')"
```

Expected: `CUDA: True`
