#!/bin/bash

set -e

: ${TARGET:="suse.de"}
: ${CONCOURSE_SECRETS_FILE:="../../cloudfoundry/secure/concourse-secrets.yml.gpg"}
: ${TERRAFORM_DATA_DIR:="../../cloudfoundry/engcloud.prv.suse.net/terraform"}

fly -t $TARGET set-pipeline \
  -c pipeline.yml  \
  -p bosh:release-sles:stemcells \
  -l ../shared_vars.yml \
  -l vars.yml \
  -l <(gpg --decrypt --batch --no-tty "$CONCOURSE_SECRETS_FILE" 2> /dev/null) \
  -l $TERRAFORM_DATA_DIR/vars.yml \
  -v openstack-private-key-data="`gpg --decrypt --batch --no-tty $TERRAFORM_DATA_DIR/bosh.pem.gpg 2> /dev/null`" \
  $*
