#!/bin/bash

# Set up linux_host adapter for frisco1
mkdir /etc/ood/config/clusters.d
cat > /etc/ood/config/clusters.d/frisco1.yml <<EOF
---
v2:
  metadata:
    title: "frisco1"
    url: "https://www.chpc.utah.edu/documentation/guides/frisco-nodes.php"
    hidden: false
  login:
    host: "frisco1.chpc.utah.edu"
  job:
    adapter: "linux_host"
    submit_host: "frisco1.chpc.utah.edu"  # This is the head for a login round robin
    ssh_hosts: # These are the actual login nodes, need to have full host name for the regex to work
      - frisco1.chpc.utah.edu
    site_timeout: 7200
    debug: true
    singularity_bin: /uufs/chpc.utah.edu/sys/installdir/singularity3/std/bin/singularity
    singularity_bindpath: /etc,/mnt,/media,/opt,/run,/srv,/usr,/var,/uufs,/scratch
#    singularity_image: /opt/ood/linuxhost_adapter/centos7_lmod.sif
    singularity_image: /uufs/chpc.utah.edu/sys/installdir/ood/centos7_lmod.sif
    # Enabling strict host checking may cause the adapter to fail if the user's known_hosts does not have all the roundrobin hosts
    strict_host_checking: false
    tmux_bin: /usr/bin/tmux
  batch_connect:
    basic:
      script_wrapper: |
        #!/bin/bash
        set -x
         if [ -z "$LMOD_VERSION" ]; then
            source /etc/profile.d/chpc.sh
         fi
        export XDG_RUNTIME_DIR=$(mktemp -d)
        %s
      set_host: "host=$(hostname -s).chpc.utah.edu"
    vnc:
      script_wrapper: |
        #!/bin/bash
        set -x
        export PATH="/uufs/chpc.utah.edu/sys/installdir/turbovnc/std/opt/TurboVNC/bin:$PATH"
        export WEBSOCKIFY_CMD="/uufs/chpc.utah.edu/sys/installdir/websockify/0.8.0/bin/websockify"
        export XDG_RUNTIME_DIR=$(mktemp -d)
        %s
      set_host: "host=$(hostname -s).chpc.utah.edu"
#      set_host: "host=$(hostname -A | awk '{print $3}')"
EOF

# Set up frisco.yml host
cat > /etc/ood/config/apps/bc_desktop/single_cluster/frisco.yml <<EOF
---
title: "Frisco Desktop"
cluster: "frisco"
submit: "linux_host"
attributes:
  bc_queue: null
  bc_account: null
  bc_num_slots: 1
  num_cores: none
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
      - "frisco1"
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