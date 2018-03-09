#!/usr/bin/env bash

source /etc/profile.d/chruby.sh
chruby 2.1.7

set -e

function cp_artifacts {
  mv $HOME/.bosh director-state/
  cp director.yml director-creds.yml director-state.json director-state/
}

trap cp_artifacts EXIT

: ${BAT_INFRASTRUCTURE:?}

mv bosh-cli/bosh-cli-* /usr/local/bin/bosh-cli
chmod +x /usr/local/bin/bosh-cli

bosh-cli interpolate bosh-deployment/bosh.yml \
  -o bosh-deployment/$BAT_INFRASTRUCTURE/cpi.yml \
  -o bosh-deployment/openstack/custom-ca.yml \
  -o bosh-deployment/external-ip-with-registry-not-recommended.yml \
  -o bosh-deployment/misc/powerdns.yml \
  -o bosh-deployment/misc/dns.yml \
  -o bosh-deployment/jumpbox-user.yml \
  -o bosh-linux-stemcell-builder/ci/bats/ops/remove-health-monitor.yml \
  -o bosh-deployment/local-bosh-release.yml \
  -o bosh-linux-stemcell-builder/ci/bats/ops/use-candidate-stemcell.yml \
  -o suse-ci/assets/ops/custom-flavor.yml \
  -v internal_dns="[$BOSH_dns_recursor_ip]" \
  -v director_name=bats-director \
  -v local_bosh_release=$(realpath bosh-release/*.tgz) \
  -v local_candidate_stemcell=$(realpath stemcell/*.tgz) \
  --var-file=private_key=<(echo "$BOSH_private_key_data") \
  --var-file=openstack_ca_cert=<(echo "$BOSH_openstack_ca_cert_data") \
  --vars-env "BOSH" \
  > director.yml

bosh-cli create-env \
  --state director-state.json \
  --vars-store director-creds.yml \
  director.yml
