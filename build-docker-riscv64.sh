#!/bin/bash
# build-docker-riscv64.sh
# Build Docker Engine for riscv64 using trixie as the base.
# Usage: ./build-docker-riscv64.sh

set -e

show_usage() {
  echo "Usage: $0"
  echo "Build Docker Engine for riscv64 using trixie as the base."
}

if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  show_usage
  exit 0
fi

echo "Building Docker Engine for riscv64 using trixie as the base..."

# Ensure the local golang:1.24.4-trixie image exists
./build-local-golang-trixie.sh

cd moby

# Build for riscv64 using the patched Dockerfile (update the filename as needed)
docker build -f Dockerfile.trixie-riscv64 -t docker-riscv64:dev .

echo "Build complete. Image tagged as docker-riscv64:dev"
