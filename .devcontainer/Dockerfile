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


# Create post-create script inline (to avoid .dockerignore issues)
RUN echo "IyEvYmluL2Jhc2gKIyBQb3N0LWNyZWF0ZSBzY3JpcHQgZm9yIGRldmNvbnRhaW5lcgojIFRoaXMgc2NyaXB0IHJ1bnMgYWZ0ZXIgdGhlIGNvbnRhaW5lciBpcyBjcmVhdGVkCgpzZXQgLWUKCmVjaG8gIvCflKcgU2V0dGluZyB1cCBkZXZjb250YWluZXIuLi4iCgojIEZpeCBwZXJtaXNzaW9ucyBmb3Iga3ViZSBjb25maWcKaWYgWyAtZCAiL2hvbWUvZGV2dXNlci8ua3ViZSIgXTsgdGhlbgogICAgc3VkbyBjaG93biAtUiBkZXZ1c2VyOmRldnVzZXIgL2hvbWUvZGV2dXNlci8ua3ViZSAyPi9kZXYvbnVsbCB8fCB0cnVlCiAgICBpZiBbIC1mICIvaG9tZS9kZXZ1c2VyLy5rdWJlL2NvbmZpZyIgXTsgdGhlbgogICAgICAgIHN1ZG8gY2htb2QgNjAwIC9ob21lL2RldnVzZXIvLmt1YmUvY29uZmlnIDI+L2Rldi9udWxsIHx8IHRydWUKICAgIGZpCmZpCgojIEZpeCB3b3Jrc3BhY2UgcGVybWlzc2lvbnMKaWYgWyAtZCAiL3dvcmtzcGFjZSIgXTsgdGhlbgogICAgc3VkbyBjaG93biAtUiBkZXZ1c2VyOmRldnVzZXIgL3dvcmtzcGFjZSAyPi9kZXYvbnVsbCB8fCB0cnVlCmZpCgojIEZpeCBEb2NrZXIgc29ja2V0IHBlcm1pc3Npb25zCmlmIFsgLVMgIi92YXIvcnVuL2RvY2tlci5zb2NrIiBdOyB0aGVuCiAgICBlY2hvICLwn5SnIEZpeGluZyBEb2NrZXIgc29ja2V0IHBlcm1pc3Npb25zLi4uIgogICAgSE9TVF9ET0NLRVJfR0lEPSQoc3RhdCAtYyAnJWcnIC92YXIvcnVuL2RvY2tlci5zb2NrIDI+L2Rldi9udWxsIHx8IGVjaG8gIiIpCiAgICBDT05UQUlORVJfRE9DS0VSX0dJRD0kKGdldGVudCBncm91cCBkb2NrZXIgfCBjdXQgLWQ6IC1mMyAyPi9kZXYvbnVsbCB8fCBlY2hvICIiKQogICAgCiAgICBpZiBbIC1uICIkSE9TVF9ET0NLRVJfR0lEIiBdICYmIFsgLW4gIiRDT05UQUlORVJfRE9DS0VSX0dJRCIgXSAmJiBbICIkSE9TVF9ET0NLRVJfR0lEIiAhPSAiJENPTlRBSU5FUl9ET0NLRVJfR0lEIiBdOyB0aGVuCiAgICAgICAgZWNobyAiICAgRG9ja2VyIGdyb3VwIEdJRCBtaXNtYXRjaCBkZXRlY3RlZCAoaG9zdDogJEhPU1RfRE9DS0VSX0dJRCwgY29udGFpbmVyOiAkQ09OVEFJTkVSX0RPQ0tFUl9HSUQpIgogICAgICAgIGVjaG8gIiAgIEF0dGVtcHRpbmcgdG8gYWRqdXN0IHBlcm1pc3Npb25zLi4uIgogICAgICAgIHN1ZG8gY2htb2QgNjY2IC92YXIvcnVuL2RvY2tlci5zb2NrIDI+L2Rldi9udWxsIHx8IHRydWUKICAgIGVsc2UKICAgICAgICBzdWRvIGNobW9kIDY2NiAvdmFyL3J1bi9kb2NrZXIuc29jayAyPi9kZXYvbnVsbCB8fCB0cnVlCiAgICBmaQogICAgCiAgICBpZiBkb2NrZXIgcHMgJj4vZGV2L251bGw7IHRoZW4KICAgICAgICBlY2hvICLinIUgRG9ja2VyIGFjY2VzcyB2ZXJpZmllZCIKICAgIGVsc2UKICAgICAgICBlY2hvICLimqDvuI8gIERvY2tlciBhY2Nlc3MgbWF5IHJlcXVpcmUgY29udGFpbmVyIHJlc3RhcnQiCiAgICAgICAgZWNobyAiICAgWW91IGNhbiBtYW51YWxseSBmaXggd2l0aDogc3VkbyBjaG1vZCA2NjYgL3Zhci9ydW4vZG9ja2VyLnNvY2siCiAgICBmaQpmaQoKZWNobyAi8J+UjSBDaGVja2luZyBHUFUgYXZhaWxhYmlsaXR5Li4uIgppZiBudmlkaWEtc21pICY+IC9kZXYvbnVsbDsgdGhlbgogICAgZWNobyAi4pyFIEdQVSBkZXRlY3RlZDoiCiAgICBudmlkaWEtc21pIC0tcXVlcnktZ3B1PW5hbWUsZHJpdmVyX3ZlcnNpb24sY29tcHV0ZV9jYXAgLS1mb3JtYXQ9Y3N2LG5vaGVhZGVyIHwgaGVhZCAtMQogICAgZXhwb3J0IENVREFfVklTSUJMRV9ERVZJQ0VTPWFsbAogICAgZXhwb3J0IE5WSURJQV9WSVNJQkxFX0RFVklDRVM9YWxsCiAgICBleHBvcnQgTlZJRElBX0RSSVZFUl9DQVBBQklMSVRJRVM9Y29tcHV0ZSx1dGlsaXR5CiAgICBlY2hvICLinIUgR1BVIHN1cHBvcnQgZW5hYmxlZCAoc21fMTIwIGNvbXB1dGUgY2FwYWJpbGl0eSBzdXBwb3J0ZWQpIgogICAgZWNobyAiICAgR1BVIGFjY2VzcyB2ZXJpZmllZCAtIE5WSURJQSBDb250YWluZXIgVG9vbGtpdCBpcyB3b3JraW5nIGNvcnJlY3RseSIKZWxzZQogICAgZWNobyAi4p2MIEVSUk9SOiBHUFUgbm90IGF2YWlsYWJsZSBpbiBjb250YWluZXIiCiAgICBlY2hvICIgICBUaGUgY29udGFpbmVyIHdhcyBzdGFydGVkIHdpdGggLS1ncHVzPWFsbCwgYnV0IEdQVSBhY2Nlc3MgZmFpbGVkLiIKICAgIGVjaG8gIiAgIFRoaXMgbWF5IGluZGljYXRlOiIKICAgIGVjaG8gIiAgIDEuIE5WSURJQSBkcml2ZXJzIG5vdCBpbnN0YWxsZWQgb24gaG9zdCAocnVuOiBudmlkaWEtc21pKSIKICAgIGVjaG8gIiAgIDIuIE5WSURJQSBDb250YWluZXIgVG9vbGtpdCBtaXNjb25maWd1cmVkIgogICAgZWNobyAiICAgMy4gRG9ja2VyIGRhZW1vbiBuZWVkcyByZXN0YXJ0IChzdWRvIHN5c3RlbWN0bCByZXN0YXJ0IGRvY2tlcikiCiAgICBlY2hvICIiCiAgICBlY2hvICIgICBDaGVja2luZyBob3N0IEdQVSBzdGF0dXMuLi4iCiAgICBlY2hvICIgICBDb250YWluZXIgd2lsbCBjb250aW51ZSwgYnV0IEdQVSBmZWF0dXJlcyB3aWxsIG5vdCB3b3JrLiIKZmkKCmVjaG8gIuKchSBEZXZjb250YWluZXIgc2V0dXAgY29tcGxldGUhIgo=" | base64 -d > /usr/local/bin/post-create.sh && chmod +x /usr/local/bin/post-create.sh

# Set working directory
WORKDIR /workspace
