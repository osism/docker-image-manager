#!/usr/bin/env bash

awx --conf.host http://awx:8052 login -f human
awx --conf.host http://awx:8052 setting modify AWX_ANSIBLE_CALLBACK_PLUGINS '["/usr/local/lib/python3.8/site-packages/ara/plugins/callback"]'
