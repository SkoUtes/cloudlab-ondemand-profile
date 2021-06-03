#!/bin/bash

# Create logfile
exec > /local/logs/install.log 2>&1

# Update
sleep 10
yum update -y
yum install epel-release -y

# Install linux_host adapter components
yum install -y singularity
yum install -y tmux
singularity pull /opt/centos7.sif docker://centos:7
cat > /etc/yum.repos.d/TurboVNC.repo << EOF
[TurboVNC]
name=TurboVNC official RPMs
baseurl=https://sourceforge.net/projects/turbovnc/files
gpgcheck=1
gpgkey=https://sourceforge.net/projects/turbovnc/files/VGL-GPG-KEY
       https://sourceforge.net/projects/turbovnc/files/VGL-GPG-KEY-1024
enabled=1
EOF
yum install -y turbovnc
yum install -y python-pip
yum install -y git
yum install -y https://cbs.centos.org/kojifiles/packages/python-websockify/0.8.0/13.el7/noarch/python2-websockify-0.8.0-13.el7.noarch.rpm
yum groupinstall -y "Server with GUI"
yum groupinstall -y "MATE Desktop"

echo "
============================================================
                          Done                                      
============================================================"