#!/bin/bash
#
# Makefile.bin/merge-tags.sh
#
# Create image index(manifest list) and remove os-specific tags.
#
# Requires: regctl
#
# usage:
#
# REPO=docker.io \
# IMAGE_NAME=dagui0/my-hello \
# IMAGE_TAG=20251117-1 \
# Makefile.bin/merge-tags.sh temp_tags ...

# You can run regctl via docker without install
#regctl="docker run --it --rm --net host -v regctl-conf:/home/appuser/.regctl/ regclient/regctl:latest"
# Or you can install locally for better experience
# see https://regclient.org/install/#downloading-binaries
regctl=/usr/local/bin/regctl

# regctl index type default is OCI standard
#media_type='application/vnd.oci.image.index.v1+json'
# To create docker manifest list use this
media_type='application/vnd.docker.distribution.manifest.list.v2+json'

# check environment variables
vars="REPO IMAGE_NAME IMAGE_TAG"
for v in $vars; do
    if [[ -z "$(eval echo \$$v)" ]]; then
        echo $v is not specified >&2
        exit 1
    fi
done

if [[ "${SET_LATEST:=no}" = "yes" ]]; then
    latest="$REPO/$IMAGE_NAME:latest"
fi

find_ver() {
    case $1 in
        ltsc2019|2019)
            echo 10.0.17763.8027
            ;;
        ltsc2022|2022)
            echo 10.0.20348.4405
            ;;
        ltsc2025|2025)
            echo 10.0.26100.7171
            ;;
        *)
            echo $1
    esac
}

imgs=
for tag in "$@"; do
    IFS=- read -ra tag_part <<< "$tag"
    case ${tag_part[0]} in
        linux)
            imgs="$imgs --ref $REPO/$IMAGE_NAME:$tag"
            IFS=, read -ra archs <<<"$LINUX_ARCHS"
            for arch in "${archs[@]}"; do
                imgs="$imgs --platform $arch"
            done
            ;;
        windows)
            imgs="$imgs --ref $REPO/$IMAGE_NAME:$tag --platform windows/amd64"
            osver=$(find_ver ${tag_part[1]})
            if [[ -n "$osver" ]]; then
                imgs="${imgs},osver=$osver"
            fi
            ;;
        *)
            imgs="$imgs --ref $REPO/$IMAGE_NAME:$tag"
    esac
done

# Create merged manifest
for target in $REPO/$IMAGE_NAME:$IMAGE_TAG $latest; do
    echo $regctl index create --media-type $media_type $target $imgs
    $regctl index create --media-type $media_type $target $imgs
    rs=$?
    if [[ $rs -ne 0 ]]; then
        exit $rs
    fi
done

# Remove temp tags (discard errors)
if [ "${RM_OS_TAGS:=yes}" = "yes" ]; then
    for tag in "$@"; do
        echo $regctl tag delete $REPO/$IMAGE_NAME:$tag
        $regctl tag delete $REPO/$IMAGE_NAME:$tag
    done
fi

exit $rs
