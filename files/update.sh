#!/usr/bin/env bash

for environment in ceph kolla generic infrastructure monitoring custom openstack; do
    mkdir -p /configuration/$environment
    pushd /configuration/$environment > /dev/null

    rsync -aL --exclude .git /configuration.pre/$environment/ /configuration/$environment/

    case "$environment" in
        ceph)
            rsync -a /interface/ceph-ansible/ /configuration/$environment/ ;;

        kolla)
            rsync -a /interface/kolla-ansible/ /configuration/$environment/ ;;
        
        generic|infrastructure|monitoring|custom|openstack)
            rsync -a --ignore-missing-args /interface/osism-ansible/$environment-* /configuration/$environment/ ;;
    esac 

    if [[ ! -e .git ]]; then
        git init
        git config user.name "Configuration Reconciler"
        git config user.email "configuration@reconciler.local"

        git add -A
        git commit -m $(date +"%Y-%m-%d-%H-%M")
    else
        CHANGED=$(git diff --exit-code)
        if [[ $? -gt 0 ]]; then
            git add -A
            git commit -m $(date +"%Y-%m-%d-%H-%M")
        fi
    fi

    popd > /dev/null
done
