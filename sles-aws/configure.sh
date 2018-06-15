#!/usr/bin/env bash

set -ev

: ${TARGET:="sles"}

fly -t $TARGET set-pipeline \
  -p bosh:release-sles:aws-bats \
  -c pipeline.yml \
  -l ../shared_vars.yml \
  -l vars.yml \
  -v aws-ssh-public-key="$(cat ../../cloudfoundry/aws/bats/sles-bats.pem.pub)" \
  -v aws-ssh-private-key="$(cat ../../cloudfoundry/aws/bats/sles-bats.pem)" \
  $*
