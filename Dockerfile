ARG TAG

FROM ghcr.io/actions/actions-runner-controller/actions-runner:$TAG

USER root

RUN apt-get update -y \
    && apt-get install -y wget zstd \
    && rm -rf /var/lib/apt/lists/*
