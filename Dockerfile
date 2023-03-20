ARG TAG

FROM ghcr.io/actions/actions-runner-controller/actions-runner:$TAG

RUN sudo apt-get update -y && sudo apt-get install -y \
    wget \
    zstd \
    && sudo rm -rf /var/lib/apt/lists/*
