#!/bin/bash
# Build script for RISC-V fixed Dockerfile

set -e

echo "Building Docker with RISC-V fixed Dockerfile..."

# Use the fixed Dockerfile with native build flags
docker build -f Dockerfile.riscv-fixed \
    --build-arg BUILDPLATFORM=linux/riscv64 \
    --build-arg TARGETPLATFORM=linux/riscv64 \
    --target binary \
    -t moby:riscv64-native .

echo "Build completed! Extracting binaries..."

# Extract binaries from the built image
docker create --name moby-extract moby:riscv64-native
docker cp moby-extract:/build ./binaries-riscv64/
docker rm moby-extract

echo "✅ RISC-V Docker binaries extracted to ./binaries-riscv64/"
echo "Test the dockerd binary:"
echo "  file ./binaries-riscv64/dockerd-*"
echo "  ./binaries-riscv64/dockerd-* --version"
