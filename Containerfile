ARG AWX_VERSION

ARG RELEASE_RECEPTOR=0.9.7
FROM quay.io/project-receptor/receptor:$RELEASE_RECEPTOR as receptor

FROM quay.io/ansible/awx:$AWX_VERSION

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

COPY files/initialize.sh /initialize.sh
COPY files/receptor.conf /etc/receptor/receptor.conf
COPY files/requirements.txt /requirements.txt
COPY files/run.sh /run.sh
COPY files/supervisor.conf /etc/supervisord.conf
COPY files/supervisor_initialize.conf /etc/supervisor_initialize.conf

RUN mkdir -p /opt/ansible

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN mkdir -p \
      /opt/ansible/ceph/group_vars/all \
      /opt/ansible/kolla/group_vars/all \
      /opt/ansible/osism/group_vars/all

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
      mkdir -p /opt/ansible/$environment/group_vars/all; \
      ln -s /opt/configuration/environments/$environment/configuration.yml /opt/ansible/$environment/group_vars/all/zzz-configuration.yml; \
      ln -s /opt/configuration/environments/$environment/images.yml /opt/ansible/$environment/group_vars/all/zzz-images.yml; \
      ln -s /opt/configuration/environments/$environment/secrets.yml /opt/ansible/$environment/group_vars/all/zzz-secrets.yml; \
    done

RUN for environment in custom openstack; do \
      mkdir -p /opt/ansible/$environment/group_vars/all; \
      mkdir -p /opt/overlay/$environment/group_vars/all; \
      ln -s /opt/configuration/environments/$environment/configuration.yml /opt/overlay/$environment/group_vars/all/zzz-configuration.yml; \
      ln -s /opt/configuration/environments/$environment/images.yml /opt/overlay/$environment/group_vars/all/zzz-images.yml; \
      ln -s /opt/configuration/environments/$environment/secrets.yml /opt/overlay/$environment/group_vars/all/zzz-secrets.yml; \
      ln -s /opt/configuration/environments/configuration.yml /opt/overlay/$environment/group_vars/all/yyy-configuration.yml; \
      ln -s /opt/configuration/environments/images.yml /opt/overlay/$environment/group_vars/all/yyy-images.yml; \
      ln -s /opt/configuration/environments/secrets.yml /opt/overlay/$environment/group_vars/all/yyy-secrets.yml; \
    done

RUN chown -R 1000:1000 /opt/ansible \
    && chmod +x /wait

RUN yum -y install \
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
    && yum -y clean all

RUN mkdir -p /etc/ansible \
    && ln -s /opt/configuration/environments/ansible.cfg /etc/ansible/ansible.cfg

RUN pip3.8 install --no-cache-dir -r /requirements.txt \
    && python3 -m ara.setup.env > /opt/ansible/ara.env

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

USER 1000

VOLUME ["/opt/configuration"]
CMD ["sh", "-c", "/wait && /run.sh"]
