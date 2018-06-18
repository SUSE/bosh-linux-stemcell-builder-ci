#!/usr/bin/env bash

set -eu

export BOSH_BINARY_PATH=$(realpath bosh-cli/bosh-cli-*)
chmod +x $BOSH_BINARY_PATH

state_path() { $BOSH_BINARY_PATH int director-state/director.yml --path="$1" ; }
creds_path() { $BOSH_BINARY_PATH int director-state/director-creds.yml --path="$1" ; }

name=$(cat environment/name)
export BOSH_ENVIRONMENT="$( state_path /instance_groups/name=bosh/networks/name=$name/static_ips/0 2>/dev/null )"
export BOSH_CLIENT="admin"
export BOSH_CLIENT_SECRET="$( creds_path /admin_password )"
export BOSH_CA_CERT="$( creds_path /director_ssl/ca )"
export BOSH_GW_HOST="$( state_path /instance_groups/name=bosh/networks/name=$name/static_ips/0 2>/dev/null )"
export BOSH_GW_USER="jumpbox"

export SYSLOG_RELEASE_PATH=$(realpath syslog-release/*.tgz)
export OS_CONF_RELEASE_PATH=$(realpath os-conf-release/*.tgz)
export STEMCELL_PATH=$(realpath stemcell/*.tgz)
export BOSH_stemcell_version=\"$(realpath stemcell/version | xargs -n 1 cat)\"

$BOSH_BINARY_PATH -n update-cloud-config bosh-deployment/aws/cloud-config.yml \
          --vars-file <( suse-ci/sles-aws/director-vars ) \
          --ops-file bosh-linux-stemcell-builder/ci/assets/reserve-ips.yml \
          --vars-env "BOSH"

jumpbox_private_key=$(mktemp)
$BOSH_BINARY_PATH int director-state/director-creds.yml --path /jumpbox_ssh/private_key > $jumpbox_private_key
chmod 0600 $jumpbox_private_key
export BOSH_GW_PRIVATE_KEY=$jumpbox_private_key

pushd bosh-linux-stemcell-builder
  export PATH=/usr/local/go/bin:$PATH
  export GOPATH=$(pwd)

  pushd src/github.com/cloudfoundry/stemcell-acceptance-tests
    ./bin/test-smoke $package
  popd
popd
