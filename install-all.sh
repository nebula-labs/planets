#!/bin/sh

## Install docker
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o build/get-docker.sh
    sh build/get-docker.sh
fi

## Install kubernetes
if ! command -v kubectl &> /dev/null; then
    PLATFORM=$(uname -m)

    # Set the architecture variable based on the platform
    if [[ "${PLATFORM}" == "x86_64" ]]; then
        ARCH="amd64"
    elif [[ "${PLATFORM}" == "aarch64" ]]; then
        ARCH="arm64"
    elif [[ "${PLATFORM}" == "arm64" ]]; then
        ARCH="arm64"
    fi

    SYSTEM=$(uname -s | tr '[:upper:]' '[:lower:]')

    KUBECTL_VERSION="$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)"
    wget "https://storage.googleapis.com/kubernetes-release/release/$KUBECTL_VERSION/bin/$SYSTEM/$ARCH/kubectl"
    chmod +x ./kubectl
    sudo mv ./kubectl /usr/local/bin/kubectl
fi

## Install kind
if ! command -v kind &> /dev/null; then
    KIND_VERSION=$(curl --silent "https://api.github.com/repos/kubernetes-sigs/kind/releases/latest" | jq -r '.tag_name')
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/$KIND_VERSION/kind-$SYSTEM-$ARCH
    chmod +x ./kind
    sudo mv ./kind /usr/local/bin/kind
fi

## Run a kind cluster
if ! docker info &> /dev/null; then
    echo "Please run docker"
    exit 1
fi

kind create cluster