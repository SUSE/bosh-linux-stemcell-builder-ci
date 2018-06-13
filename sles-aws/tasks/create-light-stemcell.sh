#!/usr/bin/env bash

set -eo pipefail

: ${AWS_ACCESS_KEY_ID:?}
: ${AWS_SECRET_ACCESS_KEY:?}
: ${AWS_DEFAULT_REGION:?}
: ${ami_bucket_name:?}
: ${ami_region:?}
: ${ami_destinations:?}

mb_to_gb() {
  mb="$1"
  echo "$(( (${mb}+1024-1)/1024 ))"
}

output_path="$PWD/light-stemcell/"

stemcell_path=$(realpath input-stemcell/*.tgz)
original_stemcell_name="$(basename ${stemcell_path})"
light_stemcell_name="light-${original_stemcell_name}"

echo "Building light stemcell..."
echo "  Starting region: ${ami_region}"
echo "  Copy regions: ${ami_destinations}"

export CONFIG_PATH="$PWD/config.json"

cat > $CONFIG_PATH << EOF
{
  "ami_configuration": {
    "description":          "SLES BOSH Stemcell light",
    "virtualization_type":  "hvm",
    "visibility":           "private"
  },
  "ami_regions": [
    {
      "name":               "$ami_region",
      "credentials": {
        "access_key":       "$AWS_ACCESS_KEY_ID",
        "secret_key":       "$AWS_SECRET_ACCESS_KEY"
      },
      "bucket_name":        "$ami_bucket_name",
      "destinations":       $ami_destinations
    }
  ]
}
EOF

extracted_stemcell_dir=$PWD/extracted-stemcell
mkdir -p "$extracted_stemcell_dir"
tar -C "$extracted_stemcell_dir" -xf "$stemcell_path"
tar -xf "$extracted_stemcell_dir/image"

# image format can be raw or stream optimized vmdk
stemcell_image="$(echo $PWD/root.*)"
stemcell_manifest="$extracted_stemcell_dir/stemcell.MF"
manifest_contents="$(cat $stemcell_manifest)"

disk_regex="disk: ([0-9]+)"
format_regex="disk_format: ([a-z]+)"

[[ "${manifest_contents}" =~ ${disk_regex} ]]
disk_size_gb=$(mb_to_gb "${BASH_REMATCH[1]}")

[[ "${manifest_contents}" =~ ${format_regex} ]]
disk_format="${BASH_REMATCH[1]}"

pushd "bosh-aws-light-stemcell-builder"
  . .envrc
  go run src/light-stemcell-builder/main.go \
    -c $CONFIG_PATH \
    --image "$stemcell_image" \
    --format "$disk_format" \
    --volume-size "$disk_size_gb" \
    --manifest "$stemcell_manifest" \
    | tee tmp-manifest

  mv tmp-manifest "$stemcell_manifest"
popd

pushd "$extracted_stemcell_dir"
  > image
  # the bosh cli sees the stemcell as invalid if tar contents have leading ./
  tar -czf ${output_path}/${light_stemcell_name} *
popd
tar -tf ${output_path}/${light_stemcell_name}
