FROM ghcr.io/actions/actions-runner:latest

RUN sudo apt-get update -y && sudo apt-get install -y --no-install-recommends \
    curl \
    wget \
    git \
    jq \
    zip \
    unzip \
    zstd \
    python3 \
    && sudo rm -rf /var/lib/apt/lists/*

RUN sudo wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq \
    && sudo chmod +x /usr/bin/yq

CMD ["/home/runner/run.sh"]
