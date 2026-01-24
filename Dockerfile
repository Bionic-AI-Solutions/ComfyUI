# Multi-stage Dockerfile for ComfyUI
# Supports both GPU (CUDA) and CPU modes

# ============================================================================
# GPU stage - with CUDA support using golden image
# ============================================================================
# Uses the golden image: docker4zerocool/ai-template:runtime
# - CUDA 12.8.0
# - NVIDIA GPU support
# - Compute capability 12.0 (sm_120) support
# - Pre-configured Python environment with conda (wan22 environment)
FROM docker4zerocool/ai-template:runtime AS gpu

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Switch to root for installations
USER root

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    wget \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements first for better caching
COPY ComfyUI/requirements.txt /app/requirements.txt
COPY ComfyUI/manager_requirements.txt /app/manager_requirements.txt

# Activate conda environment and install Python dependencies
# The golden image has conda with wan22 environment and PyTorch 2.9.0+cu128 already installed
RUN /opt/conda/envs/wan22/bin/pip install --upgrade pip setuptools wheel && \
    /opt/conda/envs/wan22/bin/pip install -r /app/requirements.txt && \
    /opt/conda/envs/wan22/bin/pip install -r /app/manager_requirements.txt

# Verify PyTorch CUDA is available (will show False without GPU runtime, but PyTorch has CUDA support)
RUN /opt/conda/envs/wan22/bin/python -c "import torch; print(f'PyTorch: {torch.__version__}, CUDA compiled: {torch.version.cuda}')" || true

# Copy ComfyUI application
COPY ComfyUI/ /app/ComfyUI/

# Set working directory to ComfyUI
WORKDIR /app/ComfyUI

# Create necessary directories
RUN mkdir -p models/checkpoints \
    models/vae \
    models/loras \
    models/embeddings \
    models/clip \
    models/controlnet \
    models/upscale_models \
    models/vae_approx \
    input \
    output \
    custom_nodes

# Expose port
EXPOSE 8188

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8188/ || exit 1

# Don't use nvidia entrypoint - it interferes with GPU access
# Override nvidia entrypoint from base image (it interferes with GPU access in docker-compose)
# Keep nvidia entrypoint for proper CUDA initialization
ENTRYPOINT ["/opt/nvidia/nvidia_entrypoint.sh"]

# Use Python from conda environment directly
# Run ComfyUI with GPU support
CMD ["/opt/conda/envs/wan22/bin/python", "main.py", "--listen", "0.0.0.0", "--port", "8188", "--preview-method", "auto", "--enable-manager", "--enable-manager"]

# ============================================================================
# CPU stage - without CUDA (for systems without GPU)
# ============================================================================
FROM python:3.12-slim AS cpu

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    wget \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements first for better caching
COPY ComfyUI/requirements.txt /app/requirements.txt
COPY ComfyUI/manager_requirements.txt /app/manager_requirements.txt

# Install Python dependencies
RUN pip install --upgrade pip setuptools wheel && \
    pip install -r /app/requirements.txt && \
    pip install -r /app/manager_requirements.txt

# Install PyTorch CPU version
RUN pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu

# Copy ComfyUI application
COPY ComfyUI/ /app/ComfyUI/

# Set working directory to ComfyUI
WORKDIR /app/ComfyUI

# Create necessary directories
RUN mkdir -p models/checkpoints \
    models/vae \
    models/loras \
    models/embeddings \
    models/clip \
    models/controlnet \
    models/upscale_models \
    models/vae_approx \
    input \
    output \
    custom_nodes

# Expose port
EXPOSE 8188

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8188/ || exit 1

# Run ComfyUI in CPU mode
CMD ["/opt/conda/envs/wan22/bin/python", "main.py", "--listen", "0.0.0.0", "--port", "8188", "--preview-method", "auto", "--enable-manager"]
