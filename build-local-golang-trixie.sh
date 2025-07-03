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

# Build the image locally
echo "Building local $TAG image..."
docker buildx build --platform linux/riscv64 -f Dockerfile.golang-trixie -t $TAG .

echo "Local $TAG image built and ready for use."
