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

<<<<<<< HEAD:blueprints/clearwater-scripts-plugin-blueprint/scripts/sprout.sh
sudo -E bash -c 'cat > /etc/clearwater/shared_config << EOF
# Deployment definitions
home_domain=example.com
sprout_hostname=sprout.example.com
hs_hostname=hs.example.com:8888
hs_provisioning_hostname=hs.example.com:8889
ralf_hostname=ralf.example.com:10888
xdms_hostname=homer.example.com:7888

# Email server configuration
smtp_smarthost=localhost
smtp_username=username
smtp_password=password
email_recovery_sender=clearwater@example.org
                                                                                                                                                                                                     
# Keys
signup_key=secret
turn_workaround=secret
ellis_api_key=secret
ellis_cookie_key=secret

# eheiris: to use external HSS. TBD use FQDN for HSS.. 
# HSS configuration
hss_hostname=10.67.71.40
hss_port=3868
EOF'


=======
>>>>>>> cross-domain:blueprints/clearwater-scripts-plugin-blueprint/scripts/sprout-install.sh
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

<<<<<<< HEAD:blueprints/clearwater-scripts-plugin-blueprint/scripts/sprout.sh
sudo /usr/share/clearwater/clearwater-config-manager/scripts/upload_shared_config
#sudo /usr/share/clearwater/clearwater-config-manager/scripts/apply_shared_config --sync

# eheiris START for DNS
sudo mkdir -p /etc/resolvconf/resolv.conf.d
sudo touch /etc/resolvconf/resolv.conf.d/head
cat << EOF | sudo -E tee -a /etc/resolvconf/resolv.conf.d/head
nameserver ${dns_ip}
domain example.com
search example.com
EOF
sudo resolvconf -u


=======
>>>>>>> cross-domain:blueprints/clearwater-scripts-plugin-blueprint/scripts/sprout-install.sh
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
update add icscf.example.com.                   30 IN A $(hostname -I)
update add _sip.example.com.               30 SRV 0 0 5060 icscf
update add _sip._udp.example.com.               30 SRV 0 0 5060 icscf
update add _sip._tcp.example.com.               30 SRV 0 0 5060 icscf
update add scscf.example.com.                  30 IN A $(hostname -I)
update add _sip.scscf.example.com.              30 SRV 0 0 6060 scscf
update add _sip._udp.scscf.example.com.         30 SRV 0 0 6060 scscf
update add _sip._tcp.scscf.example.com.         30 SRV 0 0 6060 scscf
send
EOF

<<<<<<< HEAD:blueprints/clearwater-scripts-plugin-blueprint/scripts/sprout.sh



retries=0
while ! { sudo -E nsupdate -y "example.com:8r6SIIX/cWE6b0Pe8l2bnc/v5vYbMSYvj+jQPP4bWe+CXzOpojJGrXI7iiustDQdWtBHUpWxweiHDWvLIp6/zw==" -v /home/ubuntu/dnsupdatefile
=======
while ! { sudo nsupdate /home/ubuntu/dnsupdatefile
>>>>>>> cross-domain:blueprints/clearwater-scripts-plugin-blueprint/scripts/sprout-install.sh
} && [ $retries -lt 10 ]
do
  retries=$((retries + 1))
  echo 'nsupdate failed - retrying (retry '$retries')...'
  ctx logger info "nsupdate failed retrying..."
  sleep 5
done

ctx instance runtime-properties dns_ip ${dns_ip}
