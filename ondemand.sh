#!/bin/bash

# Create logfile
exec > /local/logs/install.log 2>&1

export hostname=$(hostname)
# Install Open OnDemand components
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
# Create apachectl script wrapper
echo -e '#!/bin/bash\nscl enable httpd24 -- /opt/rh/httpd24/root/usr/sbin/apachectl $@' > /opt/apachectl-wrapper.sh
chmod 0750 /opt/apachectl-wrapper.sh
############################################### Certs ##########################################################

# Get letsencrypt certs using certbot
certbot -m u1064657@umail.utah.edu -d $hostname --agree-tos --apache \
--apache-server-root /opt/rh/httpd24/root/etc/httpd --apache-vhost-root /opt/rh/httpd24/root/etc/httpd/conf.d \
--apache-logs-root /opt/rh/httpd24/root/etc/httpd/logs --apache-challenge-location /opt/rh/httpd24/root/etc/httpd/ \
--apache-ctl /opt/apachectl-wrapper.sh

# Get self-signed certs using openssl
#mkdir -p /etc/letsencrypt/live/$hostname
#cd /etc/letsencrypt/live/$hostname
#openssl req -x509 -newkey rsa:4096 -nodes -keyout privkey.pem -out cert.pem \
#-subj "/C=US/ST=Utah/L='Salt Lake City'/O='University of Utah CHPC'/CN=www.chpc.utah.edu"
sleep 10

############################################## Config ##########################################################
# Configure ood_portal.yml file
cat > /etc/ood/config/ood_portal.yml <<EOF
# /etc/ood/config/ood_portal.yml
---
# List of Apache authentication directives
# NB: Be sure the appropriate Apache module is installed for this
# Default: (see below, uses basic auth with an htpasswd file)
auth:
  - 'AuthType openid-connect'
  - 'Require valid-user'

# The server name used for name-based Virtual Host
# Example:
#     servername: 'www.example.com'
# Default: null (don't use name-based Virtual Host)
servername: $hostname

# Redirect user to the following URI when accessing logout URI
# Example:
#     logout_redirect: '/oidc?logout=https%3A%2F%2Fwww.example.com'
# Default: '/pun/sys/dashboard/logout' (the Dashboard app provides a simple
# HTML page explaining logout to the user)
logout_redirect: '/oidc?logout=https%3A%2F%2F$hostname'

# Sub-uri used by mod_auth_openidc for authentication
# Example:
#     oidc_uri: '/oidc'
# Default: null (disable OpenID Connect support)
oidc_uri: '/oidc'

# Certificates
servername: $hostname
ssl:
  - 'SSLCertificateFile "/etc/letsencrypt/live/$hostname/cert.pem"'
  - 'SSLCertificateKeyFile "/etc/letsencrypt/live/$hostname/privkey.pem"'
EOF
# Start up Apache
/opt/ood/ood-portal-generator/sbin/update_ood_portal
/opt/rh/httpd24/root/usr/sbin/httpd-scl-wrapper
# Configure apache for OnDemand
cat > /opt/rh/httpd24/root/etc/httpd/conf.d/auth_openidc.conf <<EOF
OIDCProviderMetadataURL https://$hostname:443/auth/realms/ondemand/.well-known/openid-configuration
OIDCClientID        "ondemand_client"
OIDCClientSecret    "1111111-1111-1111-1111-111111111111"
OIDCRedirectURI      https://$hostname/oidc
OIDCCryptoPassphrase "4444444444444444444444444444444444444444"

# Keep sessions alive for 8 hours
OIDCSessionInactivityTimeout 28800
OIDCSessionMaxDuration 28800

# Set REMOTE_USER
OIDCRemoteUserClaim preferred_username

# Don't pass claims to backend servers
OIDCPassClaimsAs environment

# Strip out session cookies before passing to backend
OIDCStripCookies mod_auth_openidc_session mod_auth_openidc_session_chunks mod_auth_openidc_session_0 mod_auth_openidc_session_1
EOF
#Change permissions
chgrp apache /opt/rh/httpd24/root/etc/httpd/conf.d/auth_openidc.conf
chmod 640 /opt/rh/httpd24/root/etc/httpd/conf.d/auth_openidc.conf