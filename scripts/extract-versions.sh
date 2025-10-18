#!/bin/bash
# Extract component versions from binaries

set -e

echo "Extracting versions from binaries..."

# Get runc version
if [ -f "runc" ]; then
    RUNC_VERSION=$(./runc --version | head -1 | awk '{print $3}')
    echo "runc version: $RUNC_VERSION"
    echo "RUNC_VERSION=$RUNC_VERSION" >> versions.env
fi

# Get containerd version
if [ -f "containerd" ]; then
    CONTAINERD_VERSION=$(./containerd --version | awk '{print $3}' | sed 's/v//')
    echo "containerd version: $CONTAINERD_VERSION"
    echo "CONTAINERD_VERSION=$CONTAINERD_VERSION" >> versions.env
fi

# Get dockerd version
if [ -f "dockerd" ]; then
    DOCKERD_VERSION=$(./dockerd --version | head -1 | awk '{print $3}' | sed 's/,$//')
    echo "dockerd version: $DOCKERD_VERSION"
    echo "DOCKERD_VERSION=$DOCKERD_VERSION" >> versions.env
fi

echo ""
echo "Versions saved to versions.env"
cat versions.env
