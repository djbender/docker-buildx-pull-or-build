#!/bin/sh -l

set -o errexit

DOCKER_USERNAME=$1
DOCKER_PASSWORD=$2
DOCKER_REGISTRY=$3
image=$4
dockerfile=$5

default_image_cache="$image:cache"
image_cache=${6:-$default_image_cache}

# act will by default change $HOME to /github/home which
# is not where the buildx cli-plugin is located
export DOCKER_CONFIG=/root/.docker

echo ::debug:: Logging in to "${DOCKER_REGISTRY:-Docker Hub}" ...
docker_login_log=mktmp
echo "$DOCKER_PASSWORD" | docker login \
  --username "$DOCKER_USERNAME" \
  --password-stdin "$DOCKER_REGISTRY" > $docker_login_log 2>&1 \
  \
  || docker_login_result=$?

[ ${docker_login_result:-0} = 1 ] && cat $docker_login_log
rm $docker_login_log
[ ${docker_login_result:-0} = 1 ] && exit $docker_login_result
echo ::debug:: Log in succeeded!

echo ::debug:: Creating buildx 'docker-container' builder...
docker buildx create --name builder --driver docker-container --use > /dev/null
docker buildx install
echo ::debug:: Builder creation succeeded!

echo ::debug:: pulling "$image" ...
if docker pull -q "$image" > /dev/null; then
  echo ::debug:: image fetch succeeded!
else
  echo ::debug:: remote image "$image" was not available, starting image build...
  docker buildx build \
    --cache-from "type=registry,ref=$image_cache" \
    --cache-to "type=registry,ref=$image_cache,mode=max" \
    --file "$dockerfile" \
    --load \
    --progress=plain \
    --tag "$image" \
    "$GITHUB_WORKSPACE"
  echo ::debug:: image build succeeded!

  echo ::debug:: pushing image...
  docker push "$image"
  echo ::debug:: image push succeeded!
fi

echo ::set-output name=image_id::"$(docker image ls "$image" -q)"
