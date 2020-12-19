#!/usr/bin/env bash
set -x

# Available environment variables
#
# BUILD_TYPE
# CEPH_VERSION
# DOCKER_REGISTRY
# OPENSTACK_VERSION
# REPOSITORY

# Set default values

BUILD_TYPE=${BUILD_TYPE:-all-in-one}
CEPH_VERSION=${CEPH_VERSION:-nautilus}
DOCKER_REGISTRY=${DOCKER_REGISTRY:-quay.io}
OPENSTACK_VERSION=${OPENSTACK_VERSION:-victoria}

if [[ -n $DOCKER_REGISTRY ]]; then
    REPOSITORY="$DOCKER_REGISTRY/$REPOSITORY"
fi

if [[ $BUILD_TYPE == "all-in-one" ]]; then
    VERSION=$CEPH_VERSION-$OPENSTACK_VERSION
fi

if [[ $BUILD_TYPE == "openstack" ]]; then
    VERSION=$OPENSTACK_VERSION
fi

docker push "$REPOSITORY:$VERSION"
