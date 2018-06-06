#!/usr/bin/env bash

set -ev

: ${TARGET:="sles"}
: ${CONCOURSE_SECRETS_FILE:="../../cloudfoundry/secure/concourse-secrets.yml.gpg"}

fly -t $TARGET set-pipeline \
  -p bosh:release-sles:aws-bats \
  -c pipeline.yml \
  -l vars.yml \
  -v aws-ssh-public-key="$(cat ../../cloudfoundry/aws/bats/sles-bats.pem.pub)" \
  -v aws-ssh-private-key="$(cat ../../cloudfoundry/aws/bats/sles-bats.pem)" \
  -l <(gpg --decrypt --batch --no-tty "$CONCOURSE_SECRETS_FILE" 2> /dev/null) \
  $*
