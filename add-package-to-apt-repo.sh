#!/bin/bash
set -e

echo "=== Adding docker.io package to APT repository ==="
echo ""

# Check we're in the right place
if [ ! -f "conf/distributions" ]; then
    echo "❌ Error: Not in apt-repo branch directory"
    echo "Please run: cd /tmp/docker-for-riscv64-local && git checkout apt-repo"
    exit 1
fi

# Check reprepro is installed
if ! which reprepro > /dev/null 2>&1; then
    echo "📦 Installing reprepro..."
    sudo apt-get update
    sudo apt-get install -y reprepro
    echo "✅ reprepro installed"
fi

# Check .deb file exists
if [ ! -f "docker.io_28.5.1-1_riscv64.deb" ]; then
    echo "📥 Downloading .deb package..."
    gh release download v28.5.1-riscv64 -p "docker.io_*.deb" --repo gounthar/docker-for-riscv64
fi

echo ""
echo "📦 Package info:"
ls -lh docker.io_28.5.1-1_riscv64.deb
dpkg-deb --info docker.io_28.5.1-1_riscv64.deb | head -20

echo ""
echo "🔧 Adding package to repository..."
reprepro -b . includedeb trixie docker.io_28.5.1-1_riscv64.deb

echo ""
echo "📋 Repository contents:"
reprepro -b . list trixie

echo ""
echo "💾 Committing changes..."
git config user.name "Bruno Verachten" || true
git config user.email "gounthar@gmail.com" || true

git add dists pool
git status

git commit -m "Add docker.io 28.5.1-1 to APT repository

Automated package addition for v28.5.1-riscv64 release.

Package: docker.io_28.5.1-1_riscv64.deb (30MB)
Components: dockerd, docker-proxy, containerd, runc, shim
Release: https://github.com/gounthar/docker-for-riscv64/releases/tag/v28.5.1-riscv64
Built: 2025-10-18
Architecture: riscv64

Users can now install with:
  echo \"deb [arch=riscv64] https://gounthar.github.io/docker-for-riscv64 trixie main\" | \\
    sudo tee /etc/apt/sources.list.d/docker-riscv64.list
  sudo apt-get update
  sudo apt-get install docker.io"

echo ""
echo "📤 Pushing to GitHub..."
git push origin apt-repo

echo ""
echo "✅ SUCCESS! APT repository updated!"
echo ""
echo "🌐 Repository URL: https://gounthar.github.io/docker-for-riscv64"
echo ""
echo "Users can now install Docker with:"
echo "  sudo apt-get update"
echo "  sudo apt-get install docker.io"
echo ""
