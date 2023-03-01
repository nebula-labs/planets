#!/bin/bash

VERSION=$1

# check if VERSION is set
if [ -z "$VERSION" ]; then
    VERSION=0.12.11
fi

# build cargo
cargo build
if [[ "${PIPESTATUS[0]}" != "0" ]]; then
    echo "build failed"
    exit 1
fi

# detect architecture and decide image
arch=$(uname -m)
rust_optimizer_image="cosmwasm/rust-optimizer:$VERSION"
if [ $arch == "arm64" ]; then
  # newer version of cosmwasm/rust-optimizer-arm64 is not yet on docker hub, manual build is required
  rust_optimizer_image="cosmwasm/rust-optimizer-arm64:$VERSION"

  if ! docker image inspect $rust_optimizer_image &>/dev/null; then
    mkdir build
    wget -c https://github.com/CosmWasm/rust-optimizer/archive/refs/tags/v$VERSION.zip -O build/v$VERSION.zip
    unzip build/v$VERSION.zip -d build
    cd build/rust-optimizer-$VERSION
    make build-rust-optimizer-arm64
    cd ../..
  fi
fi

# compile contract
docker run --rm -v "$(pwd)":/code \
  --mount type=volume,source="$(basename "$(pwd)")_cache",target=/code/target \
  --mount type=volume,source=registry_cache,target=/usr/local/cargo/registry \
  $rust_optimizer_image