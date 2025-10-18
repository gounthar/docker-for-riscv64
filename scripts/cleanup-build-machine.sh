#!/bin/bash
set -e

echo "=== Docker RISC-V64 Build Machine Cleanup ==="
echo ""
echo "This script will:"
echo "  1. Remove old badly-versioned packages"
echo "  2. Update APT sources"
echo "  3. Install correctly-versioned packages from the repository"
echo ""
read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

echo ""
echo "Step 1: Checking current Docker packages..."
dpkg -l | grep -E 'docker.io|containerd|runc' || echo "No Docker packages found"

echo ""
echo "Step 2: Removing old packages..."
sudo apt-get remove -y docker.io containerd runc 2>/dev/null || echo "Packages already removed or not found"

echo ""
echo "Step 3: Cleaning up old .deb files from repository..."
cd /tmp/docker-for-riscv64-local 2>/dev/null || cd ~/docker-for-riscv64 || {
    echo "Error: Cannot find docker-for-riscv64 directory"
    exit 1
}

# Switch to apt-repo branch
git fetch origin apt-repo
git checkout apt-repo

# Remove old .deb files that are not in pool/
rm -f docker.io_28.5.1-1_riscv64.deb 2>/dev/null || true
rm -f containerd_28.5.1-*.deb 2>/dev/null || true
rm -f runc_28.5.1-*.deb 2>/dev/null || true

echo "Cleaned up old .deb files"

echo ""
echo "Step 4: Updating APT cache..."
sudo apt-get update

echo ""
echo "Step 5: Installing Docker from our repository..."
sudo apt-get install -y docker.io

echo ""
echo "Step 6: Verifying installation..."
echo ""
echo "Installed versions:"
dpkg -l | grep -E 'docker.io|containerd|runc|tini' | awk '{print $2 " " $3}'

echo ""
echo "Docker version:"
docker --version

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "Next steps:"
echo "  - Switch back to main branch: git checkout main"
echo "  - Docker daemon should be running with correctly versioned packages"
echo "  - Tini is now installed for 'docker run --init' support"
