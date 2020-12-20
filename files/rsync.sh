#!/usr/bin/env bash

if [[ ! -e /inventory/inventory ]]; then
    mkdir /inventory/inventory
fi

rsync -a --delete --exclude .git /opt/inventory/ /inventory/inventory/
rsync -a /opt/configuration/inventory/ /inventory/inventory/

pushd /inventory

if [[ ! -e .git ]]; then
    git init
    git config user.name "AWX"
    git config user.email "awx@osism"
fi

git add -A
git commit -m $(date +"%Y-%m-%d-%H-%M")

popd
