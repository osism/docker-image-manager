#!/usr/bin/env bash

ANSIBLE_REMOTE_TEMP=/tmp ANSIBLE_LOCAL_TEMP=/tmp ansible-playbook -i "127.0.0.1," -c local -e ceph=$CEPH -e ansible_python_interpreter=/usr/bin/python3 /opt/ansible/awx-bootstrap.yml

awx --conf.host http://awx:8052 login -f human
awx --conf.host http://awx:8052 setting modify AWX_ANSIBLE_CALLBACK_PLUGINS '["/usr/local/lib/python3.8/site-packages/ara/plugins/callback"]'
