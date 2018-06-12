#!/usr/bin/env bash

set -e

if [ -z "$BOSH_DIRECTOR_NAME"]; then
  BOSH_DIRECTOR_NAME=`cat environment/name`
fi

cp bosh-cli/bosh-cli-* /usr/local/bin/bosh-cli
chmod +x /usr/local/bin/bosh-cli

bosh-cli -n delete-deployment -d $BOSH_DIRECTOR_NAME --force
bosh-cli -n delete-config --type cloud --name $BOSH_DIRECTOR_NAME
