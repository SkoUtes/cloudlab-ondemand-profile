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