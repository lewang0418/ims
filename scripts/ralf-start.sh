#!/bin/bash
ctx logger info "Updating HSS ${hss_ip} ${hss_port}"
sudo -E bash -c 'cat > /etc/clearwater/shared_config << EOF
# Deployment definitions
home_domain=example.com
sprout_hostname=sprout.example.com
hs_hostname=hs.example.com:8888
hs_provisioning_hostname=hs.example.com:8889
ralf_hostname=ralf.example.com:10888
xdms_hostname=homer.example.com:7888

# HSS configuration
hss_hostname=${hss_ip}
hss_realm=example.com
hss_port=${hss_port}

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

upstream_hostname=scscf.\$sprout_hostname
upstream_port=5054

EOF'

sudo /usr/share/clearwater/clearwater-config-manager/scripts/upload_shared_config

