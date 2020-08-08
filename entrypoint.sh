#!/bin/sh -l

set -o errexit -o nounset

DOCKER_PASSWORD=$1
DOCKER_REGISTRY=$2
DOCKER_USERNAME=$3
dockerfile=$4
image=$5

default_image_cache="$image:cache"
image_cache=${6:-$default_image_cache}

living_tag=$7

tags=${8:-latest}

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

IFS=,

# get the first element in $tags
for t in $tags; do tag=$t; break; done

tagged_image_array=''
tag_args=''
for t in $tags; do
  tagged_image_array="${tagged_image_array:+${tagged_image_array},}$image:$t"
  tag_args="${tag_args:+${tag_args} }--tag $image:$t"
done

unset IFS

if [ "$living_tag" = 'true' ]; then
  echo ::debug:: Option living_tag was true so skip check with registry to see if image already exists!
  build_and_push=true
else
  echo ::debug:: Using first tag to see if image already exists: "$tag"
  if docker pull -q "$image:${tag}" > /dev/null; then
    echo ::debug:: image fetch succeeded!
    build_and_push=false
  else
    echo ::debug:: remote image "$image:$tag" was not available, starting image build...
    build_and_push=true
  fi
fi

if [ "$build_and_push" = 'true' ]; then
  # shellcheck disable=SC2086
  docker buildx build \
    --cache-from "type=registry,ref=$image_cache" \
    --cache-to "type=registry,ref=$image_cache,mode=max" \
    --file "$dockerfile" \
    --load \
    --progress=plain \
    ${tag_args} \
    "$GITHUB_WORKSPACE"
  echo ::debug:: image build succeeded!

  echo ::debug:: pushing images...
  IFS=,
  for tagged_image in $tagged_image_array; do
    docker push "$tagged_image"
  done
  unset IFS

  echo ::debug:: image pushes succeeded!
fi

echo ::set-output name=image_id::"$(docker image ls "$image:$tag" -q)"
