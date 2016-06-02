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

# Update DNS
ctx logger info "Updating DNS..."

cat > /home/ubuntu/resolv.conf << EOF
nameserver ${dns_ip}
search example.com
domain example.com
EOF

sudo rm /run/resolvconf/resolv.conf
sudo rm /etc/resolv.conf
sudo cp /home/ubuntu/resolv.conf /run/resolvconf/resolv.conf
sudo chown root:root /run/resolvconf/resolv.conf
sudo ln -s /run/resolvconf/resolv.conf /etc/resolv.conf

cat > /home/ubuntu/dnsupdatefile << EOF
server ${dns_ip}
zone example.com
key example.com 8r6SIIX/cWE6b0Pe8l2bnc/v5vYbMSYvj+jQPP4bWe+CXzOpojJGrXI7iiustDQdWtBHUpWxweiHDWvLIp6/zw==
update add sprout-0.example.com. 30 A $(hostname -I)
update add sprout.example.com. 30 A $(hostname -I)
update add sprout.example.com. 30 NAPTR   1 1 "S" "SIP+D2T" "" _sip._tcp.sprout
update add _sip._tcp.sprout.example.com.  30 SRV     0 0 5054 sprout-0
update add icscf.sprout.example.com.  30 A  $(hostname -I)
update add icscf.sprout.example.com.  30 NAPTR   1 1 "S" "SIP+D2T" "" _sip._tcp.icscf.sprout
update add _sip._tcp.icscf.sprout.example.com.  30  SRV     0 0 5052 sprout-0
update add scscf.sprout.example.com. 30 A $(hostname -I)
send
EOF

retries=0
while ! { sudo nsupdate /home/ubuntu/dnsupdatefile
} && [ $retries -lt 10 ]
do
  retries=$((retries + 1))
  echo 'nsupdate failed - retrying (retry '$retries')...'
  ctx logger info "nsupdate failed retrying..."
  sleep 5
done

ctx instance runtime-properties dns_ip ${dns_ip}
