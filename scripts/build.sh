#!/usr/bin/env bash
set -x

# Available environment variables
#
# BUILD_OPTS
# DOCKER_REGISTRY
# REPOSITORY
# VERSION
# VERSION_AWX
# RELEASE_CEPH
# RELEASE_OPENSTACK
# RELEASE_OSISM

# Set default values

BUILD_OPTS=${BUILD_OPTS:-}
CREATED=$(date --rfc-3339=ns)
DOCKER_REGISTRY=${DOCKER_REGISTRY:-quay.io}
RELEASE_CEPH=${RELEASE_CEPH:-nautilus}
RELEASE_OPENSTACK=${RELEASE_OPENSTACK:-train}
RELEASE_OSISM=${RELEASE_OSISM:-latest}
REPOSITORY=${REPOSITORY:-osism/manager}
REVISION=$(git rev-parse --short HEAD)
VERSION=${VERSION:-latest}
VERSION_AWX=${VERSION_AWX:-latest}

if [[ -n $TRAVIS_TAG ]]; then
    VERSION=${TRAVIS_TAG:1}
fi

if [[ -n $DOCKER_REGISTRY ]]; then
    REPOSITORY="$DOCKER_REGISTRY/$REPOSITORY"
fi

docker build \
    --build-arg "VERSION_AWX=$VERSION_AWX" \
    --build-arg "RELEASE_CEPH=$RELEASE_CEPH" \
    --build-arg "RELEASE_OPENSTACK=$RELEASE_OPENSTACK" \
    --build-arg "RELEASE_OSISM=$RELEASE_OSISM" \
    --tag "$REPOSITORY:$VERSION" \
    --label "org.opencontainers.image.created=$CREATED" \
    --label "org.opencontainers.image.documentation=https://docs.osism.de" \
    --label "org.opencontainers.image.licenses=ASL 2.0" \
    --label "org.opencontainers.image.revision=$REVISION" \
    --label "org.opencontainers.image.source=https://github.com/osism/docker-manager" \
    --label "org.opencontainers.image.title=kolla-ansible" \
    --label "org.opencontainers.image.url=https://www.osism.de" \
    --label "org.opencontainers.image.vendor=Betacloud Solutions GmbH" \
    --label "org.opencontainers.image.version=$VERSION" \
    --squash \
    --no-cache \
    $BUILD_OPTS .
