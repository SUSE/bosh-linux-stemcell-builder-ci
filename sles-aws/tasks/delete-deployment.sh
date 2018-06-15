#!/usr/bin/env bash

set -e

POOL_NAME=`cat environment/name`

cp bosh-cli/bosh-cli-* /usr/local/bin/bosh-cli
chmod +x /usr/local/bin/bosh-cli

bosh-cli -n delete-deployment -d $POOL_NAME --force
bosh-cli -n delete-config --type cloud --name $POOL_NAME
