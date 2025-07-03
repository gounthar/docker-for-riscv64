#!/bin/bash
# Build a local golang:1.24.4-trixie image for riscv64 builds and push to local registry.
# Usage: ./build-local-golang-trixie.sh

set -e

GO_VERSION=1.24.4
BASE_DISTRO=trixie
TAG="golang:${GO_VERSION}-${BASE_DISTRO}"
LOCAL_REGISTRY="localhost:5000"
LOCAL_TAG="$LOCAL_REGISTRY/golang:1.24.4-trixie"

# Start local registry if not running
if ! docker ps | grep -q "registry:2"; then
  if docker ps -a | grep -q "registry"; then
    echo "Removing stopped registry container..."
    docker rm registry
  fi
  echo "Starting local Docker registry on $LOCAL_REGISTRY..."
  docker run -d -p 5000:5000 --name registry registry:2
fi

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

# Tag and push to local registry for buildx cross-platform compatibility
echo "Tagging image as $LOCAL_TAG"
docker tag $TAG $LOCAL_TAG

echo "Pushing $LOCAL_TAG to local registry..."
docker push $LOCAL_TAG

echo "Image also available as $LOCAL_TAG (local registry)."
