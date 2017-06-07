#!/bin/bash

set -eu

PACKAGE_PATH="obs.fissile_base_image/home:DKarakasilis/fissile_base_image"
OUTPUT_PATH="obs.fissile_base_image-output"
cp -r $PACKAGE_PATH/. $OUTPUT_PATH
cp os-image/opensuse-leap.tgz $OUTPUT_PATH/fissile_base_image.tgz
