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
yum install -y python3
pip install websockify
cd /opt && git clone https://github.com/novnc/websockify.git
cd /opt/websockify && sed "/install_requires=['numpy']/d" ./setup.py && python3 setup.py install
yum groupinstall "Server with GUI" -y
yum groupinstall "MATE Desktop"
yum install -y autofs
systemctl enable autofs.service

echo "
================================================================================================

                                     End of Install                                             

================================================================================================"