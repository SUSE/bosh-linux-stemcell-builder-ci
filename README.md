# BOSH Linux Stemcell Builder Pipelines

This repository hosts the definitions for all the pipelines we use to build the openSUSE stemcells, both for BOSH and fissile.

We maintain 3 different "sets" of pipelines for the BOSH stemcells:

## Release Set (`bosh:release` namespace)

Uses the `opensuse_stemcell` branch of our bosh-linux-stemcell-builder fork. New builds are triggered by updates to the branch or by RPM updates to the os-images.
The set is comprised of 2 pipelines:
- os-images
- stemcells

The os-images pipeline is also building the `ubuntu:trusty` and `sle:12` images because we need them for the `fissile:release` pipeline (see details below).
  To build the sle image, we bring in the `sle_stemcell` branch of bosh-linux-stemcell-builder repo as well.

## Development Set (`bosh:develop` namespace)

Uses the `develop` branch of our bosh-linux-stemcell-builder fork.
New builds are triggered by merges to develop or by rpm updates to the os-images.
The set is comprised of 2 pipelines:
- os-images
- stemcells

The os-images pipeline is also building the `ubuntu:trusty` and `sle:12` images because we need them for the `fissile:develop` pipeline (see details below).

## Regression set (`bosh:regression` namespace).

Uses the `master` branch of the upstream bosh-linux-stemcell-builder repository. It is used to check if upstream changes break when building our stemcells.
This set is comprised of 2 pipelines:
- os-images
- stemcells

We only build opensuse stemcells in this set.

## Fissile Stemcells

We maintain 2 different pipelines for the fissile stemcells:

- The develop pipeline (`fissile:develop`).
  Uses the os-images built in bosh:develop:os-images to push the os-images to a docker registry and then build the fissile stemcells from that.
  The images are tagged like "docker.io/splatform/os-image-opensuse:develop-30.4.0" (notice the `develop` prefix)

- The release pipeline (`fissile:release`).
  Uses the os-images built in bosh:release:os-images to push the os-images to a docker registry and then build the fissile stemcells from that.
  The images are tagged like:
    - opensuse: "splatform/os-image-opensuse:42.3-30.2.0"
    - sle: "staging.registry.howdoi.website/splatform/os-image-sle12:12-0.92.0"
    - ubuntu: "splatform/os-image-ubuntu:trusty-3.2.0

# Setting Pipelines

There is a Makefile that should be used to deploy any of the pipelines (or all of them). Check the targets in the Makefile for more. Some examples:

- `make all` -> deploys all pipelines to the fly target specified by the $TARGET env var.
- `make release` -> deploys all `release` pipelines (both bosh and fissile).
