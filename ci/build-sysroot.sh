#!/bin/bash
set -eu

ROOT_DIR="$(cd "$(dirname $0)/../" && pwd)"
BUILD_DIR="$ROOT_DIR/build"
SYSROOT_TAR="$BUILD_DIR/wasi-sysroot.tar.gz"

if [[ -z "$WASM_CC" ]]; then
  echo "Need to set WASM_CC"
  exit 1
fi

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

make -C $ROOT_DIR \
  WASM_CC="$WASM_CC" \
  SYSROOT="$BUILD_DIR/wasi-sysroot"

tar czf "$SYSROOT_TAR" -C "$BUILD_DIR" wasi-sysroot
