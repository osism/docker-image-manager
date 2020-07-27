#!/usr/bin/env bash

# NOTE: not required when placing venvs in /var/lib/awx/venv
#
# curl -X PATCH "http://$AWX_ADMIN_USER:$AWX_ADMIN_PASSWORD@localhost:8052/api/v2/settings/system/" \
#     -d '{"CUSTOM_VENV_PATHS": ["/opt/venvs/ceph/", "/opt/venvs/kolla/", "/opt/venvs/osism/"]}' \
#     -H 'Content-Type:application/json'

ANSIBLE_REMOTE_TEMP=/tmp ANSIBLE_LOCAL_TEMP=/tmp ansible-playbook -i "127.0.0.1," -c local /opt/ansible/awx.yml

awx --conf.host http://awx-web:8052 setting modify AWX_ANSIBLE_CALLBACK_PLUGINS '["/usr/local/lib/python3.6/site-packages/ara/plugins/callback"]'
awx --conf.host http://awx-web:8052 setting modify TOWER_URL_BASE http://$AWX_SERVER_HOST:$AWX_SERVER_PORT

python3 /home/awx/set-custom-logo.py
