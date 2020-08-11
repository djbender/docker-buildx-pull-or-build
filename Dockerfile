FROM docker:19.03
ARG DOCKER_BUILDX_VERSION=0.4.1
ENV DOCKER_CLI_EXPERIMENTAL enabled

RUN set -exu; \
  \
  apk add --no-cache jq \
  && mkdir -p $HOME/.docker/cli-plugins \
  && wget -q -O $HOME/.docker/cli-plugins/docker-buildx https://github.com/docker/buildx/releases/download/v${DOCKER_BUILDX_VERSION}/buildx-v${DOCKER_BUILDX_VERSION}.linux-amd64 \
  && chmod a+x $HOME/.docker/cli-plugins/docker-buildx

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
