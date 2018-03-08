#!/bin/bash

tag="$TAG_PREFIX`cat semver.os-image/number`"

echo "$BUILD_ARGS_TMPL" | sed "s/base_image_tag_var/$tag/" > build_args/json
