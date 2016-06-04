# Update DNS
ctx logger info "Updating DNS ${dns_ip}"
# Set public_ip in ctx
ctx instance runtime-properties dns_ip ${dns_ip}
public_ip=$(ctx instance runtime_properties public_ip)
ctx logger info " ip ${public_ip}"
public_ip=`cat /home/ubuntu/public_ip`
ctx logger info " ip ${public_ip}"

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

# Update DNS
cat > /home/ubuntu/dnsupdatefile << EOF
server ${dns_ip}
zone example.com
key example.com 8r6SIIX/cWE6b0Pe8l2bnc/v5vYbMSYvj+jQPP4bWe+CXzOpojJGrXI7iiustDQdWtBHUpWxweiHDWvLIp6/zw==
update add example.com. 30 A ${public_ip}
update add bono-0.example.com. 30 A ${public_ip}
update add example.com. 30 NAPTR   1 1 "S" "SIP+D2T" "" _sip._tcp
update add example.com. 30 NAPTR   2 1 "S" "SIP+D2U" "" _sip._udp
update add _sip._tcp.example.com. 30 SRV     0 0 5060 bono-0
update add _sip._udp.example.com. 30 SRV     0 0 5060 bono-0
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

# configure node to identify its DNS server
# http://clearwater.readthedocs.io/en/stable/Clearwater_DNS_Usage.html?highlight=dns
sudo -E bash -c 'cat > /etc/dnsmasq.resolv.conf << EOF
nameserver ${dns_ip}
EOF'

sudo -E bash -c 'cat >> /etc/default/dnsmasq << EOF
RESOLV_CONF=/etc/dnsmasq.resolv.conf
EOF'

sudo service dnsmasq restart
