#!/bin/bash
# Setup build environment variables
export DOCKER_BUILDKIT=1
export BUILDPLATFORM=linux/riscv64
export TARGETPLATFORM=linux/riscv64
export GOOS=linux
export GOARCH=riscv64
export CGO_ENABLED=0

echo "Docker build environment configured for RISC-V"
echo "BUILDPLATFORM: $BUILDPLATFORM"
echo "TARGETPLATFORM: $TARGETPLATFORM"
echo "GOARCH: $GOARCH"
