#!/bin/bash

set -e

function check_param() {
  local name=$1
  local value=$(eval echo '$'$name)
  if [ "$value" == 'replace-me' ]; then
    echo "environment variable $name must be set"
    exit 1
  fi
}

check_param IAAS
check_param HYPERVISOR
check_param OS_NAME
check_param OS_VERSION

# optional
: ${BOSHIO_TOKEN:=""}

# outputs
output_dir="stemcell"
mkdir -p ${output_dir}

export TASK_DIR=$PWD
export CANDIDATE_BUILD_NUMBER=$( cat semver.bosh-stemcell/number | sed 's/\.0$//;s/\.0$//' )

# This is copied from https://github.com/concourse/concourse/blob/3c070db8231294e4fd51b5e5c95700c7c8519a27/jobs/baggageclaim/templates/baggageclaim_ctl.erb#L23-L54
# helps the /dev/mapper/control issue and lets us actually do scary things with the /dev mounts
# This allows us to create device maps from partition tables in image_create/apply.sh
function permit_device_control() {
  local devices_mount_info=$(cat /proc/self/cgroup | grep devices)

  local devices_subsytems=$(echo $devices_mount_info | cut -d: -f2)
  local devices_subdir=$(echo $devices_mount_info | cut -d: -f3)

  cgroup_dir=/mnt/tmp-todo-devices-cgroup

  if [ ! -e ${cgroup_dir} ]; then
    # mount our container's devices subsystem somewhere
    mkdir ${cgroup_dir}
  fi

  if ! mountpoint -q ${cgroup_dir}; then
    mount -t cgroup -o $devices_subsytems none ${cgroup_dir}
  fi

  # permit our cgroup to do everything with all devices
  # ignore failure in case something has already done this; echo appears to
  # return EINVAL, possibly because devices this affects are already in use
  echo a > ${cgroup_dir}${devices_subdir}/devices.allow || true
}

permit_device_control

# Also copied from baggageclaim_ctl.erb creates 64 loopback mappings. This fixes failures with losetup --show --find ${disk_image}
for i in $(seq 0 64); do
  if ! mknod -m 0660 /dev/loop$i b 7 $i; then
    break
  fi
done

chown -R ubuntu:ubuntu src

sudo chmod u+s $(which sudo)

# Monkey patch dependency fetcher to always download the latest image version
# from S3 as opposed to the upstream version which downloads a version set
# in a json file:
# https://github.com/cloudfoundry/src/blob/master/bosh-dev/lib/bosh/dev/stemcell_dependency_fetcher.rb#L16
# Also use the correct bucket url format
dependency_fetcher_path="$PWD/src/bosh-dev/lib/bosh/dev/stemcell_dependency_fetcher.rb"
original_fetcher_sha1="77bfeecc549ada4ba9312e932364c8c8b2adf122"
current_fetcher_sha1=$(sha1sum "$dependency_fetcher_path" | cut -d" " -f1)

sudo --preserve-env --set-home --user ubuntu -- /bin/bash --login -i <<SUDO
  set -e

  if [ "$current_fetcher_sha1" != "$original_fetcher_sha1" ]; then
    echo "Dependency fetcher is changed upstream. We won't monkey patch an unknown version."
    echo "Exiting."
    exit 1
  else
    cp ci/assets/stemcell_dependency_fetcher.rb "$dependency_fetcher_path"
  fi

  cd src

  # Set the aws bucket where the os images live unless already set
  : ${OS_IMAGE_BUCKET:=bosh-os-images}

  bundle install --local
  bundle exec rake stemcell:build[$IAAS,$HYPERVISOR,$OS_NAME,$OS_VERSION,$OS_IMAGE_BUCKET,bosh-$OS_NAME-$OS_VERSION-os-image.tgz,$CANDIDATE_BUILD_NUMBER]
  rm -f ./tmp/base_os_image.tgz
SUDO

stemcell_name="bosh-stemcell-$CANDIDATE_BUILD_NUMBER-$IAAS-$HYPERVISOR-$OS_NAME-$OS_VERSION-go_agent"

if [ -e src/tmp/*-raw.tgz ] ; then
  # openstack currently publishes raw files
  raw_stemcell_filename="${stemcell_name}-raw.tgz"
  mv src/tmp/*-raw.tgz "${output_dir}/${raw_stemcell_filename}"

  raw_checksum="$(sha1sum "${output_dir}/${raw_stemcell_filename}" | awk '{print $1}')"
  echo "$raw_stemcell_filename sha1=$raw_checksum"
  if [ -n "${BOSHIO_TOKEN}" ]; then
    curl -X POST \
      --fail \
      -d "sha1=${raw_checksum}" \
      -H "Authorization: bearer ${BOSHIO_TOKEN}" \
      "https://bosh.io/checksums/${raw_stemcell_filename}"
  fi
fi

stemcell_filename="${stemcell_name}.tgz"
mv "src/tmp/${stemcell_filename}" "${output_dir}/${stemcell_filename}"

checksum="$(sha1sum "${output_dir}/${stemcell_filename}" | awk '{print $1}')"
echo "$stemcell_filename sha1=$checksum"
if [ -n "${BOSHIO_TOKEN}" ]; then
  curl -X POST \
    --fail \
    -d "sha1=${checksum}" \
    -H "Authorization: bearer ${BOSHIO_TOKEN}" \
    "https://bosh.io/checksums/${stemcell_filename}"
fi
