#!/bin/bash

set -e

state_path() { bosh-cli int director-state/director.yml --path="$1" ; }
creds_path() { bosh-cli int director-state/director-creds.yml --path="$1" ; }

source environment/metadata

cat > bats-config/bats.env <<EOF
export BOSH_ENVIRONMENT=$BOSH_internal_ip
export BOSH_CLIENT="admin"
export BOSH_CLIENT_SECRET="$( creds_path /admin_password )"
export BOSH_CA_CERT="$( creds_path /director_ssl/ca )"
export BOSH_GW_HOST="$( state_path /instance_groups/name=bosh/networks/name=public/static_ips/0 2>/dev/null )"
export BOSH_GW_USER="jumpbox"
export BAT_PRIVATE_KEY="$( creds_path /jumpbox_ssh/private_key )"

export BAT_DNS_HOST="$( state_path /instance_groups/name=bosh/networks/name=public/static_ips/0 2>/dev/null )"

export BAT_INFRASTRUCTURE=openstack
export BAT_NETWORKING=dynamic

export BAT_RSPEC_FLAGS="--tag ~manual_networking --tag ~raw_ephemeral_storage"
EOF

cat > interpolate.yml <<EOF
---
cpi: openstack
properties:
  pool_size: 1
  instances: 1
  vip: ((floating_ip))
  availability_zone: ((az))
  instance_type: ((instance_type))
  flavor_with_no_ephemeral_disk: ((flavor_with_no_ephemeral_disk))
  stemcell:
    name: ((STEMCELL_NAME))
    version: latest
  networks:
    - name: default
      type: dynamic
      cloud_properties:
        net_id: ((net_id))
        security_groups: ((default_security_groups))
EOF

bosh-cli interpolate \
 --vars-env "BATS" \
 -v STEMCELL_NAME=$STEMCELL_NAME \
 interpolate.yml \
 > bats-config/bats-config.yml
