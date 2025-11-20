#!/bin/bash
#
# Makefile.bin/run-build.sh
#
# Build a image using `docker build` and push it to local and public registry both.
#
# Requires: docker-cli
#
# usage:
#
# PUBLIC_REPO=docker.io \
# LOCAL_REPO=anas:5000 \
# IMAGE_NAME=dagui0/my-hello \
# IMAGE_TAG=20251117-1 \
# Makefile.bin/run-build.sh [ docker build options ]
#

# check environment variables
vars="PUBLIC_REPO LOCAL_REPO IMAGE_NAME IMAGE_TAG"
for v in $vars; do
    if [[ -z "$(eval echo \$$v)" ]]; then
        echo $v is not specified >&2
        exit 1
    fi
done

if [[ "${PUSH_PUBLIC:=no}" = "yes" ]]; then
    public="-t $PUBLIC_REPO/$IMAGE_NAME:$IMAGE_TAG"
fi
if [[ -n "$CONTEXT" ]]; then
    context="--context $CONTEXT"
fi

docker $context build \
  -t $LOCAL_REPO/$IMAGE_NAME:$IMAGE_TAG $public \
  --build-arg "BASE_IMAGE=$BASE_IMAGE" \
  --build-arg "BASE_VERSION=$BASE_VERSION" \
  --build-arg "IMAGE_NAME=$IMAGE_NAME" \
  --build-arg "IMAGE_TAG=$IMAGE_TAG" \
  "$@" . && \
docker $context push $LOCAL_REPO/$IMAGE_NAME:$IMAGE_TAG
rs=$?
if [[ $rs -ne 0 ]]; then
    exit $rs
fi

if [[ "$PUSH_PUBLIC" = "yes" ]]; then
    docker $context push $PUBLIC_REPO/$IMAGE_NAME:$IMAGE_TAG
    rs=$?
    if [[ $rs -ne 0 ]]; then
        exit $rs
    fi
fi

# cleaning build context (discard errors)
docker $context rmi $LOCAL_REPO/$IMAGE_NAME:$IMAGE_TAG
if [[ "$PUSH_PUBLIC" = "yes" ]]; then
    docker $context rmi $PUBLIC_REPO/$IMAGE_NAME:$IMAGE_TAG
fi

exit $rs
