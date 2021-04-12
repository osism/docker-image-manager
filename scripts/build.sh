#!/usr/bin/env bash
set -x

# Available environment variables
#
# AWX_VRSION
# BUILD_OPTS
# CEPH_VERSION
# DOCKER_REGISTRY
# OPENSTACK_VERSION
# RELEASE_OSISM
# REPOSITORY
# VERSION

# Set default values

AWX_VERSION=${AWX_VERSION:-latest}
BUILD_OPTS=${BUILD_OPTS:-}
CEPH_VERSION=${CEPH_VERSION:-octopus}
CREATED=$(date --rfc-3339=ns)
DOCKER_REGISTRY=${DOCKER_REGISTRY:-quay.io}
OPENSTACK_VERSION=${OPENSTACK_VERSION:-victoria}
RELEASE_OSISM=${RELEASE_OSISM:-latest}
REPOSITORY=${REPOSITORY:-osism/manager}
REVISION=$(git rev-parse --short HEAD)
VERSION=${VERSION:-latest}

if [[ -n $DOCKER_REGISTRY ]]; then
    REPOSITORY="$DOCKER_REGISTRY/$REPOSITORY"
fi

docker buildx build \
    --load \
    --build-arg "AWX_VERSION=$AWX_VERSION" \
    --build-arg "RELEASE_CEPH=$CEPH_VERSION" \
    --build-arg "RELEASE_OPENSTACK=$OPENSTACK_VERSION" \
    --build-arg "RELEASE_OSISM=$RELEASE_OSISM" \
    --tag "$REPOSITORY:$VERSION" \
    --label "org.opencontainers.image.created=$CREATED" \
    --label "org.opencontainers.image.documentation=https://docs.osism.de" \
    --label "org.opencontainers.image.licenses=ASL 2.0" \
    --label "org.opencontainers.image.revision=$REVISION" \
    --label "org.opencontainers.image.source=https://github.com/osism/container-image-manager" \
    --label "org.opencontainers.image.title=manager" \
    --label "org.opencontainers.image.url=https://www.osism.de" \
    --label "org.opencontainers.image.vendor=Betacloud Solutions GmbH" \
    --label "org.opencontainers.image.version=$VERSION" \
    --file Dockerfile $BUILD_OPTS .
