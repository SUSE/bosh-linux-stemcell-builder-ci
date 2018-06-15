#!/usr/bin/env bash

set -e

source /etc/profile.d/chruby.sh
chruby 2.1.7

function cp_artifacts {
  mv $HOME/.bosh director-state/
  cp director.yml director-creds.yml director-state/
}

trap cp_artifacts EXIT

export BOSH_stemcell_path=$(realpath stemcell/*.tgz)

source environment/metadata

cat > director-creds.yml <<EOF
internal_ip: $BOSH_internal_ip
EOF

export bosh_cli=$(realpath bosh-cli/bosh-cli-*)
chmod +x $bosh_cli

export BOSH_ENVIRONMENT=`$bosh_cli int suse-cf/engcloud.prv.suse.net/bosh/vars.yml --path /external_ip`
export BOSH_CA_CERT=`$bosh_cli int suse-cf/engcloud.prv.suse.net/bosh/director-creds.yml --path /director_ssl/ca`
export BOSH_CLIENT=admin
export BOSH_CLIENT_SECRET=`$bosh_cli int suse-cf/engcloud.prv.suse.net/bosh/director-creds.yml --path /admin_password`

export BOSH_GW_PRIVATE_KEY=`$bosh_cli int suse-cf/engcloud.prv.suse.net/bosh/director-creds.yml --path /jumpbox_ssh/private_key`
export BOSH_GW_USER=vcap
export BOSH_GW_HOST=$BOSH_ENVIRONMENT

$bosh_cli -n update-config \
  --type cloud \
  --name $(cat environment/name) \
  --var=env_name=$(cat environment/name) \
  --vars-env "BOSH" \
  suse-ci/assets/cloud-config.yml

$bosh_cli -n upload-stemcell \
  $(realpath stemcell/*.tgz)

$bosh_cli interpolate bosh-deployment/bosh.yml \
  -o bosh-deployment/misc/source-releases/bosh.yml \
  -o bosh-deployment/openstack/cpi.yml \
  -o bosh-deployment/openstack/custom-ca.yml \
  -o bosh-deployment/misc/powerdns.yml \
  -o bosh-deployment/misc/dns.yml \
  -o bosh-deployment/misc/bosh-dev.yml \
  -o bosh-deployment/experimental/blobstore-https.yml \
  -o bosh-deployment/experimental/bpm.yml \
  -o suse-ci/assets/ops/rename-deployment.yml \
  -o suse-ci/assets/ops/rename-network.yml \
  -o suse-ci/assets/ops/rename-az.yml \
  -o suse-ci/assets/ops/custom-stemcell.yml \
  -o suse-ci/assets/ops/custom-static-ip.yml \
  -o suse-ci/assets/ops/custom-password.yml \
  --vars-store director-creds.yml \
  -v director_name=stemcell-smoke-tests-director \
  -v deployment_name=$(cat environment/name) \
  -v internal_dns="[$BOSH_dns_recursor_ip]" \
  -v stemcell_os=$BOSH_os_name \
  -v stemcell_version="\"$(cat stemcell/version)\"" \
  -v static_ip=$BOSH_internal_ip \
  --var-file=private_key=<(echo "$BOSH_private_key_data") \
  --var-file=openstack_ca_cert=<(echo "$BOSH_openstack_ca_cert_data") \
  --vars-env "BOSH" > director.yml

$bosh_cli -n deploy -d $(cat environment/name) -l director-creds.yml director.yml

# occasionally we get a race where director process hasn't finished starting
# before nginx is reachable causing "Cannot talk to director..." messages.
sleep 10

export BOSH_ENVIRONMENT=$BOSH_internal_ip
export BOSH_CA_CERT=`$bosh_cli int director-creds.yml --path /director_ssl/ca`
export BOSH_CLIENT=admin
export BOSH_CLIENT_SECRET=`$bosh_cli int director-creds.yml --path /admin_password`

$bosh_cli -n update-cloud-config bosh-deployment/openstack/cloud-config.yml \
          --ops-file bosh-linux-stemcell-builder/ci/assets/reserve-ips.yml \
          --vars-env "BOSH"
