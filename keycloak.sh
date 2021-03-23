#!/bin/bash

# Create logfile
exec > /local/logs/install.log 2>&1

export hostname=$(hostname)
# Install Open OnDemand components
sleep 10
yum update -y

# Install Keycloak components
cd /opt
wget https://downloads.jboss.org/keycloak/9.0.0/keycloak-9.0.0.tar.gz && tar xzf keycloak-9.0.0.tar.gz && \
groupadd -r keycloak && useradd -m -d /var/lib/keycloak -s /sbin/nologin -r -g keycloak keycloak && \
chown keycloak: -R keycloak-9.0.0
cd /opt/keycloak-9.0.0 
sudo -u keycloak chmod 0700 standalone
yum install -y java-1.8.0-openjdk-devel
# Generate admin user
export KC_PASSWORD=$(openssl rand -hex 20) && echo $KC_PASSWORD >> /root/kc-password.txt
sudo -u keycloak ./bin/add-user-keycloak.sh --user admin --password $KC_PASSWORD --realm master
# Enable proxying to keycloak
sudo -u keycloak ./bin/jboss-cli.sh 'embed-server,/subsystem=undertow/server=default-server/http-listener=default:write-attribute(name=proxy-address-forwarding,value=true)'
sudo -u keycloak ./bin/jboss-cli.sh 'embed-server,/socket-binding-group=standard-sockets/socket-binding=proxy-https:add(port=443)'
sudo -u keycloak ./bin/jboss-cli.sh 'embed-server,/subsystem=undertow/server=default-server/http-listener=default:write-attribute(name=redirect-socket,value=proxy-https)'
# Create keycloak service
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

# Start up keycloak
systemctl daemon-reload
systemctl start keycloak

# Install and configure default apache
yum install -y httpd
yum install -y mod_ssl
awk '/## SSL Virtual Host Context/ { print; print "NameVirtualHost *:443"; next }1' /etc/httpd/conf.d/ssl.conf
cat > /etc/httpd/conf.d/keycloak.conf <<EOF
<VirtualHost *:80>
  ServerName node2.ondemand.slate-pg0.wisc.cloudlab.us

  ErrorLog  "/var/log/httpd/error_log"
  CustomLog "/var/log/httpd/access_log" combined
</VirtualHost>
EOF
systemctl start httpd

# Install certbot
yum install -y snapd
systemctl enable --now snapd.socket && ln -s /var/lib/snapd/snap /snap && \
snap install core ; snap install core ; snap refresh core
snap install --classic certbot ; snap install --classic certbot
ln -s /snap/bin/certbot /usr/bin/certbot

# Run certbot
certbot --apache -d $hostname --agree-tos -m u1064657@umail.utah.edu

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