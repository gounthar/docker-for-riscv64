#!/bin/bash
# docker-riscv-native-build.sh
# Complete solution for building Docker from source on RISC-V without xx tools

set -e

echo "=== Docker RISC-V Native Build Script ==="
echo "This script builds Docker from source on RISC-V using native compilation"
echo "Bypassing all cross-compilation tools (xx-*) that cause issues"
echo

# Check if we're in a moby directory
if [ ! -f "Makefile" ] || [ ! -d "hack" ]; then
    echo "Error: This script must be run from the moby/docker source directory"
    echo "Please cd to your moby directory first"
    exit 1
fi

# Check architecture
ARCH=$(uname -m)
if [ "$ARCH" != "riscv64" ]; then
    echo "Warning: This script is designed for riscv64 architecture"
    echo "Current architecture: $ARCH"
    echo "Continuing anyway..."
fi

echo "=== Step 1: Installing Build Dependencies ==="
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    pkg-config \
    libseccomp-dev \
    libdevmapper-dev \
    libbtrfs-dev \
    libsystemd-dev \
    golang-go \
    git

echo
echo "=== Step 2: Setting Up Build Environment ==="

# Set up environment variables for native RISC-V build
export DOCKER_BUILDTAGS="seccomp"
export VERSION="26.1.5"
export DOCKER_GITCOMMIT="$(git rev-parse HEAD 2>/dev/null || echo 'unknown')"
export GO111MODULE=off
export CGO_ENABLED=1
export GOOS=linux
export GOARCH=riscv64
export GOPATH="$PWD/gopath"

echo "Build configuration:"
echo "  VERSION: $VERSION"
echo "  DOCKER_BUILDTAGS: $DOCKER_BUILDTAGS"
echo "  GOARCH: $GOARCH"
echo "  GOPATH: $GOPATH"

echo
echo "=== Step 3: Preparing Go Workspace ==="

# Clean and create Go workspace
rm -rf $GOPATH
mkdir -p $GOPATH/src/github.com/docker/
ln -sf $PWD $GOPATH/src/github.com/docker/docker

echo
echo "=== Step 4: Building Docker Binary (Native Method) ==="

cd $GOPATH/src/github.com/docker/docker

# Try hack/make.sh first (most reliable for RISC-V)
echo "Attempting build with hack/make.sh..."
if ./hack/make.sh binary; then
    echo "✅ Build successful with hack/make.sh!"
    BUILD_SUCCESS=true
else
    echo "❌ hack/make.sh failed, trying dynbinary..."
    if ./hack/make.sh dynbinary; then
        echo "✅ Build successful with hack/make.sh dynbinary!"
        BUILD_SUCCESS=true
    else
        echo "❌ Both build methods failed"
        BUILD_SUCCESS=false
    fi
fi

echo
echo "=== Step 5: Verification ==="

if [ "$BUILD_SUCCESS" = true ]; then
    echo "Locating built binaries..."
    find bundles/ -name "docker*" -type f -executable 2>/dev/null | while read binary; do
        echo "Found: $binary"
        echo "  Architecture: $(file "$binary" | grep -o 'RISC-V RV64' || echo 'Unknown')"
        echo "  Size: $(du -h "$binary" | cut -f1)"
    done
    
    # Test the main dockerd binary
    DOCKERD_BINARY=$(find bundles/ -name "dockerd-*" -type f -executable | head -1)
    if [ -n "$DOCKERD_BINARY" ]; then
        echo
        echo "Testing dockerd binary..."
        if "$DOCKERD_BINARY" --version; then
            echo "✅ Docker daemon binary is working!"
        else
            echo "⚠️  Docker daemon binary found but version check failed"
        fi
    fi
    
    echo
    echo "=== Build Summary ==="
    echo "✅ Docker build completed successfully for RISC-V!"
    echo "📁 Binaries location: $(pwd)/bundles/"
    echo "🔧 You can now install these binaries or create packages"
    echo
    echo "To install the binaries:"
    echo "  sudo cp bundles/binary-daemon/dockerd-* /usr/local/bin/dockerd"
    echo "  sudo systemctl restart docker"
    
else
    echo
    echo "=== Build Failed ==="
    echo "❌ Docker build failed on RISC-V"
    echo "This may be due to:"
    echo "  - Missing dependencies"
    echo "  - Go version compatibility issues"
    echo "  - RISC-V toolchain problems"
    echo
    echo "Try the Dockerfile method instead or check the build logs above"
fi

echo
echo "=== Alternative Quick Solutions ==="
echo "If native building continues to fail, consider:"
echo "1. Using pre-built packages: sudo apt install docker.io docker-cli"
echo "2. Using Podman instead: sudo apt install podman"
echo "3. Cross-compiling on x86_64 system"

echo
echo "Script completed at $(date)"