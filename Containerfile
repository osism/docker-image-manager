ARG AWX_VERSION

ARG RELEASE_CEPH
ARG RELEASE_OPENSTACK
ARG RELEASE_OSISM
ARG RELEASE_RECEPTOR=0.9.7

FROM quay.io/osism/ceph-ansible:$RELEASE_CEPH as ceph-ansible
FROM quay.io/osism/kolla-ansible:$RELEASE_OPENSTACK as kolla-ansible
FROM quay.io/osism/osism-ansible:$RELEASE_OSISM as osism-ansible
FROM quay.io/project-receptor/receptor:$RELEASE_RECEPTOR as receptor

FROM quay.io/ansible/awx:$AWX_VERSION

ARG RELEASE_CEPH
ARG RELEASE_OPENSTACK

ENV PYTHONUNBUFFERED=1
ENV CRYPTOGRAPHY_DONT_BUILD_RUST=1

USER root

RUN yum -y upgrade \
    && yum -y clean all

RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.8 100 \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.6 10 \
    && update-alternatives --auto python3

COPY files/playbooks/ceph.yml /opt/ansible/ceph/awx.yml
COPY files/playbooks/default.yml /opt/ansible/default.yml
COPY files/playbooks/kolla.yml /opt/ansible/kolla/awx.yml

ADD https://raw.githubusercontent.com/osism/osism-ansible/master/playbooks/awx-bootstrap.yml /opt/ansible/awx-bootstrap.yml
ADD https://raw.githubusercontent.com/osism/osism-ansible/master/playbooks/awx-schedules.yml /opt/ansible/awx-schedules.yml
ADD https://raw.githubusercontent.com/osism/osism-ansible/master/playbooks/awx-smart-inventories.yml /opt/ansible/awx-smart-inventories.yml
ADD https://raw.githubusercontent.com/osism/osism-ansible/master/playbooks/awx-wait.yml /opt/ansible/awx-wait.yml
ADD https://raw.githubusercontent.com/osism/osism-ansible/master/playbooks/awx-workflows.yml /opt/ansible/awx-workflows.yml

ADD https://github.com/ufoscout/docker-compose-wait/releases/download/2.7.3/wait /wait

COPY files/surveys /var/lib/awx/surveys

COPY files/initialize.sh /initialize.sh
COPY files/requirements.txt /var/lib/awx/venv/requirements.txt
COPY files/rsync.sh /rsync.sh
COPY files/run.sh /run.sh
COPY files/supervisor.conf /etc/supervisord.conf
COPY files/supervisor_crond.conf /etc/supervisor_crond.conf
COPY files/supervisor_initialize.conf /etc/supervisor_initialize.conf
COPY files/receptor.conf /etc/receptor/receptor.conf

RUN mkdir -p /opt/ansible /opt/inventory

COPY --from=ceph-ansible /ansible/ /opt/ansible/ceph/
COPY --from=ceph-ansible /requirements.txt /opt/ansible/ceph/requirements.txt

COPY --from=kolla-ansible /ansible/ /opt/ansible/kolla/
COPY --from=kolla-ansible /requirements.txt /opt/ansible/kolla/requirements.txt

COPY --from=osism-ansible /usr/share/ansible/roles /usr/share/ansible/roles
COPY --from=osism-ansible /usr/share/ansible/collections /usr/share/ansible/collections
COPY --from=osism-ansible /ansible/ /opt/ansible/osism/
COPY --from=osism-ansible /ansible/workflows /opt/ansible/workflows
COPY --from=osism-ansible /requirements.txt /opt/ansible/osism/requirements.txt

COPY --from=osism-ansible /opt/netbox-devicetype-library /opt/netbox-devicetype-library

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN mv /opt/ansible/ceph/galaxy/* /opt/ansible/ceph/roles \
    && mv /opt/ansible/kolla/galaxy/* /opt/ansible/kolla/roles

RUN for environment in osism kolla ceph; do \
      rm -f /opt/ansible/$environment/ara.env; \
      rm -f /opt/ansible/$environment/requirements*.yml; \
      rm -rf /opt/ansible/$environment/cache; \
      rm -rf /opt/ansible/$environment/collections; \
      rm -rf /opt/ansible/$environment/galaxy; \
      rm -rf /opt/ansible/$environment/logs; \
      rm -rf /opt/ansible/$environment/secrets; \
    done

RUN ln -s /opt/configuration/environments/configuration.yml /opt/ansible/kolla/group_vars/all/yyy-configuration.yml \
    && ln -s /opt/configuration/environments/images.yml /opt/ansible/kolla/group_vars/all/yyy-images.yml \
    && ln -s /opt/configuration/environments/secrets.yml /opt/ansible/kolla/group_vars/all/yyy-secrets.yml \
    && ln -s /opt/configuration/environments/kolla/configuration.yml /opt/ansible/kolla/group_vars/all/zzz-configuration.yml \
    && ln -s /opt/configuration/environments/kolla/images.yml /opt/ansible/kolla/group_vars/all/zzz-images.yml \
    && ln -s /opt/configuration/environments/kolla/secrets.yml /opt/ansible/kolla/group_vars/all/zzz-secrets.yml

RUN ln -s /opt/configuration/environments/configuration.yml /opt/ansible/ceph/group_vars/all/yyy-configuration.yml \
    && ln -s /opt/configuration/environments/images.yml /opt/ansible/ceph/group_vars/all/yyy-images.yml \
    && ln -s /opt/configuration/environments/secrets.yml /opt/ansible/ceph/group_vars/all/yyy-secrets.yml \
    && ln -s /opt/configuration/environments/ceph/configuration.yml /opt/ansible/ceph/group_vars/all/zzz-configuration.yml \
    && ln -s /opt/configuration/environments/ceph/images.yml /opt/ansible/ceph/group_vars/all/zzz-images.yml \
    && ln -s /opt/configuration/environments/ceph/secrets.yml /opt/ansible/ceph/group_vars/all/zzz-secrets.yml

RUN ln -s /opt/configuration/environments/configuration.yml /opt/ansible/osism/group_vars/all/yyy-configuration.yml \
    && ln -s /opt/configuration/environments/images.yml /opt/ansible/osism/group_vars/all/yyy-images.yml \
    && ln -s /opt/configuration/environments/secrets.yml /opt/ansible/osism/group_vars/all/yyy-secrets.yml

RUN for environment in generic infrastructure monitoring; do \
      cp -r /opt/ansible/osism /opt/ansible/$environment; \
    done

RUN rm -f /opt/ansible/generic/infrastructure-*.yml /opt/ansible/generic/manager-*.yml /opt/ansible/generic/monitoring-*.yml \
    && rm -f /opt/ansible/infrastructure/generic-*.yml /opt/ansible/infrastructure/manager-*.yml /opt/ansible/infrastructure/monitoring-*.yml \
    && rm -f /opt/ansible/monitoring/generic-*.yml /opt/ansible/monitoring/manager-*.yml /opt/ansible/monitoring/infrastructure-*.yml

RUN for environment in generic infrastructure monitoring; do \
      ln -s /opt/configuration/environments/$environment/configuration.yml /opt/ansible/$environment/group_vars/all/zzz-configuration.yml; \
      ln -s /opt/configuration/environments/$environment/images.yml /opt/ansible/$environment/group_vars/all/zzz-images.yml; \
      ln -s /opt/configuration/environments/$environment/secrets.yml /opt/ansible/$environment/group_vars/all/zzz-secrets.yml; \
    done

COPY files/playbooks/generic.yml /opt/ansible/generic/awx.yml
COPY files/playbooks/infrastructure.yml /opt/ansible/infrastructure/awx.yml
COPY files/playbooks/monitoring.yml /opt/ansible/monitoring/awx.yml

RUN for environment in custom openstack; do \
      mkdir /opt/ansible/$environment; \
      mkdir -p /opt/overlay/$environment/group_vars/all; \
      ln -s /opt/configuration/environments/$environment/configuration.yml /opt/overlay/$environment/group_vars/all/zzz-configuration.yml; \
      ln -s /opt/configuration/environments/$environment/images.yml /opt/overlay/$environment/group_vars/all/zzz-images.yml; \
      ln -s /opt/configuration/environments/$environment/secrets.yml /opt/overlay/$environment/group_vars/all/zzz-secrets.yml; \
      ln -s /opt/configuration/environments/configuration.yml /opt/overlay/$environment/group_vars/all/yyy-configuration.yml; \
      ln -s /opt/configuration/environments/images.yml /opt/overlay/$environment/group_vars/all/yyy-images.yml; \
      ln -s /opt/configuration/environments/secrets.yml /opt/overlay/$environment/group_vars/all/yyy-secrets.yml; \
    done

COPY files/playbooks/custom.yml /opt/overlay/custom/awx.yml
COPY files/playbooks/openstack.yml /opt/overlay/openstack/awx.yml

ADD https://raw.githubusercontent.com/osism/cfg-generics/master/inventory/50-ceph /opt/inventory/50-ceph
ADD https://raw.githubusercontent.com/osism/cfg-generics/master/inventory/50-infrastruture /opt/inventory/50-infrastruture
ADD https://raw.githubusercontent.com/osism/cfg-generics/master/inventory/50-kolla /opt/inventory/50-kolla
ADD https://raw.githubusercontent.com/osism/cfg-generics/master/inventory/50-monitoring /opt/inventory/50-monitoring
ADD https://raw.githubusercontent.com/osism/cfg-generics/master/inventory/50-openstack /opt/inventory/50-openstack
ADD https://raw.githubusercontent.com/osism/cfg-generics/master/inventory/51-ceph /opt/inventory/51-ceph
ADD https://raw.githubusercontent.com/osism/cfg-generics/master/inventory/51-kolla /opt/inventory/51-kolla
ADD https://raw.githubusercontent.com/osism/cfg-generics/master/inventory/60-generic /opt/inventory/60-generic

RUN chown -R 1000:1000 /opt/ansible /opt/inventory \
    && chmod +x /wait

RUN yum -y install \
      cronie \
      cyrus-sasl-devel \
      gcc \
      gcc-c++ \
      krb5-devel \
      libtool-ltdl-devel \
      libxml2-devel \
      libxslt-devel \
      openldap-devel \
      postgresql-devel \
      python38-devel \
      nodejs \
      xmlsec1-devel \
      xmlsec1-openssl-devel \
    && yum -y clean all

RUN mkdir -p /etc/ansible \
    && ln -s /opt/configuration/environments/ansible.cfg /etc/ansible/ansible.cfg

RUN pip3.8 install --no-cache-dir -U 'pip==21.0.1' \
    && pip3.8 install --no-cache-dir 'setuptools-rust==0.12.1' \
    && pip3.8 install --no-cache-dir 'ara[server]==1.5.5' 'redis==3.5.3' 'awxkit==19.0.0' 'ansible>=3.0.0,<4.0.0' 'supervisor==4.2.2' \
    && pip3.8 install --no-cache-dir -U 'python-dateutil==2.8.1' \
    && python3 -m ara.setup.env > /opt/ansible/ara.env

COPY files/crontab /etc/crontab

RUN yum -y remove \
      cyrus-sasl-devel \
      gcc \
      gcc-c++ \
      krb5-devel \
      libtool-ltdl-devel \
      libxml2-devel \
      libxslt-devel \
      openldap-devel \
      postgresql-devel \
      python38-devel \
      nodejs \
      xmlsec1-devel \
      xmlsec1-openssl-devel \
    && yum -y clean all

COPY --from=receptor /usr/bin/receptor /usr/bin/receptor
RUN mkdir -p /var/run/receptor

USER 1000

VOLUME ["/opt/configuration"]
CMD ["sh", "-c", "/wait && /run.sh"]
