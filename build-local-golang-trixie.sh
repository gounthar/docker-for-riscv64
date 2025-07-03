#!/bin/bash
# Build a local golang:1.24.4-trixie image for riscv64 builds.
# Usage: ./build-local-golang-trixie.sh

set -e

GO_VERSION=1.24.4
BASE_DISTRO=trixie
TAG="golang:${GO_VERSION}-${BASE_DISTRO}"

# Download the official Dockerfile for golang:1.24.4-bookworm
echo "Downloading official golang Dockerfile for ${GO_VERSION}-bookworm..."
curl -fsSL https://raw.githubusercontent.com/docker-library/golang/master/1.24/bookworm/Dockerfile -o Dockerfile.golang-trixie

# Replace bookworm with trixie
echo "Patching Dockerfile to use trixie as the base..."
sed -i 's/bookworm/trixie/g' Dockerfile.golang-trixie

# Build the image locally and load it into the Docker daemon
echo "Building local $TAG image for riscv64 and loading into Docker..."
if ! docker buildx build --platform linux/riscv64 --load -f Dockerfile.golang-trixie -t $TAG .; then
  echo "Error: Failed to build or load $TAG for riscv64. Ensure QEMU emulation is enabled (docker run --rm --privileged multiarch/qemu-user-static --reset -p yes)."
  exit 1
fi

echo "Local $TAG image for riscv64 built and loaded into Docker."

# Also tag as docker.io/library/golang:1.24.4-trixie for buildx compatibility
docker tag $TAG docker.io/library/golang:1.24.4-trixie || true
echo "Image also tagged as docker.io/library/golang:1.24.4-trixie"
