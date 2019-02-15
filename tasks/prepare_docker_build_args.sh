#!/bin/bash

tag="$TAG_PREFIX`cat semver.os-image/number`"
version=`cat versioned-stemcell/VERSION`

echo "$BUILD_ARGS_TMPL" | sed "s/base_image_tag_var/$tag/; s/version_var/$version/" > build_args/json
