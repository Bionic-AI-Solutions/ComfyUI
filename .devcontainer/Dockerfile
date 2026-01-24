# DevContainer Dockerfile
# Based on the golden image: docker4zerocool/ai-template:runtime
# Supports CUDA 12.8, NVIDIA, and sm_120 compute capability

FROM docker4zerocool/ai-template:runtime

# Switch to root for installations
USER root

# Fix permissions for apt
RUN chmod 755 /var/lib/apt/lists/partial || true && \
    mkdir -p /var/lib/apt/lists/partial || true

# Install system dependencies
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    git \
    vim \
    sudo \
    ca-certificates \
    gnupg \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# Install Docker CLI (to connect to host Docker daemon)
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce-cli && \
    rm -rf /var/lib/apt/lists/*

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/kubectl && \
    kubectl version --client

# Create devuser with sudo privileges (if not exists)
RUN if ! id -u devuser > /dev/null 2>&1; then \
        useradd -m -s /bin/bash devuser && \
        echo "devuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers; \
    fi

# Create docker group and add devuser to it
RUN groupadd -f docker && \
    usermod -aG docker devuser

# Copy post-create script
COPY .devcontainer/post-create.sh /usr/local/bin/post-create.sh
RUN chmod +x /usr/local/bin/post-create.sh

# Set working directory
WORKDIR /workspace

# Switch to devuser
USER devuser

# Verify installations
RUN wget --version && \
    docker --version && \
    kubectl version --client
