# Docker buildx pull or build action

![Test](https://github.com/djbender/docker-buildx-pull-or-build/workflows/Test/badge.svg)

This action sets up a docker buildx builder, sets it as the default builder, the either pulls an existing image from a remote repository, or builds it with buildx using its new build-cache caching mechanisms. Finally, the resulting image is published.

## Inputs

### `docker_username`

The username to authenticate with the registry. Required _if_ `docker_config_json` is blank.

### `docker_password`

The password to authenticate with the registry. Required _if_ `docker_config_json` is blank.'

### `docker_registry`

The remote registry for pulling and pushing images. Default: `''` (hub.docker.com).

### `dockerfile`

**Required** The Dockerfile to build when the remote image is not available.

### `image`

**Required** The image name that this action will either 1) pull 2) build and push.

### `image_cache`

Optionally specify an image cache name. Default: `<image>:cache`

### `living_tag`

Optionally skip the initial `docker pull` because this tag is not immutable (i.e.: `latest`, `stable-1.0`). Default: `'false'`"

### `docker_config_json`

Optionally authenticate with existing stored credentials by serializing `~/.docker/config.json`. If present, this will override the `docker_username` and `docker_password` inputs. E.g.: `$(cat ~/.docker/config.json)` or `"{\"auths\":{\"https://index.docker.io/v1/\":{\"auth\":\"SEKRET\"}}}"`.

## Outputs

### `image_id`

The Image ID that has been loaded into the local docker engine

## Example usage

    - name: Docker Buildx Pull or Build
      uses: djbender/docker-buildx-pull-or-build@v0.1
      with:
        docker_username: djbender
        docker_password: ${{ secrets.DOCKER_PASSWORD }}
        docker_registry: ${{ env.DOCKER_REGISTRY }}
        dockerfile: test.Dockerfile
        image: djbender/docker-buildx-pull-or-build-test-dockerfile
