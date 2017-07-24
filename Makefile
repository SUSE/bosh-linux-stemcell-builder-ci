TARGET ?= skycastle
CONCOURSE_URL ?= http://concourse.suse.de/
GITHUB_ID ?= c29a4757ff0e43c25610
GITHUB_TEAM ?= 'SUSE/Team Alfred'

all: pipeline-master pipeline-check

login:
	fly -t ${TARGET} login  --concourse-url ${CONCOURSE_URL}

login-vancouver:
	fly -t vancouver login  --concourse-url https://ci.from-the.cloud

login-sandbox:
	fly -t sandbox login  --concourse-url http://192.168.100.4:8080/

pipeline-master:
	yes | fly -t ${TARGET} set-pipeline -c bosh-linux-stemcell-builder-master.yml -p stemcells-master -l ../cloudfoundry/secure/concourse-secrets.yml
	fly -t ${TARGET} unpause-pipeline -p stemcells-master

pipeline-check:
	yes | fly -t ${TARGET} set-pipeline -c bosh-linux-stemcell-builder-check.yml -p stemcells-check -l ../cloudfoundry/secure/concourse-secrets.yml
	fly -t ${TARGET} unpause-pipeline -p stemcells-check
