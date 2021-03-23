#!/bin/bash
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