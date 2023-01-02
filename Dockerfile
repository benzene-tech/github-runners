ARG TAG

FROM ghcr.io/actions/actions-runner-controller/actions-runner:$TAG

COPY --from=docker/buildx-bin /buildx /usr/libexec/docker/cli-plugins/docker-buildx

RUN docker buildx install
