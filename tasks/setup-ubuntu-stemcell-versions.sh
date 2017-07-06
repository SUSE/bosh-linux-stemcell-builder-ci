#!/usr/bin/env bash
#
# fissile stemcells have two sources that need to be reflected in their version:
#
# 1. The git repository containing the Dockerfile and assets, e.g. https://github.com/SUSE/fissile-stemcell-openSUSE
#
# The fissile stemcell git repository source is versioned using the latest tag that is reachable from the current
# commit, the number of additional commits since this tag and the abbreviated object name of the commit. The tag
# describes the OS version that is supported by this branch. Example version:
#
#   42.2-0.g58a22c9
#   |__| | |______|
#    |   |    |-> commit id
#    |   |-> number of commits since tag
#    |-> git tag (OS version)
#
# and
#
# 2. The docker base image containing the according base BOSH os-image, e.g.
#    https://hub.docker.com/r/splatform/os-image-opensuse/
#
# The os-image image has a version that describes the OS version plus a MAJOR and a MINOR version, e.g. `42.2-28.2`.
# The MAJOR version is bumped when new features or components are added, the MINOR version is bumped on security or
# other smaller fixes. Since the OS version always matches the fissile stemcell git repository one only MAJOR and MINOR
# versions are used.
#
#
# The final version is a concatenation of both parts and looks like this:
#
#   42.2-0.g58a22c9-28.2
#
# The version is used as a tag for the resulting fissile stemcell docker image (see
# https://hub.docker.com/r/splatform/fissile-stemcell-opensuse/tags/ for the latest versions).

set -x

set +o errexit +o nounset

test -n "${XTRACE}" && set -o xtrace

set -o errexit -o nounset

cp -r git.fissile-stemcell-ubuntu/. versioned-fissile-stemcell-ubuntu
cd versioned-fissile-stemcell-ubuntu
git fetch --tags

GIT_ROOT=${GIT_ROOT:-$(git rev-parse --show-toplevel)}
GIT_DESCRIBE=${GIT_DESCRIBE:-$(git describe --tags --long)}
GIT_BRANCH=${GIT_BRANCH:-$(git name-rev --name-only HEAD)}

GIT_TAG=${GIT_TAG:-$(echo ${GIT_DESCRIBE} | awk -F - '{ print $1 }' )}
GIT_COMMITS=${GIT_COMMITS:-$(echo ${GIT_DESCRIBE} | awk -F - '{ print $2 }' )}
GIT_SHA=${GIT_SHA:-$(echo ${GIT_DESCRIBE} | awk -F - '{ print $3 }' )}

ARTIFACT_VERSION=${GIT_TAG}-${GIT_COMMITS}.${GIT_SHA}
OS_IMAGE_VERSION=$(cat ../semver.os-image-ubuntu/number)
OS_IMAGE_VERSION_STRIPPED=$(cat ../semver.os-image-ubuntu/number | sed 's/\.0$//;s/\.0$//')

STEMCELL_VERSION=${ARTIFACT_VERSION}-${OS_IMAGE_VERSION_STRIPPED}

set +o errexit +o nounset +o xtrace

sed -i "s@FROM splatform/os-image-ubuntu:trusty@FROM splatform/$DOCKER_REPOSITORY:trusty-$OS_IMAGE_VERSION@" Dockerfile
echo $STEMCELL_VERSION > VERSION
