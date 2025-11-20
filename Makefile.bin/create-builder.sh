#!/bin/bash
#
# Makefile.bin/create-builder.sh
#
# Create multiplatform builder container on build hosts.
#
# Requires: docker-buildx-pligin
#
usage() {
    cat <<ENDOFFILE
usage: [ CONTEXT=context ] [ LOCAL_REPO=repo ] $0 builder_name <<EOF
anas  ssh://anas       linux/arm64,linux/arm/v7,linux/arm/v6
xvms  tcp://xvms:2375  linux/amd64,linux/amd64/v2,linux/riscv64,linux/ppc64,linux/ppc64le,linux/s390x,linux/386,linux/loong64
EOF
ENDOFFILE
}

if [[ -n "$CONTEXT" ]]; then
    context="--context $CONTEXT"
fi
if [[ ! -f buildkitd.toml && -n "$LOCAL_REPO" && "$LOCAL_REPO" == *":"* ]]; then
    # Create config file
    cat <<EOF >buildkitd.toml
[registry."${LOCAL_REPO}"]
  http = true
  insecure = true
EOF
fi
if [[ -f buildkitd.toml ]]; then
    config="--buildkitd-config buildkitd.toml"
    echo "Applying buildkitd.toml"
    cat buildkitd.toml
fi

BUILDER=$1
if [[ $# -lt 1 ]]; then
    usage >&2
    exit 1
fi

line=0
while read node_name endpoint platforms; do
    if [[ -z "$node_name" ]]; then
        continue
    fi
    platforms="$(echo $platforms | sed -e 's/[ \t]//g')"
    if [[ $line -eq 0 ]]; then
        echo docker $context buildx create --name $BUILDER \
          --driver docker-container $config \
          --node "$node_name" --bootstrap --platform "$platforms" "$endpoint"
        docker $context buildx create --name $BUILDER \
          --driver docker-container $config \
          --node "$node_name" --bootstrap --platform "$platforms" "$endpoint"
        rs=$?
        if [[ $rs -ne 0 ]]; then
            exit $rs
        fi
    else
        echo docker $context buildx create --name $BUILDER --append $config \
          --node "$node_name" --bootstrap --platform "$platforms" "$endpoint"
        docker $context buildx create --name $BUILDER --append $config \
          --node "$node_name" --bootstrap --platform "$platforms" "$endpoint"
        rs=$?
        if [[ $rs -ne 0 ]]; then
            exit $rs
        fi
    fi
    line=$(( $line + 1 ))
done
