#!/bin/bash

read -p "Node2 (Keycloak) Cloudlab DNS record: " kc_dns

# Set up keycloak host.yml
cat > /etc/ood/config/clusters.d/kc_host.yml << EOF
---
v2:
  metadata:
    title: "kc_host"
    hidden: false
  login:
    host: "$kc_dns"
  job:
    adapter: "linux_host"
    submit_host: "$kc_dns"  # This is the head for a login round robin
    ssh_hosts: # These are the actual login nodes, need to have full host name for the regex to work
      - $kc_dns
    site_timeout: 7200
    debug: true
    singularity_bin: /bin/singularity
    singularity_bindpath: /etc,/mnt,/media,/opt,/run,/srv,/usr,/var
    singularity_image: /opt/centos7.sif
    # Enabling strict host checking may cause the adapter to fail if the user's known_hosts does not have all the roundrobin hosts
    strict_host_checking: false
    tmux_bin: /bin/tmux
EOF

# Set up keycloak desktop option
cat > /etc/ood/config/apps/bc_desktop/single_cluster << EOF
---
title: "Keycloak Desktop"
cluster: "kc_host"
submit: "linux_host"
EOF

# Configure ondemand portal desktop application
mv /var/www/ood/apps/sys/bc_desktop/form.yml /var/www/ood/apps/sys/bc_desktop/form.yml.org
cat > /var/www/ood/apps/sys/bc_desktop/form.yml <<EOF
---
attributes:
  desktop: "mate"
#  desktop: "xfce"
  bc_vnc_idle: 0
  bc_vnc_resolution:
    required: true
  node_type: null
  cluster:
    widget: "select"
    options:
      - "kc_host"
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
  bc_account:
    label: "Account"
    value: "notchpeak-shared-short"
  bc_queue:
    label: "Partition"
    value: "notchpeak-shared-short"


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

systemctl restart httpd24-httpd