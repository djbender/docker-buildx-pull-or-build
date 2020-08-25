FROM docker:19.03
ARG DOCKER_BUILDX_VERSION=0.4.1
ENV DOCKER_CLI_EXPERIMENTAL enabled

RUN set -eux; \
  \
  apk add --no-cache jq \
  && mkdir -p $HOME/.docker/cli-plugins \
  && wget -O $HOME/.docker/cli-plugins/docker-buildx https://github.com/docker/buildx/releases/download/v${DOCKER_BUILDX_VERSION}/buildx-v${DOCKER_BUILDX_VERSION}.linux-amd64 \
  && chmod a+x $HOME/.docker/cli-plugins/docker-buildx \
# verify commands work \
  && docker --version \
  && docker buildx version

COPY entrypoint.sh /entrypoint.sh
# ENTRYPOINT must always be `["entrypoint.sh"]` or else act straight up won't work
ENTRYPOINT ["/entrypoint.sh"]
