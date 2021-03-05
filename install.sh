#!/bin/bash

export hostname=$(hostname)
#Install Open OnDemand components
yum update -y 
sleep 10
yum install -y epel-release centos-release-scl subscription-manager
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
yum install -y java-1.8.0-openjdk-devel
#Generate admin user
export KC_PASSWORD=$(openssl rand -hex 20) && echo $KC_PASSWORD >> /root/kc-password.txt
sudo -u keycloak ./bin/add-user-keycloak.sh --user admin --password $KC_PASSWORD --realm master
#Enable proxying to keycloak
sudo -u keycloak ./bin/jboss-cli.sh 'embed-server,/subsystem=undertow/server=default-server/http-listener=default:write-attribute(name=proxy-address-forwarding,value=true)'
sudo -u keycloak ./bin/jboss-cli.sh 'embed-server,/socket-binding-group=standard-sockets/socket-binding=proxy-https:add(port=443)'
sudo -u keycloak ./bin/jboss-cli.sh 'embed-server,/subsystem=undertow/server=default-server/http-listener=default:write-attribute(name=redirect-socket,value=proxy-https)'
#Create keycloak service
sudo cat > /etc/systemd/system/keycloak.service <<EOF

[Unit]
Description=Jboss Application Server
After=network.target

[Service]
Type=idle
User=keycloak
Group=keycloak
ExecStart=/opt/keycloak-9.0.0/bin/standalone.sh -b 0.0.0.0
TimeoutStartSec=600
TimeoutStopSec=600

[Install]
WantedBy=multi-user.target
EOF
#Start up keycloak
systemctl daemon-reload
systemctl start keycloak
sleep 5
#Enable proxying to keycloak
cat > /opt/rh/httpd24/root/etc/httpd/conf.d/ood-keycloak.conf <<EOF
<VirtualHost *:443>
  ServerName $hostname

  ErrorLog  "logs/keycloak_error_ssl.log"
  CustomLog "logs/keycloak_access_ssl.log" combined

  SSLEngine On
  SSLCertificateFile "/etc/pki/tls/certs/$hostname.crt"
  SSLCertificateKeyFile "/etc/pki/tls/private/$hostname.key"
  SSLCertificateChainFile "/etc/pki/tls/certs/$hostname-interm.crt"

  # Proxy rules
  ProxyRequests Off
  ProxyPreserveHost On
  ProxyPass / http://localhost:8080/
  ProxyPassReverse / http://localhost:8080/

  ## Request header rules
  ## as per http://httpd.apache.org/docs/2.2/mod/mod_headers.html#requestheader
  RequestHeader set X-Forwarded-Proto "https"
  RequestHeader set X-Forwarded-Port "443"
</VirtualHost>
EOF