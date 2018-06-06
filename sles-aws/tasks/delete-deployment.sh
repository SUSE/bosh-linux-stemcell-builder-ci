#!/usr/bin/env bash

set -e

cp bosh-cli/bosh-cli-* /usr/local/bin/bosh-cli
chmod +x /usr/local/bin/bosh-cli

bosh-cli -n delete-deployment -d $(cat environment/name) --force
bosh-cli -n delete-config --type cloud --name $(cat environment/name)
