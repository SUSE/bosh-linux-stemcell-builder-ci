#!/bin/bash

set -ev

: ${TARGET:="suse.de"}
: ${CONCOURSE_SECRETS_FILE:="../../cloudfoundry/secure/concourse-secrets.yml.gpg"}

fly -t $TARGET set-pipeline \
  -c pipeline.yml  \
  -p bosh:develop-sles:os-images \
  -l ../shared_vars.yml \
  -l vars.yml \
  -l <(gpg --decrypt --batch --no-tty "$CONCOURSE_SECRETS_FILE" 2> /dev/null) \
  $*
