#!/bin/bash

public_ip=$(ctx instance runtime_properties public_ip)
dns_ip=$(ctx instance runtime_properties dns_ip)

ctx logger info "remove sprout DNS record...${public_ip} $[dns_ip}"

retries=0
cat > /home/ubuntu/dnsupdatefile << EOF
server ${dns_ip}
zone example.com
key example.com 8r6SIIX/cWE6b0Pe8l2bnc/v5vYbMSYvj+jQPP4bWe+CXzOpojJGrXI7iiustDQdWtBHUpWxweiHDWvLIp6/zw==
update delete bono-0.example.com. 30 A ${public_ip}
update delete bono.example.com. 30 A ${public_ip}
update delete example.com. 30 NAPTR   1 1 "S" "SIP+D2T" "" _sip._tcp
update delete example.com. 30 NAPTR   2 1 "S" "SIP+D2U" "" _sip._udp
update delete _sip._tcp.example.com. 30 SRV     0 0 5060 bono-0
update delete _sip._udp.example.com. 30 SRV     0 0 5060 bono-0
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
