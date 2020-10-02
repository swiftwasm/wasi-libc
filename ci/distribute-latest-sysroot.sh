#!/bin/bash
set -eu

ROOT_DIR="$(cd "$(dirname $0)/../" && pwd)"
BUILD_DIR="$ROOT_DIR/build"
SYSROOT_TAR="$BUILD_DIR/wasi-sysroot.tar.gz"

"$ROOT_DIR/ci/build-sysroot.sh"

YEAR=$(date +"%Y")
MONTH=$(date +"%m")
DAY=$(date +"%d")
TAG_NAME="swift-wasm-DEVELOPMENT-SNAPSHOT-${YEAR}-${MONTH}-${DAY}-a"
HEAD_SHA=$(git rev-parse HEAD)

repository='swiftwasm/wasi-libc'

gh_api=https://api.github.com

github() {
  curl --header "authorization: Bearer $GITHUB_TOKEN" "$@"
}

is_released() {
  local name=$1
  local code=$(github "$gh_api/repos/$repository/releases/tags/$name" -o /dev/null -w '%{http_code}')
  test $code = 200
}

create_tag() {
  local name=$1
  local sha=$2
  local body=$(cat <<EOS
    {
      "tag": "$name",
      "message": "$name",
      "object": "$sha",
      "type": "commit"
    }
EOS
)
  github --request POST --fail \
    --url "${gh_api}/repos/${repository}/git/tags" \
    --data "$body"
}

create_release() {
  local name=$1
  local tag=$2
  local sha=$3
  local body=$(cat <<EOS
    {
      "tag_name": "$tag",
      "target_commitish": "$sha",
      "name": "$name",
      "prerelease": true
    }
EOS
)
  local response=$(github \
    --request POST --fail \
    --url "${gh_api}/repos/${repository}/releases" \
    --data "$body")
  echo $response | jq .id
}

upload_tarball() {
  local release_id=$1
  local artifact=$2
  local filename=$(basename $artifact)

  github -XPOST --fail \
    -H "Content-Length: $(stat -f%z "$artifact")" \
    -H "Content-Type: application/x-gzip" \
    --upload-file "$artifact" \
    "https://uploads.github.com/repos/$repository/releases/$release_id/assets?name=$filename"
}

if is_released $TAG_NAME; then
  echo "Latest toolchain $TAG_NAME has been already released"
  exit 0
fi

create_tag $TAG_NAME $HEAD_SHA
release_id=$(create_release $TAG_NAME $TAG_NAME $HEAD_SHA)
upload_tarball $release_id "$SYSROOT_TAR"
