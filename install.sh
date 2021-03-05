#!/bin/bash
yum update -y 
sleep 10
yum install -y epel-release centos-release-scl subscription manager
sleep 10
yum install -y https://yum.osc.edu/ondemand/1.8/ondemand-release-web-1.8-1.noarch.rpm
sleep 10 
yum-config-manager --enable rhel-server-rhscl-7-rpms
yum install -y ondemand ondemand-selinux rh-ruby25 rh-nodejs10 \
ondemand-senlinux httpd-mod_auth_openidc
sleep 5
# Configure shell application
mkdir /etc/ood/config/clusters.d /opt/ood/linuxhost_adapter \
/etc/ood/config/apps etc/ood/config/apps/shell
# Configure desktop application
mkdir /etc/ood/config/apps/bc_desktop /etc/ood/config/apps/bc_desktop/single_cluster
# Install Keycloak components
cd /opt
wget https://downloads.jboss.org/keycloak/9.0.0/keycloak-9.0.0.tar.gz && tar xzf keycloak-9.0.0.tar.gz && \
groupadd -r keycloak && useradd -m -d /var/lib/keycloak -s /sbin/nologin -r -g keycloak keycloak && \
chown keycloak: -R keycloak-9.0.0
cd /opt/keycloak-9.0.0 
sudo -u keycloak chmod 0700 standalone
