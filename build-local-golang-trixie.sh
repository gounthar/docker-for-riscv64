#!/bin/bash
# Build a local golang:1.24.4-trixie image for riscv64 builds and push to local registry.
# Usage: ./build-local-golang-trixie.sh

set -e

GO_VERSION=1.25.1
BASE_DISTRO=trixie
TAG="golang:${GO_VERSION}-${BASE_DISTRO}"
LOCAL_REGISTRY="localhost:5000"
LOCAL_TAG="$LOCAL_REGISTRY/golang:1.24.4-trixie"

# Native riscv64 build: no local registry needed

# Download the official Dockerfile for golang:1.24.4-bookworm
echo "Downloading official golang Dockerfile for ${GO_VERSION}-bookworm..."
curl -fsSL https://raw.githubusercontent.com/docker-library/golang/master/1.24/bookworm/Dockerfile -o Dockerfile.golang-trixie

# Replace bookworm with trixie
echo "Patching Dockerfile to use trixie as the base..."
sed -i 's/bookworm/trixie/g' Dockerfile.golang-trixie

# Build the image locally and load it into the Docker daemon
echo "Building local $TAG image for riscv64 and loading into Docker..."
if ! docker build -f Dockerfile.golang-trixie -t $TAG .; then
  echo "Error: Failed to build or load $TAG for riscv64."
  exit 1
fi

echo "Local $TAG image for riscv64 built and loaded into Docker."
