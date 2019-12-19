TARGET ?= suse.de
CONCOURSE_SECRETS_FILE ?= ../cloudfoundry/secure/concourse-secrets.yml.gpg
TERRAFORM_DATA_DIR ?= ../cloudfoundry/engcloud.prv.suse.net/terraform
NON_INTERACTIVE ?=

all: release

release: release-os-images release-stemcells release-fissile release-sles

release-os-images:
	bash -c "fly -t ${TARGET} set-pipeline ${NON_INTERACTIVE} \
		-c release/os-images.yml \
		-p bosh:release:os-images \
		-l shared_vars.yml \
		-l release/vars.yml \
		-l <(gpg --decrypt --batch --no-tty ${CONCOURSE_SECRETS_FILE} 2> /dev/null)"
	fly -t ${TARGET} unpause-pipeline -p bosh:release:os-images
	fly -t ${TARGET} expose-pipeline -p bosh:release:os-images

release-stemcells:
	bash -c "fly -t ${TARGET} set-pipeline ${NON_INTERACTIVE} \
		-c release/stemcells.yml \
		-p bosh:release:stemcells \
		-l shared_vars.yml \
		-l release/vars.yml \
		-l ${TERRAFORM_DATA_DIR}/vars.yml \
		-l <(gpg --decrypt --batch --no-tty ${CONCOURSE_SECRETS_FILE} 2> /dev/null) \
		-v openstack-private-key-data=\"`gpg --decrypt --batch --no-tty ${TERRAFORM_DATA_DIR}/bosh.pem.gpg 2> /dev/null`\""
	fly -t ${TARGET} unpause-pipeline -p bosh:release:stemcells
	fly -t ${TARGET} expose-pipeline -p bosh:release:stemcells

release-fissile:
	bash -c "fly -t ${TARGET} set-pipeline ${NON_INTERACTIVE} \
		-c fissile/pipeline.yml \
		-p fissile:release \
		-l shared_vars.yml \
		-l release/vars.yml \
		-l fissile/release_vars.yml \
		-l <(gpg --decrypt --batch --no-tty ${CONCOURSE_SECRETS_FILE} 2> /dev/null)"
	fly -t ${TARGET} unpause-pipeline -p fissile:release
	fly -t ${TARGET} expose-pipeline -p fissile:release

release-sles: release-sles-os-images release-sles-stemcell release-sles-aws

release-sles-os-images:
	cd sles-os-images && ./configure.sh

release-sles-stemcell:
	cd sles-stemcell && ./configure.sh

release-sles-aws: TARGET ?= sles
release-sles-aws:
	fly -t ${TARGET} login -k
	cd sles-aws && ./configure.sh
