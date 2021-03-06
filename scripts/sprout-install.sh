#!/bin/bash

exec > >(sudo tee -a /var/log/clearwater-cloudify.log) 2>&1

# Configure the APT software source.
echo 'deb http://repo.cw-ngv.com/stable binary/' | sudo tee -a /etc/apt/sources.list.d/clearwater.list
curl -L http://repo.cw-ngv.com/repo_key | sudo apt-key add -
sudo apt-get update

# Configure /etc/clearwater/local_config.
sudo mkdir -p /etc/clearwater
etcd_ip=$(hostname -I)
cat << EOF | sudo -E tee -a /etc/clearwater/local_config
local_ip=$(hostname -I)
public_ip=$(hostname -I)
public_hostname=sprout-0.example.com
etcd_cluster=$(hostname -I)
EOF

# Create /etc/chronos/chronos.conf.
sudo mkdir -p /etc/chronos
sudo -E bash -c 'cat > /etc/chronos/chronos.conf << EOF
[http]
bind-address = $(hostname -I)
bind-port = 7253
threads = 50
                                 
[logging]
folder = /var/log/chronos
level = 2
                                                                                                   
[alarms]
enabled = true
                                                                                                                                                   
[exceptions]
max_ttl = 600
EOF'

# Now install the software.
# "-o DPkg::options::=--force-confnew" works around https://github.com/Metaswitch/clearwater-infrastructure/issues/186.
sudo DEBIAN_FRONTEND=noninteractive apt-get install sprout --yes --force-yes -o DPkg::options::=--force-confnew
sudo DEBIAN_FRONTEND=noninteractive apt-get install clearwater-management --yes --force-yes

# Enable logging
cat << EOF | sudo -E tee -a /etc/clearwater/user_settings
log_level=5
EOF
