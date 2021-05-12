#!/bin/bash

read -p "Node3 (Worker) Cloudlab DNS record: " remoteDNS
read -p "Node3 (Worker) IP address: " worker_ip

mkdir /etc/ood/config/clusters.d
mkdir /etc/ood/config/apps/bc_desktop/submit
mkdir /etc/ood/config/apps/dashboard
mkdir /etc/ood/config/apps/myjobs

# Configure LinuxHost Adapter submit.yml.erb
cat > /etc/ood/config/apps/bc_desktop/submit/linuxhost_submit.yml.erb << EOF
---
batch_connect:
  native:
    singularity_bindpath: /etc,/media,/mnt,/opt,/run,/srv,/usr,/var,/fs,/home
    singularity_container: /opt/centos7.sif
EOF
# Set up keycloak host.yml
cat > /etc/ood/config/clusters.d/remoteHost.yml << EOF
---
v2:
  metadata:
    title: "remoteHost"
    hidden: false
  login:
    host: "$remoteDNS"
  job:
    adapter: "linux_host"
    submit_host: "$remoteDNS"  # This is the head for a login round robin
    ssh_hosts: # These are the actual login nodes, need to have full host name for the regex to work
      - $remoteDNS
    site_timeout: 7200
    debug: true
    singularity_bin: /bin/singularity
    singularity_bindpath: /etc,/media,/mnt,/opt,/run,/srv,/usr,/var,/fs,/home
    singularity_image: /opt/centos7.sif
    # Enabling strict host checking may cause the adapter to fail if the user's known_hosts does not have all the roundrobin hosts
    strict_host_checking: false
    tmux_bin: /bin/tmux
  batch_connect:
    basic:
      script_wrapper: |
        module purge
        %s
    vnc:
      script_wrapper: |
        module purge
        #!/bin/bash
        export PATH="/opt/TurboVNC/bin:\$PATH"
        export WEBSOCKIFY_CMD="/opt/websockify/run"
        %s
EOF
# Set up keycloak desktop option
cat > /etc/ood/config/apps/bc_desktop/remoteHost.yml << EOF
---
title: "Remote Desktop"
cluster: "remoteHost"
submit: "linux_host"
form:
  - desktop
  - bc_num_hours
attributes:
  bc_qeue: null
  bc_account: null
  bc_num_hours:
    value: 1
  desktop: "mate"
EOF
# Configure ondemand portal desktop application
mv /var/www/ood/apps/sys/bc_desktop/form.yml /var/www/ood/apps/sys/bc_desktop/form.yml.org
cat > /var/www/ood/apps/sys/bc_desktop/form.yml <<EOF
---
attributes:
  desktop: "mate"
  bc_vnc_idle: 0
  bc_vnc_resolution:
    required: true
  node_type: null
  cluster:
    widget: "select"
    options:
      - "remoteHost"
    help: |
      Select the cluster or Frisco node to create this desktop session on.
  num_cores:
    widget: "number_field"
    label: "Number of tasks (CPU cores)"
    value: 1
    help: "Maximum number of CPU cores on notchpeak-shared-short is 32, see [cluster help pages](https://www.chpc.utah.edu/resources/HPC_Clusters.php) for other cluster's node counts."
    min: 1
    max: 64
    step: 1


form:
  - cluster
  - bc_vnc_idle
  - desktop
  - bc_num_hours
  - num_cores
  - node_type
  - bc_account
  - bc_queue
  - bc_vnc_resolution
  - bc_email_on_started
EOF
# Edit submit.yml.erb file
mv /var/www/ood/apps/sys/bc_desktop/submit.yml.erb /var/www/ood/apps/sys/bc_desktop/submit.yml.erb.org
cat > /var/www/ood/apps/sys/bc_desktop/submit.yml.erb <<EOF
---
attributes:
  desktop: "mate"
  bc_vnc_idle: 0
  bc_vnc_resolution:
    required: true
  node_type: null

form:
  - bc_vnc_idle
  - desktop
  - bc_account
  - bc_num_hours
  - bc_num_slots
  - node_type
  - bc_queue
  - bc_vnc_resolution
  - bc_email_on_started
EOF
# Set up nfs file-sharing
systemctl start nfs
cat > /etc/exports <<EOF
/home $worker_ip(rwx,sync,no_subtree_check,root_squash)
EOF
# Relocate ood_session_data output
#cat > /etc/ood/config/apps/dashboard/env <<EOF
#OOD_DATAROOT="/nfs/ood_data/\$USER"
#EOF
#cat > /etc/ood/config/apps/myjobs/env <<EOF
#OOD_DATAROOT="/nfs/ood_data/\$USER"
#EOF
#sed -i 's/# pun custom_env:/pun custom_env:/g' /etc/ood/config/nginx_stage.yml
#sed '/^pun custom_env:/a \ \ OOD_DATAROOT: "/nfs/ood_data/$USER"'
systemctl restart httpd24-httpd
systemctl restart nfs

echo "
==========================================================================
                                Done                                            
=========================================================================="