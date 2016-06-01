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
public_hostname=homestead-0.example.com
etcd_cluster=$(hostname -I)
EOF

<<<<<<< HEAD:blueprints/clearwater-scripts-plugin-blueprint/scripts/homestead.sh
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
>>>>>>> cross-domain:blueprints/clearwater-scripts-plugin-blueprint/scripts/homestead-install.sh

# Now install the software.
# "-o DPkg::options::=--force-confnew" works around https://github.com/Metaswitch/clearwater-infrastructure/issues/186.
sudo DEBIAN_FRONTEND=noninteractive apt-get install clearwater-cassandra --yes --force-yes -o DPkg::options::=--force-confnew
sudo DEBIAN_FRONTEND=noninteractive apt-get install homestead homestead-prov --yes --force-yes -o DPkg::options::=--force-confnew
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
update add homestead-0.example.com. 30 A $(hostname -I)
update add hs.example.com. 30 A $(hostname -I)
send
EOF

while ! { sudo nsupdate /home/ubuntu/dnsupdatefile
} && [ $retries -lt 10 ]
do
  retries=$((retries + 1))
  echo 'nsupdate failed - retrying (retry '$retries')...'
  ctx logger info "nsupdate failed retrying..."
  sleep 5
done


ctx instance runtime-properties dns_ip ${dns_ip}
