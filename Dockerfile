ARG VERSION_AWX
ARG RELEASE_CEPH
ARG RELEASE_OPENSTACK
ARG RELEASE_OSISM

FROM quay.io/osism/ceph-ansible:$RELEASE_CEPH as ceph-ansible
FROM quay.io/osism/kolla-ansible:$RELEASE_OPENSTACK as kolla-ansible
FROM quay.io/osism/osism-ansible:$RELEASE_OSISM as osism-ansible

FROM ansible/awx:$VERSION_AWX

ARG RELEASE_CEPH
ARG RELEASE_OPENSTACK

USER root

RUN yum -y upgrade \
    && yum clean all

ADD files/logo-osism.png /home/awx/logo-osism.png
ADD files/set-custom-logo.py /home/awx/set-custom-logo.py

ADD files/playbooks/ceph.yml /opt/ansible/ceph/awx.yml
ADD files/playbooks/default.yml /opt/ansible/default.yml
ADD files/playbooks/kolla.yml /opt/ansible/kolla/awx.yml

ADD files/playbooks/awx.yml /opt/ansible/awx.yml

ADD files/surveys /var/lib/awx/surveys

ADD files/requirements.txt /var/lib/awx/venv/requirements.txt
ADD files/run.sh /run.sh
ADD files/initialize.sh /initialize.sh
ADD files/supervisor_initialize.conf /etc/supervisor_initialize.conf

ADD https://github.com/ufoscout/docker-compose-wait/releases/download/2.7.3/wait /wait

RUN mkdir -p /opt/ansible

COPY --from=ceph-ansible /ansible/ /opt/ansible/ceph/
COPY --from=ceph-ansible /requirements.txt /opt/ansible/ceph/requirements.txt

COPY --from=kolla-ansible /ansible/ /opt/ansible/kolla/
COPY --from=kolla-ansible /requirements.txt /opt/ansible/kolla/requirements.txt

COPY --from=osism-ansible /usr/share/ansible/roles /usr/share/ansible/roles
COPY --from=osism-ansible /usr/share/ansible/collections /usr/share/ansible/collections
COPY --from=osism-ansible /ansible/ /opt/ansible/osism/
COPY --from=osism-ansible /requirements.txt /opt/ansible/osism/requirements.txt

COPY --from=osism-ansible /opt/tests /opt/tests
COPY --from=osism-ansible /opt/validations /opt/validations
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

ADD files/playbooks/generic.yml /opt/ansible/generic/awx.yml
ADD files/playbooks/infrastructure.yml /opt/ansible/infrastructure/awx.yml
ADD files/playbooks/monitoring.yml /opt/ansible/monitoring/awx.yml

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

ADD files/playbooks/custom.yml /opt/overlay/custom/awx.yml
ADD files/playbooks/openstack.yml /opt/overlay/openstack/awx.yml

RUN chown -R 1000:1000 /opt/ansible

RUN chmod +x /wait

RUN yum -y install cyrus-sasl-devel \
  gcc \
  gcc-c++ \
  krb5-devel \
  libtool-ltdl-devel \
  libxml2-devel \
  libxslt-devel \
  openldap-devel \
  postgresql-devel \
  python36-devel \
  nodejs \
  xmlsec1-devel \
  xmlsec1-openssl-devel

RUN virtualenv -p python3 /var/lib/awx/venv/ceph \
    && /var/lib/awx/venv/ceph/bin/pip install --no-cache-dir -r /var/lib/awx/venv/requirements.txt \
    && /var/lib/awx/venv/ceph/bin/pip install --no-cache-dir -r /opt/ansible/ceph/requirements.txt

RUN virtualenv -p python3 /var/lib/awx/venv/kolla \
    && /var/lib/awx/venv/kolla/bin/pip install --no-cache-dir -r /var/lib/awx/venv/requirements.txt \
    && /var/lib/awx/venv/kolla/bin/pip install --no-cache-dir -r /opt/ansible/kolla/requirements.txt

RUN if [[ "$RELEASE_OPENSTACK" == "latest" ]]; then git clone https://github.com/openstack/kolla-ansible /repository-kolla-ansible; fi \
    && if [[ "$RELEASE_OPENSTACK" != "latest" ]]; then git clone -b stable/$RELEASE_OPENSTACK https://github.com/openstack/kolla-ansible /repository-kolla-ansible; fi \
    && /var/lib/awx/venv/kolla/bin/pip install --no-cache-dir -r /repository-kolla-ansible/requirements.txt \
    && /var/lib/awx/venv/kolla/bin/pip install --no-cache-dir /repository-kolla-ansible \
    && rm -rf /repository/kolla-ansible

RUN virtualenv -p python3 /var/lib/awx/venv/osism \
    && /var/lib/awx/venv/osism/bin/pip install --no-cache-dir -r /var/lib/awx/venv/requirements.txt \
    && /var/lib/awx/venv/osism/bin/pip install --no-cache-dir -r /opt/ansible/osism/requirements.txt

RUN mv /etc/ansible/ansible.cfg /etc/ansible/ansible.cfg.orig \
    && ln -s /opt/configuration/environments/ansible.cfg /etc/ansible/ansible.cfg

RUN pip3 install --no-cache-dir 'ara[server]' redis \
    && pip3 install --no-cache-dir -U python-dateutil \
    && python3 -m ara.setup.env > /opt/ansible/ara.env

RUN git clone https://github.com/ansible/awx \
    && pip3 install awx/awxkit \
    && rm -rf awx

RUN yum -y remove cyrus-sasl-devel \
      gcc \
      gcc-c++ \
      krb5-devel \
      libtool-ltdl-devel \
      libxml2-devel \
      libxslt-devel \
      openldap-devel \
      postgresql-devel \
      python36-devel \
      nodejs \
      xmlsec1-devel \
      xmlsec1-openssl-devel \
    && yum -y clean all

USER 1000

VOLUME ["/opt/configuration"]
CMD ["sh", "-c", "/wait && /run.sh"]
