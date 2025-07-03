#!/bin/bash

# Generated build script for RISC-V Docker build

set -e

log_info() { echo -e "\033[0;34m[INFO]\033[0m $1"; }
log_error() { echo -e "\033[0;31m[ERROR]\033[0m $1"; }

# Use the RISC-V compatible Dockerfile
if [[ -f "Dockerfile.riscv" ]]; then
    log_info "Using RISC-V compatible Dockerfile"
    export DOCKERFILE=Dockerfile.riscv
else
    log_error "RISC-V Dockerfile not found. Run dockerfile fix script first."
    exit 1
fi

# Set RISC-V specific build variables
export DOCKER_BUILDKIT=1
export BUILDPLATFORM=linux/riscv64
export TARGETPLATFORM=linux/riscv64

# Try different build approaches
log_info "Attempting Docker build with buildx..."
if docker buildx bake --file docker-bake.hcl binary; then
    log_info "Build successful with buildx"
    exit 0
fi

log_info "Buildx failed, trying direct docker build..."
if docker build -f ${DOCKERFILE:-Dockerfile.riscv} -t docker-riscv:latest .; then
    log_info "Build successful with docker build"
    exit 0
fi

log_error "All build methods failed"
exit 1

