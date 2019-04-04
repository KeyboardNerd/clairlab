#!/bin/bash
set -e

# Switch these to pull a different image or tag
REMOTE=$1
REPO=$2
TAG=$3
FOLDER="$REMOTE-$REPO-$TAG"
FOLDER="${FOLDER/\//-}"
echo $FOLDER

echo "REMOTE must be not empty"
test -n "$REMOTE"
echo "REPO must be not empty"
test -n "$REPO"
echo "TAG must be not empty"
test -n "$TAG"

mkdir -p $FOLDER

# Download the manifest again, and store it in a variable
manifest=$(curl -sL \
           -H 'Accept: application/vnd.docker.distribution.manifest.v2+json' \
           $REMOTE/v2/$REPO/manifests/$TAG)

if [[ -e "$FOLDER/manifest.json" ]]; then
    echo "We already have manifest.json, skip saving"
else
    echo $manifest | jq . > "$FOLDER/manifest.json"
fi

# Use jq to get a list of the layers we can iterate over
layers=$(echo $manifest | jq -r '.fsLayers[].blobSum')
INDEX=0
for layer in $layers; do
  echo "Pulling $INDEX layer: $layer"
  if [[ ! -e "$FOLDER/$INDEX-$layer.tar.gz" ]]; then
    # Use content addressability to avoid pulling layers we already have!
    curl -sL $REMOTE/v2/$REPO/blobs/$layer > $FOLDER/$INDEX-$layer.tar.gz
    mkdir -p $FOLDER/$INDEX-$layer
    tar -xf $FOLDER/$INDEX-$layer.tar.gz -C $FOLDER/$INDEX-$layer
  else
    echo "Existing layer, skip!"
  fi
  let INDEX=${INDEX}+1
done
