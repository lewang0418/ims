#!/bin/bash
# Update DNS
ctx logger info "Updating DNS ${dns_ip}"
ctx instance runtime-properties dns_ip ${dns_ip}

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
update add homer-0.example.com. 30 A $(hostname -I)
update add homer.example.com. 30 A $(hostname -I)
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

# configure node to identify its DNS server
# http://clearwater.readthedocs.io/en/stable/Clearwater_DNS_Usage.html?highlight=dns
sudo -E bash -c 'cat > /etc/dnsmasq.resolv.conf << EOF
nameserver ${dns_ip}
EOF'

sudo -E bash -c 'cat >> /etc/default/dnsmasq << EOF
RESOLV_CONF=/etc/dnsmasq.resolv.conf
EOF'

sudo service dnsmasq restart
