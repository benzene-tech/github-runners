ARG TAG

FROM ghcr.io/actions/actions-runner-controller/actions-runner:$TAG

WORKDIR /home/runner

COPY configure-runners.sh ./

RUN bash configure-runners.sh

RUN rm -f configure-runners.sh
