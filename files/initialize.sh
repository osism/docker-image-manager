#!/usr/bin/env bash

source /etc/tower/conf.d/environment.sh

export TOWER_USERNAME
export TOWER_PASSWORD
export TOWER_HOST

ANSIBLE_REMOTE_TEMP=/tmp ANSIBLE_LOCAL_TEMP=/tmp ansible-playbook -i "127.0.0.1," -c local -e ansible_python_interpreter=/usr/bin/python3 /opt/ansible/awx-wait.yml

awx login
awx setting modify AWX_ANSIBLE_CALLBACK_PLUGINS '["/usr/local/lib/python3.8/site-packages/ara/plugins/callback"]'
