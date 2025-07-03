#!/bin/bash
set -e

echo "Quick Docker build test for RISC-V"
cd ~/docker-dev/moby

# Source environment
source ~/docker-dev/scripts/setup-env.sh

# Try simple build
echo "Testing simple Docker build..."
if docker build --platform linux/riscv64 -t test-riscv:latest .; then
    echo "Build test successful!"
else
    echo "Build test failed - this is expected initially"
fi
