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
## Old VNC installation
# cat > /etc/yum.repos.d/TurboVNC.repo << EOF
# [TurboVNC]
# name=TurboVNC official RPMs
# baseurl=https://sourceforge.net/projects/turbovnc/files
# gpgcheck=1
# gpgkey=https://sourceforge.net/projects/turbovnc/files/VGL-GPG-KEY
       # https://sourceforge.net/projects/turbovnc/files/VGL-GPG-KEY-1024
# enabled=1
# EOF
# yum install -y turbovnc
hostnamectl set-hostname $(hostname -A)
yum install -y python-pip
yum install -y git
yum install -y https://yum.osc.edu/ondemand/1.8/compute/el7Server/x86_64/turbovnc-2.2.3-1.el7.x86_64.rpm
yum install -y https://yum.osc.edu/ondemand/1.8/compute/el7Server/x86_64/ondemand-compute-1.8-1.el7.noarch.rpm
yum install -y https://yum.osc.edu/ondemand/1.8/compute/el7Server/x86_64/python-websockify-0.8.0-1.el7.noarch.rpm
yum groupinstall -y "Server with GUI"
yum groupinstall -y "MATE Desktop"

echo "
============================================================
                          Done                                      
============================================================"