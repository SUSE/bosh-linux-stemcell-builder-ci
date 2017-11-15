TARGET ?= skycastle
CONCOURSE_URL ?= http://concourse.suse.de/
GITHUB_ID ?= c29a4757ff0e43c25610
GITHUB_TEAM ?= 'SUSE/Team Alfred'
CONCOURSE_SECRETS_FILE ?= ../cloudfoundry/secure/concourse-secrets.yml.gpg

all: pipeline-master pipeline-check

login:
	fly -t ${TARGET} login  --concourse-url ${CONCOURSE_URL}

login-vancouver:
	fly -t vancouver login  --concourse-url https://ci.from-the.cloud

login-sandbox:
	fly -t sandbox login  --concourse-url http://192.168.100.4:8080/

pipeline-%: ${CONCOURSE_SECRETS_FILE}
	# Explicitly call bash here to get process substitution, otherwise make
	# runs the shell in a mode that doesn't support <(...)
	bash -c "fly -t ${TARGET} set-pipeline -n -c bosh-linux-stemcell-builder-$*.yml -p stemcells-$* -l <(gpg --decrypt --batch --no-tty ${CONCOURSE_SECRETS_FILE})"
	fly -t ${TARGET} unpause-pipeline -p stemcells-$*
