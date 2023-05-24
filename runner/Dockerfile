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

CMD ["/home/runner/run.sh"]
