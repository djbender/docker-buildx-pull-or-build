#!/bin/sh -l

set -o errexit

DOCKER_PASSWORD=$1
DOCKER_REGISTRY=$2
DOCKER_USERNAME=$3
dockerfile=$4
image=$5

default_image_cache="$image:cache"
image_cache=${6:-$default_image_cache}

living_tag=$7
docker_config_json=$8
cache=${9:-true}

# act will by default change $HOME to /github/home which
# is not where the buildx cli-plugin is located
export DOCKER_CONFIG=/root/.docker

echo Logging in to "${DOCKER_REGISTRY:-Docker Hub}" ...
docker_login_log=mktmp

if [ "$docker_config_json" = '' ]; then
  echo "docker_config_json was blank so logging in with username and password..."
  echo "$DOCKER_PASSWORD" | docker login \
    --username "$DOCKER_USERNAME" \
    --password-stdin "$DOCKER_REGISTRY" > $docker_login_log 2>&1 \
    \
    || docker_login_result=$?
else
  echo "Using docker_config_json to authenticate with registry..."
  jq --null-input --tab "$docker_config_json" > /root/.docker/config.json
  docker login "$DOCKER_REGISTRY" > $docker_login_log 2>&1 \
    || docker_login_result=$?
fi

[ ${docker_login_result:-0} = 1 ] && cat $docker_login_log
rm $docker_login_log
[ ${docker_login_result:-0} = 1 ] && exit $docker_login_result
echo Log in succeeded!

echo Creating buildx 'docker-container' builder...
docker buildx create --name builder --driver docker-container --use > /dev/null
docker buildx install
echo Builder creation succeeded!

if [ "$living_tag" != 'true' ] \
  && [ "$cache" != 'false' ] \
  && echo "Pulling $image..." \
  && docker pull -q "$image" > /dev/null; then

  echo Image fetch succeeded!
else
  if [ "$living_tag" = 'true' ]; then
    # shellcheck disable=SC2016
    echo '`living_tag` was true! Skipping `docker pull` and starting image build...'
  elif [ "$cache" = 'true' ]; then
    # shellcheck disable=SC2016
    echo '`cache` was true! Skipping all caching mechanisms...'
    no_cache_flags='--pull --no-cache'
  else
    echo Remote image "$image" was not available, starting image build...
  fi

  # word splitting is intentional here
  # shellcheck disable=2086
  docker buildx build \
    --cache-from "type=registry,ref=$image_cache" \
    --cache-to "type=registry,ref=$image_cache,mode=max" \
    --file "$dockerfile" \
    --load \
    --progress=plain \
    --tag "$image" \
    ${no_cache_flags:-} \
    "$GITHUB_WORKSPACE"
  echo Image build succeeded!

  echo Pushing image...
  docker push "$image"
  echo Image push succeeded!
fi

image_id=$(docker image ls "$image" -q | head -n 1)
# if $image failed to pull or build, fail this script
[ "$image" = '' ] && exit 1
echo "::set-output name=image_id::$image_id"
