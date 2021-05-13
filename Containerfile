ARG AWX_VERSION

ARG RELEASE_RECEPTOR=0.9.7
FROM quay.io/project-receptor/receptor:$RELEASE_RECEPTOR as receptor

FROM quay.io/ansible/awx:$AWX_VERSION

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV PYTHONUNBUFFERED=1
ENV CRYPTOGRAPHY_DONT_BUILD_RUST=1

COPY --from=receptor /usr/bin/receptor /usr/bin/receptor
RUN mkdir -p /var/run/receptor

USER root

RUN yum -y upgrade \
    && yum -y clean all

RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.8 100 \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.6 10 \
    && update-alternatives --auto python3

ADD https://github.com/ufoscout/docker-compose-wait/releases/download/2.7.3/wait /wait
ADD https://raw.githubusercontent.com/osism/osism-ansible/master/playbooks/awx-wait.yml /opt/ansible/awx-wait.yml

COPY files/crontab /etc/crontabs/root
COPY files/initialize.sh /initialize.sh
COPY files/receptor.conf /etc/receptor/receptor.conf
COPY files/requirements.txt /requirements.txt
COPY files/run.sh /run.sh
COPY files/supervisor.conf /etc/supervisord.conf
COPY files/supervisor_initialize.conf /etc/supervisor_initialize.conf
COPY files/update.sh /update.sh


RUN mkdir -p /opt/ansible /configuration /configuration.pre

RUN for environment in ceph kolla generic infrastructure monitoring custom openstack; do \
      mkdir -p /configuration.pre/$environment/group_vars/all; \
      ln -s /opt/configuration/environments/$environment/configuration.yml /configuration.pre/$environment/group_vars/all/zzz-configuration.yml; \
      ln -s /opt/configuration/environments/$environment/images.yml /configuration.pre/$environment/group_vars/all/zzz-images.yml; \
      ln -s /opt/configuration/environments/$environment/secrets.yml /configuration.pre/$environment/group_vars/all/zzz-secrets.yml; \
      ln -s /opt/configuration/environments/configuration.yml /configuration.pre/$environment/group_vars/all/yyy-configuration.yml; \
      ln -s /opt/configuration/environments/images.yml /configuration.pre/$environment/group_vars/all/yyy-images.yml; \
      ln -s /opt/configuration/environments/secrets.yml /configuration.pre/$environment/group_vars/all/yyy-secrets.yml; \
      ln -s /inventory /configuration.pre/$environment/inventory; \
    done

RUN chown -R 1000:1000 /opt/ansible /configuration /configuration.pre \
    && chmod +x /wait \
    && mkdir -p /etc/ansible \
    && ln -s /opt/configuration/environments/ansible.cfg /etc/ansible/ansible.cfg

RUN yum -y install \
      cronie \
      cyrus-sasl-devel \
      gcc \
      gcc-c++ \
      krb5-devel \
      libtool-ltdl-devel \
      libxml2-devel \
      libxslt-devel \
      nodejs \
      openldap-devel \
      postgresql-devel \
      python38-devel \
      xmlsec1-devel \
      xmlsec1-openssl-devel \
    && yum -y clean all \
    && pip3.8 install --no-cache-dir -r /requirements.txt \
    && python3 -m ara.setup.env > /opt/ansible/ara.env \
    && yum -y remove \
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

USER 1000

VOLUME ["/opt/configuration", "/configuration"]
CMD ["sh", "-c", "/wait && /run.sh"]
