#!/bin/bash

set -eu

TASK_DIR=$PWD
TARGET_USER="${TARGET_USER:-ubuntu}"

cd bosh-linux-stemcell-builder

function check_param() {
  local name=$1
  local value=$(eval echo '$'$name)
  if [ "$value" == 'replace-me' ]; then
    echo "environment variable $name must be set"
    exit 1
  fi
}
check_param OPERATING_SYSTEM_NAME
check_param OPERATING_SYSTEM_VERSION

OS_IMAGE_NAME=$OPERATING_SYSTEM_NAME-$OPERATING_SYSTEM_VERSION
OS_IMAGE=$TASK_DIR/os-image/$OS_IMAGE_NAME.tgz

sudo chown -R $TARGET_USER .
sudo chmod u+s $(which sudo)
sudo --preserve-env --set-home --user $TARGET_USER -- /bin/bash --login -i <<SUDO
    bundle install --local
    bundle exec rake stemcell:build_os_image[$OPERATING_SYSTEM_NAME,$OPERATING_SYSTEM_VERSION,$OS_IMAGE]
SUDO
