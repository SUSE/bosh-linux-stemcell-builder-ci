TARGET ?= skycastle
CONCOURSE_URL ?= http://concourse.suse.de/
GITHUB_ID ?= c29a4757ff0e43c25610
GITHUB_TEAM ?= 'SUSE/Team Alfred'
CONCOURSE_SECRETS_FILE ?= ../cloudfoundry/secure/concourse-secrets.yml.gpg
TMP_SECRETS_FILE := $(shell mktemp -t tmp-concourseXXXXXX)

all: pipeline-master pipeline-check

login:
	fly -t ${TARGET} login  --concourse-url ${CONCOURSE_URL}

login-vancouver:
	fly -t vancouver login  --concourse-url https://ci.from-the.cloud

login-sandbox:
	fly -t sandbox login  --concourse-url http://192.168.100.4:8080/

pipeline-%:
	gpg --decrypt --batch --no-tty ${CONCOURSE_SECRETS_FILE} > ${TMP_SECRETS_FILE} 2> /dev/null
	yes | fly -t ${TARGET} set-pipeline -c bosh-linux-stemcell-builder-$*.yml -p stemcells-$* -l ${TMP_SECRETS_FILE}
	fly -t ${TARGET} unpause-pipeline -p stemcells-$*
	rm -f ${TMP_SECRETS_FILE}
