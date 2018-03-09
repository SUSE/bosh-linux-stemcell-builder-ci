#!/usr/bin/env bash

set -ev

source /etc/profile.d/chruby.sh
chruby 2.1.7

export BOSH_stemcell_path=$(realpath stemcell/*.tgz)

cat > director-creds.yml <<EOF
internal_ip: $BOSH_internal_ip
EOF

export bosh_cli=$(realpath bosh-cli/bosh-cli-*)
chmod +x $bosh_cli

$bosh_cli interpolate bosh-deployment/bosh.yml \
  -o bosh-deployment/openstack/cpi.yml \
  -o bosh-deployment/openstack/custom-ca.yml \
  -o bosh-deployment/jumpbox-user.yml \
  -o bosh-deployment/external-ip-with-registry-not-recommended.yml \
  -o bosh-linux-stemcell-builder/ci/assets/local-stemcell.yml \
  --vars-store director-creds.yml \
  -v director_name=stemcell-smoke-tests-director \
  --var-file=private_key=<(echo "$BOSH_private_key_data") \
  --var-file=openstack_ca_cert=<(echo "$BOSH_openstack_ca_cert_data") \
  --vars-env "BOSH" > director.yml

$bosh_cli create-env director.yml -l director-creds.yml

# occasionally we get a race where director process hasn't finished starting
# before nginx is reachable causing "Cannot talk to director..." messages.
sleep 10

export BOSH_ENVIRONMENT=$BOSH_external_ip
export BOSH_CA_CERT=`$bosh_cli int director-creds.yml --path /director_ssl/ca`
export BOSH_CLIENT=admin
export BOSH_CLIENT_SECRET=`$bosh_cli int director-creds.yml --path /admin_password`

$bosh_cli -n update-cloud-config bosh-deployment/openstack/cloud-config.yml \
          --ops-file bosh-linux-stemcell-builder/ci/assets/reserve-ips.yml \
          --vars-env "BOSH"

mv $HOME/.bosh director-state/
mv director.yml director-creds.yml director-state.json director-state/
