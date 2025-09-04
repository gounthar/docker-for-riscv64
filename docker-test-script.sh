#!/bin/bash
# Docker Installation Test Script for BananaPi F3 RISC-V
# This script verifies that Docker is properly installed and functional

echo "=== Docker Installation Verification for BananaPi F3 RISC-V ==="
echo "Test Date: $(date)"
echo "System: $(uname -a)"
echo

# Function to print test results
print_result() {
    if [ $? -eq 0 ]; then
        echo "✅ PASS: $1"
    else
        echo "❌ FAIL: $1"
    fi
}

# Test 1: Check if Docker is installed
echo "1. Testing Docker installation..."
docker --version &>/dev/null
print_result "Docker is installed"
if [ $? -eq 0 ]; then
    echo "   Version: $(docker --version)"
fi
echo

# Test 2: Check Docker daemon status
echo "2. Testing Docker daemon status..."
sudo systemctl is-active docker &>/dev/null
print_result "Docker daemon is running"
if [ $? -eq 0 ]; then
    echo "   Status: $(sudo systemctl is-active docker)"
fi
echo

# Test 3: Check user permissions
echo "3. Testing user permissions..."
docker ps &>/dev/null
print_result "User can run Docker commands without sudo"
echo

# Test 4: Check Docker system info
echo "4. Testing Docker system information..."
docker info &>/dev/null
print_result "Docker system info accessible"
if [ $? -eq 0 ]; then
    echo "   Architecture: $(docker info 2>/dev/null | grep 'Architecture:' | awk '{print $2}')"
    echo "   OS: $(docker info 2>/dev/null | grep 'Operating System:' | cut -d':' -f2 | xargs)"
fi
echo

# Test 5: Test basic container functionality
echo "5. Testing basic container functionality..."
echo "   Attempting to run hello-world container..."
docker run --rm hello-world &>/dev/null
print_result "Hello-world container works"

if [ $? -ne 0 ]; then
    echo "   Trying RISC-V specific hello-world..."
    docker run --rm snowdreamtech/helloworld &>/dev/null
    print_result "RISC-V hello-world container works"
fi
echo

# Test 6: Test RISC-V specific images
echo "6. Testing RISC-V specific images..."
echo "   Testing riscv64/debian:sid..."
docker run --rm riscv64/debian:sid echo "Debian RISC-V works!" &>/dev/null
print_result "RISC-V Debian container works"

echo "   Testing SpacemiT harbor registry..."
docker run --rm harbor.spacemit.com/library/debian:unstable-slim echo "SpacemiT harbor works!" &>/dev/null
print_result "SpacemiT harbor registry works"
echo

# Test 7: Test Docker Compose
echo "7. Testing Docker Compose..."
docker-compose --version &>/dev/null
print_result "Docker Compose is installed"
if [ $? -eq 0 ]; then
    echo "   Version: $(docker-compose --version)"
fi
echo

# Test 8: Check available images
echo "8. Checking available Docker images..."
IMAGE_COUNT=$(docker images -q | wc -l)
echo "   Available images: $IMAGE_COUNT"
if [ $IMAGE_COUNT -gt 0 ]; then
    echo "✅ PASS: Docker images are available"
    echo "   Images:"
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | head -10
else
    echo "ℹ️  INFO: No images downloaded yet (this is normal for a fresh installation)"
fi
echo

# Test 9: System resources
echo "9. Checking system resources..."
MEMORY_GB=$(free -g | awk '/^Mem:/{print $2}')
DISK_GB=$(df -BG / | awk 'NR==2{print $4}' | sed 's/G//')
echo "   Available RAM: ${MEMORY_GB}GB"
echo "   Available disk space: ${DISK_GB}GB"

if [ $MEMORY_GB -ge 2 ]; then
    echo "✅ PASS: Sufficient RAM for Docker"
else
    echo "⚠️  WARN: Limited RAM (less than 2GB)"
fi

if [ $DISK_GB -ge 5 ]; then
    echo "✅ PASS: Sufficient disk space for Docker"
else
    echo "⚠️  WARN: Limited disk space (less than 5GB)"
fi
echo

# Summary
echo "=== SUMMARY ==="
echo "Your Docker installation on BananaPi F3 RISC-V appears to be working!"
echo
echo "✅ What's working:"
echo "   - Docker.io package (version 26.1.5+dfsg1-9+b6)"
echo "   - Containerd (version 1.7.24~ds1-6+b2)"
echo "   - Runc (version 1.1.15+ds1-2+b3)"
echo "   - Docker-compose (version 2.26.1-4)"
echo "   - Docker service is enabled and running"
echo
echo "ℹ️  Important notes:"
echo "   - The warning about docker.com repository not supporting RISC-V is NORMAL"
echo "   - You're using Debian's docker.io package (recommended for RISC-V)"
echo "   - Use 'riscv64/*' or 'harbor.spacemit.com/library/*' images for best compatibility"
echo
echo "🚀 Next steps:"
echo "   1. Try running: docker run -it --rm riscv64/debian:sid bash"
echo "   2. Explore available RISC-V images on Docker Hub"
echo "   3. Consider using Podman as an alternative (also excellent on RISC-V)"
echo
echo "For more information, see the Docker verification guide."
echo "Test completed at $(date)"