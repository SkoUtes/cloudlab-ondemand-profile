#!/bin/bash

#Create logfile
exec > /local/install.log 2>&1

export hostname=$(hostname)
#Install Open OnDemand components
sleep 10
yum update -y 
sleep 10
yum install -y epel-release centos-release-scl subscription-manager snapd
sleep 10
yum install -y https://yum.osc.edu/ondemand/1.8/ondemand-release-web-1.8-1.noarch.rpm
sleep 10 
yum-config-manager --enable rhel-server-rhscl-7-rpms
yum install -y ondemand ondemand-selinux rh-ruby25 rh-nodejs10 httpd24-mod_auth_openidc
sleep 5
systemctl enable --now snapd.socket && ln -s /var/lib/snapd/snap /snap && \
snap install core ; snap install core ; snap refresh core
snap install --classic certbot ; snap install --classic certbot
ln -s /snap/bin/certbot /usr/bin/certbot
# Configure shell application
mkdir -p /etc/ood/config/apps etc/ood/config/apps/shell
# Configure desktop application
mkdir -p /etc/ood/config/apps/bc_desktop/single_cluster
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
cat > /etc/systemd/system/keycloak.service <<EOF

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
##Start up keycloak
#systemctl daemon-reload
systemctl start keycloak
sleep 5
##Generate self-signed certificates
#cd /etc/pki/tls/certs
#openssl  req -x509 -newkey rsa:4096 -nodes \
#-keyout ondemand.key -out ondemand.crt \
#-subj "/C=US/ST=Utah/L='Salt Lake City'/O='University of Utah CHPC'/CN=chpc.utah.edu"
#mv ondemand.key /etc/pki/tls/private

#Enable proxying to keycloak
#cat > /opt/rh/httpd24/root/etc/httpd/conf.d/ood-keycloak.conf <<EOF
#<VirtualHost *:443>
  #ServerName $hostname
#
  #ErrorLog  "logs/keycloak_error_ssl.log"
  #CustomLog "logs/keycloak_access_ssl.log" combined
#
  #SSLEngine On
  #SSLCertificateFile "/etc/pki/tls/certs/ondemand.crt"
  #SSLCertificateKeyFile "/etc/pki/tls/private/ondemand.key"
  #Include "/root/ssl/ssl-standard.conf"
##  SSLCertificateChainFile "/etc/pki/tls/certs/ondemand-interm.crt"
#
  ## Proxy rules
  #ProxyRequests Off
  #ProxyPreserveHost On
  #ProxyPass / http://localhost:8080/
  #ProxyPassReverse / http://localhost:8080/
#
  ### Request header rules
  ### as per http://httpd.apache.org/docs/2.2/mod/mod_headers.html#requestheader
  #RequestHeader set X-Forwarded-Proto "https"
  #RequestHeader set X-Forwarded-Port "443"
#</VirtualHost>
#EOF
##Configure ood_portal.yml file
#cat > /etc/ood/config/ood_portal.yml <<EOF
## /etc/ood/config/ood_portal.yml
#---
## List of Apache authentication directives
## NB: Be sure the appropriate Apache module is installed for this
## Default: (see below, uses basic auth with an htpasswd file)
#auth:
  #- 'AuthType openid-connect'
  #- 'Require valid-user'
#
## Redirect user to the following URI when accessing logout URI
## Example:
##     logout_redirect: '/oidc?logout=https%3A%2F%2Fwww.example.com'
## Default: '/pun/sys/dashboard/logout' (the Dashboard app provides a simple
## HTML page explaining logout to the user)
#logout_redirect: '/oidc?logout=https%3A%2F%2F$hostname'
#
## Sub-uri used by mod_auth_openidc for authentication
## Example:
##     oidc_uri: '/oidc'
## Default: null (disable OpenID Connect support)
#oidc_uri: '/oidc'
#
## Certificates
#servername: $hostname
#ssl:
  #- 'SSLCertificateFile "/etc/pki/tls/certs/$hostname.crt"'
  #- 'SSLCertificateKeyFile "/etc/pki/tls/private/$hostname.key"'
  #- 'Include "/root/ssl/ssl-standard.conf"'
#EOF
##Configure apache for OnDemand
#cat > /opt/rh/httpd24/root/etc/httpd/conf.d/auth_openidc.conf <<EOF
#OIDCProviderMetadataURL https://$hostname:8443/auth/realms/ondemand/.well-known/openid-configuration
#OIDCClientID        "ondemand_client"
#OIDCClientSecret    "1111111-1111-1111-1111-111111111111"
#OIDCRedirectURI      https://$hostname/oidc
#OIDCCryptoPassphrase "4444444444444444444444444444444444444444"
#
## Keep sessions alive for 8 hours
#OIDCSessionInactivityTimeout 28800
#OIDCSessionMaxDuration 28800
#
## Set REMOTE_USER
#OIDCRemoteUserClaim preferred_username
#
## Don't pass claims to backend servers
#OIDCPassClaimsAs environment
#
## Strip out session cookies before passing to backend
#OIDCStripCookies mod_auth_openidc_session mod_auth_openidc_session_chunks mod_auth_openidc_session_0 mod_auth_openidc_session_1
#EOF
##Configure SSL for Apache
#mkdir /root/ssl
#cat > /root/ssl/ssl-standard.conf <<EOF
## ssl-standard.conf
## Basic Apache SSL options
## 2015-10-15
#SSLEngine on
##   SSL Cipher Suite:
##   List the ciphers that the client is permitted to negotiate.
##   See the mod_ssl documentation for a complete list.
#SSLProtocol All -SSLv2 -SSLv3 -TLSv1 -TLSv1.1
#SSLHonorCipherOrder on
#SSLCipherSuite EECDH:ECDH:-RC4:-3DES
##   Export the SSL environment variables to scripts
#<Files ~ "\.(cgi|pl|shtml|phtml|php3?)$">
   #SSLOptions +StdEnvVars
#</Files>
#EOF
##Startup Apache
#/opt/rh/httpd24/root/usr/sbin/httpd-scl-wrapper
##Change permissions and rebuild the portal
#chgrp apache /opt/rh/httpd24/root/etc/httpd/conf.d/auth_openidc.conf
#chmod 640 /opt/rh/httpd24/root/etc/httpd/conf.d/auth_openidc.conf
#/opt/ood/ood-portal-generator/sbin/update_ood_portal