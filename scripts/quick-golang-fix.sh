#!/bin/bash
# Quick Fix for golang:1.24.4-bookworm RISC-V Build Issue
# This script creates a local golang image to solve the "no match for platform" error

set -e

print_info() { echo -e "\033[0;34m[INFO]\033[0m $1"; }
print_success() { echo -e "\033[0;32m[SUCCESS]\033[0m $1"; }
print_error() { echo -e "\033[0;31m[ERROR]\033[0m $1"; }

print_info "Building golang:1.24.4-bookworm for RISC-V locally..."

# Create temporary directory for building
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Create Dockerfile for golang:1.24.4-bookworm
cat > Dockerfile << 'EOF'
FROM riscv64/debian:sid

# Install essential build tools
RUN apt-get update && apt-get install -y \
    wget \
    tar \
    gcc \
    libc6-dev \
    ca-certificates \
    git \
    make \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Download official Go 1.24.4 for RISC-V from go.dev
ENV GO_VERSION=1.24.4
RUN wget -O go.tar.gz "https://go.dev/dl/go${GO_VERSION}.linux-riscv64.tar.gz" \
    && tar -C /usr/local -xzf go.tar.gz \
    && rm go.tar.gz

# Set up Go environment exactly like official golang image
ENV GOPATH=/go
ENV PATH=$GOPATH/bin:/usr/local/go/bin:$PATH

# Create Go workspace
RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 755 "$GOPATH"

# Set working directory
WORKDIR $GOPATH

# Default command
CMD ["go", "version"]
EOF

print_info "Building local golang:1.24.4-bookworm image..."

# Build the image with the exact tag Docker expects
if docker build -t golang:1.24.4-bookworm .; then
    print_success "Successfully built golang:1.24.4-bookworm for RISC-V!"
    
    # Test the image
    print_info "Testing the built image..."
    if docker run --rm golang:1.24.4-bookworm go version; then
        print_success "Image test passed! Go is working correctly."
    else
        print_error "Image test failed!"
        exit 1
    fi
    
    print_success "Local golang image is ready. Your Docker build should now work!"
    print_info "Now run: make binary"
    
else
    print_error "Failed to build golang image"
    exit 1
fi

# Cleanup
cd /
rm -rf "$TEMP_DIR"

print_info "Cleanup completed. You can now proceed with your Docker build."