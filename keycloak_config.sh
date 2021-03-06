#!/bin/bash

read -p "Email: " email
read -p "Node1 (Ondemand) Cloudlab DNS Record: " ood_dns
export server_ip=$(ip addr | grep -E -o '[0-9]{3}\.[0-9]{3}\.[0-9]{1,3}\.[0-9]{1,3}/22' | sed 's/\/22//g')
export hostname=$(hostname)
export ood_host=$(hostname | sed 's/2/1/')

# Run certbot
certbot --apache -m $email -d $hostname --agree-tos

# Place apache in front of keycloak
cat > /etc/httpd/conf.d/ood-keycloak.conf <<EOF
<VirtualHost $server_ip:443>
  ServerName $hostname

  ErrorLog  "/var/log/httpd/error_log"
  CustomLog "/var/log/httpd/access_log" combined

  SSLEngine on
  SSLCertificateFile "/etc/letsencrypt/live/$hostname/cert.pem"
  SSLCertificateKeyFile "/etc/letsencrypt/live/$hostname/privkey.pem"
  SSLCertificateChainFile "/etc/letsencrypt/live/$hostname/chain.pem"
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

cat > /etc/httpd/conf.d/keycloak.conf <<EOF
<VirtualHost *:80>
  ServerName $hostname

  ErrorLog  "/var/log/httpd/error_log"
  CustomLog "/var/log/httpd/access_log" combined
</VirtualHost>
EOF

systemctl restart httpd 
systemctl restart keycloak

####################### Keycloak Parameters #####################

export keycloak="/opt/keycloak-9.0.0/bin/kcadm.sh"
export redirect_uris="[\"https://$ood_host\",\"https://$ood_host/oidc\"]"
export server="http://localhost:8080/auth"
export realm="master"
export user="admin"
export password=$(cat /root/kc-password.txt)

# Try to log into keycloak as admin user and retry up to 5 times
n=0
until [ "$n" -ge 5 ]
do
        $keycloak config credentials --server $server --realm $realm --user $user --password $password && break
        n=$((n+1))
        sleep 5
done

# Create keycloak realm and client
$keycloak create realms -s realm=ondemand -s enabled=true
$keycloak create clients --server $server -r ondemand -s clientId=ondemand_client -s enabled=true -s publicClient=false -s protocol=openid-connect -s directAccessGrantsEnabled=false -s serviceAccountsEnabled=true -s redirectUris=$redirect_uris -s authorizationServicesEnabled=true

echo "
============================================================
                          Done                                      
============================================================"