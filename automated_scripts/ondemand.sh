#!/bin/bash

# Create logfile
exec > /local/logs/install.log 2>&1

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
# Reinstall openssh
yum erase openssh -y
yum install openssh -y
yum install openssh-server -y