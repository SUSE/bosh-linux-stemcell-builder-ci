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

POOL_NAME=`cat environment/name`
if [ -z "$BOSH_DIRECTOR_NAME"]; then
  BOSH_DIRECTOR_NAME="$POOL_NAME"
fi

cp bosh-cli/bosh-cli-* /usr/local/bin/bosh-cli
chmod +x /usr/local/bin/bosh-cli

bosh-cli -n update-config \
  --type cloud \
  --name $POOL_NAME \
  --var=env_name=$POOL_NAME \
  --vars-file <( suse-ci/sles-aws/director-vars ) \
  suse-ci/assets/cloud-config-aws.yml

bosh-cli -n upload-stemcell $(realpath stemcell/*.tgz)

bosh-cli interpolate bosh-deployment/bosh.yml \
  -o bosh-deployment/$BAT_INFRASTRUCTURE/cpi.yml \
  -o bosh-deployment/misc/powerdns.yml \
  -o bosh-deployment/jumpbox-user.yml \
  -o bosh-src/ci/bats/ops/remove-health-monitor.yml \
  -o bosh-deployment/misc/source-releases/bosh.yml \
  -o bosh-deployment/misc/bosh-dev.yml \
  -o suse-ci/assets/ops/rename-deployment.yml \
  -o suse-ci/assets/ops/rename-network.yml \
  -o suse-ci/assets/ops/custom-stemcell.yml \
  -v dns_recursor_ip=8.8.8.8 \
  -v director_name=$BOSH_DIRECTOR_NAME \
  -v deployment_name=$POOL_NAME \
  -v stemcell_os=sles-12 \
  -v stemcell_version="\"$(cat stemcell/version)\"" \
  --vars-file <( suse-ci/sles-aws/director-vars ) \
  $DEPLOY_ARGS \
  > director.yml

bosh-cli deploy -n \
  -d $POOL_NAME \
  --vars-store director-creds.yml \
  director.yml
