#!/bin/bash

# Place apache in front of keycloak
cat > /etc/httpd/conf.d/ood-keycloak.conf <<EOF
<VirtualHost *:443>
  ServerName $hostname

  ErrorLog  "/var/log/httpd/error_log"
  CustomLog "/var/log/httpd/access_log" combined

  SSLEngine on
  SSLCertificateFile "/etc/letsencrypt/live/$hostname/cert.pem"
  SSLCertificateKeyFile "/etc/letsencrypt/live/$hostname/privkey.pem"
  SSLCACertificatePath    "/etc/letsencrypt/live/$hostname"
  Include "/etc/letsencrypt/options-ssl-apache.conf"

  ProxyRequests Off
  ProxyPreserveHost On
  ProxyPass / http://localhost:8080/
  ProxyPassReverse / http://localhost:8080/

  RequestHeader set X-Forwarded-Proto "https"
  RequestHeader set X-Forwarded-Port "443"
</VirtualHost>
EOF

# Restart keycloak and apache
systemctl restart httpd keycloak

# Place apache in front of keycloak
cat > /etc/httpd/conf.d/ood-keycloak.conf <<EOF
<VirtualHost *:443>
  ServerName $hostname

  ErrorLog  "/var/log/httpd/error_log"
  CustomLog "/var/log/httpd/access_log" combined

  SSLEngine on
  SSLCertificateFile "/etc/letsencrypt/live/$hostname/cert.pem"
  SSLCertificateKeyFile "/etc/letsencrypt/live/$hostname/privkey.pem"
  SSLCACertificatePath    "/etc/letsencrypt/live/$hostname"
  Include "/etc/letsencrypt/options-ssl-apache.conf"

  ProxyRequests Off
  ProxyPreserveHost On
  ProxyPass / http://localhost:8080/
  ProxyPassReverse / http://localhost:8080/

  RequestHeader set X-Forwarded-Proto "https"
  RequestHeader set X-Forwarded-Port "443"
</VirtualHost>
EOF

# Restart keycloak and apache
systemctl restart httpd keycloak