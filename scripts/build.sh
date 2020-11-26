#!/usr/bin/env bash
set -x

# Available environment variables
#
# BUILD_OPTS
# CEPH_VERSION
# DOCKER_REGISTRY
# OPENSTACK_VERSION
# RELEASE_OSISM
# REPOSITORY
# VERSION_AWX

# Set default values

BUILD_OPTS=${BUILD_OPTS:-}
CEPH_VERSION=${CEPH_VERSION:-nautilus}
CREATED=$(date --rfc-3339=ns)
DOCKER_REGISTRY=${DOCKER_REGISTRY:-quay.io}
OPENSTACK_VERSION=${OPENSTACK_VERSION:-ussuri}
RELEASE_OSISM=${RELEASE_OSISM:-latest}
REPOSITORY=${REPOSITORY:-osism/manager}
REVISION=$(git rev-parse --short HEAD)
VERSION_AWX=${VERSION_AWX:-latest}


if [[ -n $DOCKER_REGISTRY ]]; then
    REPOSITORY="$DOCKER_REGISTRY/$REPOSITORY"
fi


docker build \
    --build-arg "VERSION_AWX=$VERSION_AWX" \
    --build-arg "RELEASE_CEPH=$CEPH_VERSION" \
    --build-arg "RELEASE_OPENSTACK=$OPENSTACK_VERSION" \
    --build-arg "RELEASE_OSISM=$RELEASE_OSISM" \
    --tag "$REPOSITORY:$CEPH_VERSION-$OPENSTACK_VERSION" \
    --label "org.opencontainers.image.created=$CREATED" \
    --label "org.opencontainers.image.documentation=https://docs.osism.de" \
    --label "org.opencontainers.image.licenses=ASL 2.0" \
    --label "org.opencontainers.image.revision=$REVISION" \
    --label "org.opencontainers.image.source=https://github.com/osism/docker-manager" \
    --label "org.opencontainers.image.title=kolla-ansible" \
    --label "org.opencontainers.image.url=https://www.osism.de" \
    --label "org.opencontainers.image.vendor=Betacloud Solutions GmbH" \
    --label "org.opencontainers.image.version=$CEPH_VERSION-$OPENSTACK_VERSION" \
    --no-cache \
    $BUILD_OPTS .
