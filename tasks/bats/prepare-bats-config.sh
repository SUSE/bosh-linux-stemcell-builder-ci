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
export BAT_NETWORKING=manual

export BAT_RSPEC_FLAGS="--tag ~manual_networking --tag ~raw_ephemeral_storage"
EOF

cat > interpolate.yml <<EOF
---
cpi: openstack
properties:
  stemcell:
    name: ((STEMCELL_NAME))
    version: ((STEMCELL_VERSION))
  pool_size: 1
  instances: 1
  instance_type: ((instance_type))
  flavor_with_no_ephemeral_disk: ((flavor_with_no_ephemeral_disk)) 
  vip: ((floating_ip)) # Virtual (public/floating) IP assigned to the bat-release job vm ('static' network), for ssh testing
  second_static_ip: ((secondary_static_ip)) # Secondary (private) IP to use for reconfiguring networks, must be in the primary network & different from static_ip
  networks:
  - name: ((network_name))
    type: manual
    static_ip: ((primary_static_ip)) # Primary (private) IP assigned to the bat-release job vm (primary NIC), must be in the primary static range
    cloud_properties:
      net_id: ((net_id)) # Primary Network ID
      security_groups: ['bosh-concourse'] # Security groups assigned to deployed VMs
    cidr: ((internal_cidr))
    reserved: ((internal_reserved_range))
    static: ((internal_static_range))
    gateway: ((internal_gw))
  - name: second # Secondary network for testing jobs with multiple manual networks
    type: manual
    static_ip: 192.168.0.30 # Secondary (private) IP assigned to the bat-release job vm (secondary NIC)
    cloud_properties:
      net_id: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx # Secondary Network ID
      security_groups: ['default'] # Security groups assigned to deployed VMs
    cidr: 192.168.0.0/24
    reserved: ['192.168.0.2 - 192.168.0.9']
    static: ['192.168.0.10 - 192.168.0.30']
    gateway: 192.168.0.1
  key_name: bosh # (optional) SSH keypair name, overrides the director's default_key_name setting
  password: hash # (optional) vcap password hash
EOF

bosh-cli interpolate \
 --vars-env "BATS" \
 -v STEMCELL_NAME=$STEMCELL_NAME \
 interpolate.yml \
 > bats-config/bats-config.yml
