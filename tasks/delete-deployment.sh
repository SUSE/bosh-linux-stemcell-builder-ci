#!/usr/bin/env bash

set -ev

export bosh_cli=$(realpath bosh-cli/bosh-cli-*)
chmod +x $bosh_cli

export BOSH_ENVIRONMENT=`$bosh_cli int suse-cf/engcloud.prv.suse.net/bosh/vars.yml --path /external_ip`
export BOSH_CA_CERT=`$bosh_cli int suse-cf/engcloud.prv.suse.net/bosh/director-creds.yml --path /director_ssl/ca`
export BOSH_CLIENT=admin
export BOSH_CLIENT_SECRET=`$bosh_cli int suse-cf/engcloud.prv.suse.net/bosh/director-creds.yml --path /admin_password`

$bosh_cli -n delete-deployment -d $(cat environment/name) --force
$bosh_cli -n delete-config --type cloud --name $(cat environment/name)
