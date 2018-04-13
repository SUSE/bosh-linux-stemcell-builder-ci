TARGET ?= suse.de
CONCOURSE_SECRETS_FILE ?= ../cloudfoundry/secure/concourse-secrets.yml.gpg
TERRAFORM_DATA_DIR ?= ../cloudfoundry/engcloud.prv.suse.net/terraform
NON_INTERACTIVE ?=

all: release develop regression

release: release-os-images release-stemcells release-fissile

release-os-images:
	bash -c "fly -t ${TARGET} set-pipeline ${NON_INTERACTIVE} \
		-c release/os-images.yml \
		-p bosh:release:os-images \
		-l shared_vars.yml \
		-l release/vars.yml \
		-l <(gpg --decrypt --batch --no-tty ${CONCOURSE_SECRETS_FILE})"
	fly -t ${TARGET} unpause-pipeline -p bosh:release:os-images
	fly -t ${TARGET} expose-pipeline -p bosh:release:os-images

release-stemcells:
	bash -c "fly -t ${TARGET} set-pipeline ${NON_INTERACTIVE} \
		-c release/stemcells.yml \
		-p bosh:release:stemcells \
		-l shared_vars.yml \
		-l release/vars.yml \
		-l ${TERRAFORM_DATA_DIR}/vars.yml \
		-l <(gpg --decrypt --batch --no-tty ${CONCOURSE_SECRETS_FILE}) \
		-v openstack-private-key-data=\"`gpg --decrypt --batch --no-tty ${TERRAFORM_DATA_DIR}/bosh.pem.gpg`\""
	fly -t ${TARGET} unpause-pipeline -p bosh:release:stemcells
	fly -t ${TARGET} expose-pipeline -p bosh:release:stemcells

release-fissile:
	bash -c "fly -t ${TARGET} set-pipeline ${NON_INTERACTIVE} \
		-c fissile/pipeline.yml \
		-p fissile:release \
		-l shared_vars.yml \
		-l release/vars.yml \
		-l fissile/release_vars.yml \
		-l <(gpg --decrypt --batch --no-tty ${CONCOURSE_SECRETS_FILE})"
	fly -t ${TARGET} unpause-pipeline -p fissile:release
	fly -t ${TARGET} expose-pipeline -p fissile:release

develop: develop-os-images develop-stemcells develop-fissile

develop-os-images:
	bash -c "fly -t ${TARGET} set-pipeline ${NON_INTERACTIVE} \
		-c develop/os-images.yml \
		-p bosh:develop:os-images \
		-l shared_vars.yml \
		-l develop/vars.yml \
		-l <(gpg --decrypt --batch --no-tty ${CONCOURSE_SECRETS_FILE})"
	fly -t ${TARGET} unpause-pipeline -p bosh:develop:os-images
	fly -t ${TARGET} expose-pipeline -p bosh:develop:os-images

develop-stemcells:
	bash -c "fly -t ${TARGET} set-pipeline ${NON_INTERACTIVE} \
		-c develop/stemcells.yml \
		-p bosh:develop:stemcells \
		-l shared_vars.yml \
		-l develop/vars.yml \
		-l ${TERRAFORM_DATA_DIR}/vars.yml \
		-l <(gpg --decrypt --batch --no-tty ${CONCOURSE_SECRETS_FILE}) \
		-v openstack-private-key-data=\"`gpg --decrypt --batch --no-tty ${TERRAFORM_DATA_DIR}/bosh.pem.gpg`\""
	fly -t ${TARGET} unpause-pipeline -p bosh:develop:stemcells
	fly -t ${TARGET} expose-pipeline -p bosh:develop:stemcells

develop-fissile:
	bash -c "fly -t ${TARGET} set-pipeline ${NON_INTERACTIVE} \
		-c fissile/pipeline.yml \
		-p fissile:develop \
		-l shared_vars.yml \
		-l develop/vars.yml \
		-l fissile/develop_vars.yml \
		-l <(gpg --decrypt --batch --no-tty ${CONCOURSE_SECRETS_FILE})"
	fly -t ${TARGET} unpause-pipeline -p fissile:develop
	fly -t ${TARGET} expose-pipeline -p fissile:develop

regression: regression-os-images regression-stemcells

regression-os-images:
	bash -c "fly -t ${TARGET} set-pipeline ${NON_INTERACTIVE} \
		-c regression/os-images.yml \
		-p bosh:regression:os-images \
		-l shared_vars.yml \
		-l regression/vars.yml \
		-l <(gpg --decrypt --batch --no-tty ${CONCOURSE_SECRETS_FILE})"
	#fly -t ${TARGET} unpause-pipeline -p bosh:regression:os-images
	fly -t ${TARGET} expose-pipeline -p bosh:regression:os-images

regression-stemcells:
	bash -c "fly -t ${TARGET} set-pipeline ${NON_INTERACTIVE} \
		-c regression/stemcells.yml \
		-p bosh:regression:stemcells \
		-l shared_vars.yml \
		-l regression/vars.yml \
		-l ${TERRAFORM_DATA_DIR}/vars.yml \
		-l <(gpg --decrypt --batch --no-tty ${CONCOURSE_SECRETS_FILE}) \
		-v openstack-private-key-data=\"`gpg --decrypt --batch --no-tty ${TERRAFORM_DATA_DIR}/bosh.pem.gpg`\""
	#fly -t ${TARGET} unpause-pipeline -p bosh:regression:stemcells
	fly -t ${TARGET} expose-pipeline -p bosh:regression:stemcells
