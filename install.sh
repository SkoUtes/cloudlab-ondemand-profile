#!/bin/bash
touch /home/test
yum install -y epel-release
yum install -y centos-release-scl subscription manager
yum install -y https://yum.osc.edu/ondemand/1.8/ondemand-release-web-1.8-1.noarch.rpm
yum install -y ondemand
yum install -y ondemand-selinux
(cd /opt && wget https://downloads.jboss.org/keycloak/9.0.0/keycloak-9.0.0.tar.gz && tar xzf keycloak-9.0.0.tar.gz)
groupadd -r keycloak && useradd -m -d /var/lib/keycloak -s /sbin/nologin -r -g keycloak keycloak)
(cd /opt && chown keycloak: -R keycloak-9.0.0)
(cd /opt/keycloak-9.0.0 && sudo -u keycloak chmod 0700 standalone)
