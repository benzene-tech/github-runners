ARG TAG

FROM ghcr.io/actions/actions-runner-controller/actions-runner:$TAG

USER root

# Update APT
RUN apt-get update -y

# Install APT packages
RUN apt-get install -y wget zstd
