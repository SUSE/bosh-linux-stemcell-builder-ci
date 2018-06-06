#!/usr/bin/env bash

source /etc/profile.d/chruby.sh
chruby ruby

set -evo pipefail

function cp_artifacts {
  cp director.yml director-creds.yml director-state/
}

trap cp_artifacts EXIT

: ${BAT_INFRASTRUCTURE:?}
: ${BOSH_ENVIRONMENT:?}
: ${BOSH_CA_CERT:?}
: ${BOSH_CLIENT:?}
: ${BOSH_CLIENT_SECRET:?}


cp bosh-cli/bosh-cli-* /usr/local/bin/bosh-cli
chmod +x /usr/local/bin/bosh-cli

bosh-cli -n update-config \
  --type cloud \
  --name $(cat environment/name) \
  --var=env_name=$(cat environment/name) \
  --vars-file <( suse-ci/sles-aws/director-vars ) \
  suse-ci/assets/cloud-config-aws.yml

bosh-cli -n upload-stemcell $(realpath stemcell/*.tgz)

bosh-cli interpolate bosh-deployment/bosh.yml \
  -o bosh-deployment/$BAT_INFRASTRUCTURE/cpi.yml \
  -o bosh-deployment/misc/powerdns.yml \
  -o bosh-deployment/jumpbox-user.yml \
  -o bosh-src/ci/bats/ops/remove-health-monitor.yml \
  -o bosh-deployment/local-bosh-release-tarball.yml \
  -o bosh-deployment/misc/bosh-dev.yml \
  -o bosh-deployment/experimental/blobstore-https.yml \
  -o bosh-deployment/experimental/bpm.yml \
  -o suse-ci/assets/ops/rename-deployment.yml \
  -o suse-ci/assets/ops/rename-network.yml \
  -o suse-ci/assets/ops/custom-stemcell.yml \
  -v dns_recursor_ip=8.8.8.8 \
  -v director_name=$(cat environment/name) \
  -v deployment_name=$(cat environment/name) \
  -v local_bosh_release=$(realpath bosh-release/*.tgz) \
  -v stemcell_os=sles-12 \
  -v stemcell_version=$(cat stemcell/version) \
  --vars-file <( suse-ci/sles-aws/director-vars ) \
  $DEPLOY_ARGS \
  > director.yml

bosh-cli deploy -n \
  -d $(cat environment/name) \
  --vars-store director-creds.yml \
  director.yml
