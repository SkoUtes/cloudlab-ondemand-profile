#!/bin/bash
sudo yum update -y 
sleep 10
sudo yum install -y epel-release centos-release-scl subscription manager
sleep 10
sudo yum install -y https://yum.osc.edu/ondemand/1.8/ondemand-release-web-1.8-1.noarch.rpm
sleep 10 
sudo yum install -y ondemand ondemand-selinux
(cd /opt && wget https://downloads.jboss.org/keycloak/9.0.0/keycloak-9.0.0.tar.gz && tar xzf keycloak-9.0.0.tar.gz)
sudo groupadd -r keycloak && useradd -m -d /var/lib/keycloak -s /sbin/nologin -r -g keycloak keycloak)
(cd /opt && sudo chown keycloak: -R keycloak-9.0.0)
(cd sudo /opt/keycloak-9.0.0 && sudo -u keycloak chmod 0700 standalone)
