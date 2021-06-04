#!/bin/bash

read -p "Node1 (Ondemand) Cloudlab DNS Record: " ood_dns

# Set up hostBasedAuthentication (dependent on temporary fix)
sed -i 's/#HostbasedAuthentication no/HostbasedAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/#IgnoreRhosts yes/IgnoreRhosts no/g' /etc/ssh/sshd_config
echo $ood_dns > /etc/ssh/shosts.equiv
ssh-keyscan $ood_dns > /etc/ssh/ssh_known_hosts
systemctl restart sshd

# Set up autofs
yum install -y autofs
systemctl enable autofs.service
sed -i '1s/^/\/home \ \ \ \/etc\/home.map /' /etc/auto.master
echo '* -fstype=rw,auto $ood_dns:/home/&' > /etc/auto.home
mount $ood_dns:/home /home

systemctl restart nfs
systemctl start autofs
systemctl start NetworkManager

echo "
============================================================
                          Done                                      
============================================================"