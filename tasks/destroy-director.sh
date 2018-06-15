#!/usr/bin/env bash

set -e

cp bosh-cli/bosh-cli-* /usr/local/bin/bosh-cli
chmod +x /usr/local/bin/bosh-cli

state_path() { bosh-cli int director-state/director.yml --path="$1" ; }

source environment/metadata
export BOSH_ENVIRONMENT=$BOSH_internal_ip
export BOSH_CA_CERT=`bosh-cli int director-state/director-creds.yml --path /director_ssl/ca`
export BOSH_CLIENT=admin
export BOSH_CLIENT_SECRET=`bosh-cli int director-state/director-creds.yml --path /admin_password`

set +e

bosh-cli deployments --column name | xargs -n1 -I % bosh-cli -n -d % delete-deployment
bosh-cli clean-up -n --all
