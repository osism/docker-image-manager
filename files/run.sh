#!/usr/bin/env bash

if [[ -e /opt/configuration/environments/custom ]]; then
    mount -t overlay overlay -o lowerdir=/opt/configuration/environments/custom:/opt/overlay/custom /opt/ansible/custom
fi

if [[ -e /opt/configuration/environments/openstack ]]; then
    mount -t overlay overlay -o lowerdir=/opt/configuration/environments/openstack:/opt/overlay/openstack /opt/ansible/openstack
fi

if [[ $(id -u) -ge 500 ]]; then

    echo "awx:x:$(id -u):$(id -g):,,,:/var/lib/awx:/bin/bash" >> /tmp/passwd
    cat /tmp/passwd > /etc/passwd
    rm /tmp/passwd

fi

source /etc/tower/conf.d/environment.sh

ANSIBLE_REMOTE_TEMP=/tmp ANSIBLE_LOCAL_TEMP=/tmp ansible -i "127.0.0.1," -c local -v -m wait_for -a "host=$DATABASE_HOST port=$DATABASE_PORT" all
ANSIBLE_REMOTE_TEMP=/tmp ANSIBLE_LOCAL_TEMP=/tmp ansible -i "127.0.0.1," -c local -v -m wait_for -a "host=$REDIS_HOST port=$REDIS_PORT" all

if [[ -z "$AWX_SKIP_MIGRATIONS" ]]; then

  awx-manage migrate --noinput

fi

if [[ ! -z "$AWX_ADMIN_USER" ]] && [[ ! -z "$AWX_ADMIN_PASSWORD" ]]; then

  result=$(echo "from django.contrib.auth import get_user_model; User = get_user_model(); print(User.objects.filter(username='$AWX_ADMIN_USER').count()>0)" | awx-manage shell | tail -n 1)

  if [ $result == "False" ]; then

    echo "from django.contrib.auth.models import User; User.objects.create_superuser('$AWX_ADMIN_USER', '$AWX_ADMIN_MAILADDRESS', '$AWX_ADMIN_PASSWORD')" | awx-manage shell

  fi

fi

awx-manage create_preload_data

echo 'from django.conf import settings; x = settings.AWX_TASK_ENV; x["HOME"] = "/var/lib/awx"; settings.AWX_TASK_ENV = x' | awx-manage shell
awx-manage provision_instance --hostname=$(hostname)
awx-manage register_queue --queuename=tower --instance_percent=100

if [[ ! -e /tmp/.supervisor_initialized ]]; then
    cat /etc/supervisor_initialize.conf | sed "s/##TOWER_OAUTH_TOKEN##/${TOWER_OAUTH_TOKEN}/g" | tee -a /etc/supervisord.conf
    touch /tmp/.supervisor_initialized
fi

awx-manage collectstatic --noinput --clear

unset $(cut -d = -f -1 /etc/tower/conf.d/environment.sh)

exec supervisord -c /etc/supervisord.conf
