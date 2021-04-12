#!/usr/bin/env bash

ANSIBLE_REMOTE_TEMP=/tmp ANSIBLE_LOCAL_TEMP=/tmp ansible-playbook -i "127.0.0.1," -c local -e ceph=$CEPH /opt/ansible/awx-bootstrap.yml

awx --conf.host http://awx-web:8052 setting modify AWX_ANSIBLE_CALLBACK_PLUGINS '["/usr/local/lib/python3.8/site-packages/ara/plugins/callback"]'
awx --conf.host http://awx-web:8052 setting modify TOWER_URL_BASE http://$AWX_SERVER_HOST:$AWX_SERVER_PORT
