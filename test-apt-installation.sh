#!/bin/bash
set -e

echo "=== Docker RISC-V64 APT Installation Test ==="
echo ""

# Check architecture
if [ "$(uname -m)" != "riscv64" ]; then
    echo "⚠️  Warning: Not running on riscv64 (detected: $(uname -m))"
    echo "This package is designed for RISC-V64 architecture."
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "📋 System Information:"
echo "  Architecture: $(uname -m)"
echo "  Kernel: $(uname -r)"
echo "  OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo ""

# Check if GPG key is installed
if [ ! -f /usr/share/keyrings/docker-riscv64.gpg ]; then
    echo "🔑 Importing GPG key..."
    curl -fsSL https://gounthar.github.io/docker-for-riscv64/docker-riscv64.gpg.key | \
      sudo gpg --dearmor -o /usr/share/keyrings/docker-riscv64.gpg
    echo "✅ GPG key imported"
else
    echo "✅ GPG key already installed"
fi

echo ""

# Check if repository is already configured
if [ -f /etc/apt/sources.list.d/docker-riscv64.list ]; then
    echo "✅ Repository already configured"
    cat /etc/apt/sources.list.d/docker-riscv64.list
else
    echo "📦 Adding Docker RISC-V64 repository..."
    echo "deb [arch=riscv64 signed-by=/usr/share/keyrings/docker-riscv64.gpg] https://gounthar.github.io/docker-for-riscv64 trixie main" | \
      sudo tee /etc/apt/sources.list.d/docker-riscv64.list
    echo "✅ Repository added"
fi

echo ""
echo "🔄 Updating package list..."
sudo apt-get update

echo ""
echo "📋 Checking available docker.io version..."
apt-cache policy docker.io

echo ""
echo "🔍 Checking if docker.io is already installed..."
if dpkg -l | grep -q "^ii.*docker.io"; then
    INSTALLED_VERSION=$(dpkg -l | grep docker.io | awk '{print $3}')
    echo "✅ docker.io is installed: $INSTALLED_VERSION"

    read -p "Upgrade to latest version? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "⬆️  Upgrading docker.io..."
        sudo apt-get install --only-upgrade -y docker.io
    fi
else
    echo "❌ docker.io not installed"

    read -p "Install docker.io now? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "📦 Installing docker.io..."
        sudo apt-get install -y docker.io

        echo ""
        echo "👤 Adding $USER to docker group..."
        sudo usermod -aG docker $USER

        echo ""
        echo "🔧 Enabling Docker service..."
        sudo systemctl enable docker
        sudo systemctl start docker

        echo ""
        echo "⚠️  IMPORTANT: Log out and back in for group changes to take effect!"
    fi
fi

echo ""
echo "📋 Installation verification:"
echo ""

# Check binaries
echo "🔍 Checking installed binaries:"
for binary in dockerd docker-proxy containerd runc containerd-shim-runc-v2; do
    if command -v $binary >/dev/null 2>&1; then
        echo "  ✅ $binary: $(command -v $binary)"
    else
        echo "  ❌ $binary: not found"
    fi
done

echo ""
echo "📦 Package information:"
dpkg -l | grep docker.io || echo "Package not found in dpkg"

echo ""
echo "🔧 Service status:"
sudo systemctl status docker --no-pager || echo "Service not running"

echo ""
echo "🐳 Docker version:"
docker --version 2>/dev/null || dockerd --version 2>/dev/null || echo "Docker not accessible"

echo ""
if groups | grep -q docker && systemctl is-active --quiet docker; then
    echo "🧪 Running smoke test..."

    # Try to pull alpine
    if docker pull alpine 2>/dev/null; then
        echo "✅ Successfully pulled alpine image"

        # Try to run a container
        if docker run --rm alpine echo "Docker on RISC-V64 works!" 2>/dev/null; then
            echo "✅ Container execution successful!"
        else
            echo "⚠️  Container execution failed (may need to log out/in for group changes)"
        fi
    else
        echo "⚠️  Image pull failed (may need to log out/in for group changes)"
    fi
else
    echo "ℹ️  Skipping smoke test (docker group or service not ready)"
    echo "   Log out and back in, then run: docker run alpine echo 'Test'"
fi

echo ""
echo "✅ Installation test complete!"
echo ""
echo "📖 Useful commands:"
echo "  sudo systemctl status docker  # Check service status"
echo "  docker --version              # Check Docker version"
echo "  docker info                   # Show system information"
echo "  docker ps                     # List running containers"
echo ""
