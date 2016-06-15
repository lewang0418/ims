#!/bin/bash
dns_ip=$(ctx instance runtime_properties dns_ip)
ctx logger info "remove sprout DNS record...$[dns_ip}"

#retries=0
#cat > /home/ubuntu/dnsupdatefile << EOF
#server ${dns_ip}
#zone example.com
#key example.com 8r6SIIX/cWE6b0Pe8l2bnc/v5vYbMSYvj+jQPP4bWe+CXzOpojJGrXI7iiustDQdWtBHUpWxweiHDWvLIp6/zw==
#update delete sprout-0.example.com. 30 A $(hostname -I)
#update delete sprout.example.com. 30 A $(hostname -I)
#update delete sprout.example.com. 30 NAPTR   1 1 "S" "SIP+D2T" "" _sip._tcp.sprout
#update delete _sip._tcp.sprout.example.com.  30 SRV     0 0 5054 sprout-0
#update delete icscf.sprout.example.com.  30 A  $(hostname -I)
#update delete icscf.sprout.example.com.  30 NAPTR   1 1 "S" "SIP+D2T" "" _sip._tcp.icscf.sprout
#update delete _sip._tcp.icscf.sprout.example.com.  30  SRV     0 0 5052 sprout-0
#update delete scscf.sprout.example.com. 30 A $(hostname -I)
#send
#EOF

#while ! { sudo nsupdate /home/ubuntu/dnsupdatefile
#} && [ $retries -lt 10 ]
#do
#  retries=$((retries + 1))
#  echo 'nsupdate failed - retrying (retry '$retries')...'
#  ctx logger info "nsupdate failed retrying..."
#  sleep 5
#done
