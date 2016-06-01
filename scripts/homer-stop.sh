#!/bin/bash
dns_ip=$(ctx instance runtime_properties dns_ip)
ctx logger info "remove sprout DNS record...$[dns_ip}"


retries=0
cat > /home/ubuntu/dnsupdatefile << EOF
server ${dns_ip}
zone example.com
key example.com 8r6SIIX/cWE6b0Pe8l2bnc/v5vYbMSYvj+jQPP4bWe+CXzOpojJGrXI7iiustDQdWtBHUpWxweiHDWvLIp6/zw==
update delete homer-0.example.com. 30 A $(hostname -I)
update delete homer.example.com. 30 A $(hostname -I)
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