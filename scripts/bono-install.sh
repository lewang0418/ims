#!/bin/bash 
ctx logger info "In Bono ${public_ip}   ${dns_ip}   "

echo "In Bono ${public_ip}   ${dns_ip}   " > /home/ubuntu/dnsfile

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
public_ip=$public_ip
public_hostname=$public_ip
etcd_cluster=$(hostname -I)
EOF

<<<<<<< HEAD:blueprints/clearwater-scripts-plugin-blueprint/scripts/bono.sh
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
>>>>>>> cross-domain:blueprints/clearwater-scripts-plugin-blueprint/scripts/bono-install.sh

# Now install the software.
# "-o DPkg::options::=--force-confnew" works around https://github.com/Metaswitch/clearwater-infrastructure/issues/186.
sudo DEBIAN_FRONTEND=noninteractive apt-get install bono restund --yes --force-yes -o DPkg::options::=--force-confnew
sudo DEBIAN_FRONTEND=noninteractive apt-get install clearwater-config-manager --yes --force-yes

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

sudo mkdir -p /etc/resolvconf/resolv.conf.d
sudo touch /etc/resolvconf/resolv.conf.d/head
cat << EOF | sudo -E tee -a /etc/resolvconf/resolv.conf.d/head
nameserver ${dns_ip}
domain example.com
search example.com
EOF
sudo resolvconf -u

cat > /home/ubuntu/dnsupdatefile << EOF
server ${dns_ip}
zone example.com
key example.com 8r6SIIX/cWE6b0Pe8l2bnc/v5vYbMSYvj+jQPP4bWe+CXzOpojJGrXI7iiustDQdWtBHUpWxweiHDWvLIp6/zw==
update add bono-0.example.com. 30 A ${public_ip}
<<<<<<< HEAD:blueprints/clearwater-scripts-plugin-blueprint/scripts/bono.sh
update add example.com. 30 A ${public_ip}
update add example.com. 30 NAPTR   1 1 "S" "SIP+D2T" "" _sip._tcp
update add example.com. 30 NAPTR   2 1 "S" "SIP+D2U" "" _sip._udp
update add _sip._tcp.example.com. 30 SRV     0 0 5060 bono-0
update add _sip._udp.example.com. 30 SRV     0 0 5060 bono-0
update add pcscf.example.com.                30 IN A ${public_ip}
update add _sip.pcscf.example.com              30 SRV 0 0 4060 pcscf
update add _sip._udp.pcscf.example.com         30 SRV 0 0 4060 pcscf
update add _sip._tcp.pcscf.example.com         30 SRV 0 0 4060 pcscf
send
EOF

# Update DNS
retries=0
while ! { sudo -E nsupdate -y "example.com:8r6SIIX/cWE6b0Pe8l2bnc/v5vYbMSYvj+jQPP4bWe+CXzOpojJGrXI7iiustDQdWtBHUpWxweiHDWvLIp6/zw==" -v /home/ubuntu/dnsupdatefile
=======
update add bono.example.com. 30 A ${public_ip}
send
EOF

while ! { sudo nsupdate /home/ubuntu/dnsupdatefile
>>>>>>> cross-domain:blueprints/clearwater-scripts-plugin-blueprint/scripts/bono-install.sh
} && [ $retries -lt 10 ]
do
  retries=$((retries + 1))
  echo 'nsupdate failed - retrying (retry '$retries')...'
  ctx logger info "nsupdate failed retrying..."
  sleep 5
done

ctx instance runtime-properties public_ip ${public_ip}
ctx instance runtime-properties dns_ip ${dns_ip}
