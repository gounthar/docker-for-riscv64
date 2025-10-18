#!/bin/bash
set -e

echo "=== Docker RISC-V64 Installation ==="
echo ""

# Check architecture
if [ "$(uname -m)" != "riscv64" ]; then
    echo "❌ Error: This package is only for RISC-V64 architecture"
    echo "   Current architecture: $(uname -m)"
    exit 1
fi

# Check Debian/Ubuntu
if [ ! -f /etc/debian_version ]; then
    echo "⚠️  Warning: This script is designed for Debian/Ubuntu"
    echo "   Your system: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Option 1: Install from GitHub release (direct .deb download)
echo "Installation method:"
echo "  1) Direct .deb download from GitHub (recommended for testing)"
echo "  2) Add APT repository (recommended for production, requires repository setup)"
echo ""
read -p "Choose method (1 or 2): " METHOD

if [ "$METHOD" = "1" ]; then
    echo ""
    echo "=== Direct .deb Installation ==="

    # Get latest release
    echo "Fetching latest release information..."
    LATEST_RELEASE=$(curl -s https://api.github.com/repos/gounthar/docker-for-riscv64/releases | \
                     grep -o '"tag_name": "v[^"]*-riscv64"' | \
                     head -1 | \
                     cut -d'"' -f4)

    if [ -z "$LATEST_RELEASE" ]; then
        echo "❌ Could not fetch latest release"
        echo "Please visit: https://github.com/gounthar/docker-for-riscv64/releases"
        exit 1
    fi

    echo "Latest release: $LATEST_RELEASE"

    # Download .deb
    DEB_URL="https://github.com/gounthar/docker-for-riscv64/releases/download/${LATEST_RELEASE}/docker.io_${LATEST_RELEASE#v}-riscv64_*.deb"
    DEB_FILE="docker.io_${LATEST_RELEASE#v}.deb"

    echo "Downloading $DEB_FILE..."
    wget -O "$DEB_FILE" "$DEB_URL" || {
        echo "❌ Download failed"
        echo "Manual download: https://github.com/gounthar/docker-for-riscv64/releases"
        exit 1
    }

    # Install
    echo "Installing docker.io..."
    sudo dpkg -i "$DEB_FILE" || {
        echo "Fixing dependencies..."
        sudo apt-get install -f -y
    }

    echo "Cleaning up..."
    rm "$DEB_FILE"

elif [ "$METHOD" = "2" ]; then
    echo ""
    echo "=== APT Repository Installation ==="

    # Check if repository is set up
    if [ ! -f /etc/apt/sources.list.d/docker-riscv64.list ]; then
        echo "Adding Docker RISC-V64 repository..."

        # Add GPG key (if signed)
        echo "Adding repository GPG key..."
        wget -qO - https://gounthar.github.io/docker-for-riscv64/KEY.gpg | sudo apt-key add - 2>/dev/null || true

        # Add repository
        echo "deb [arch=riscv64] https://gounthar.github.io/docker-for-riscv64 trixie main" | \
          sudo tee /etc/apt/sources.list.d/docker-riscv64.list
    else
        echo "Repository already configured"
    fi

    # Update and install
    echo "Updating package list..."
    sudo apt-get update

    echo "Installing docker.io..."
    sudo apt-get install -y docker.io

else
    echo "❌ Invalid choice"
    exit 1
fi

# Post-installation
echo ""
echo "=== Post-installation Setup ==="

# Add user to docker group
if [ -n "$SUDO_USER" ]; then
    USER_TO_ADD="$SUDO_USER"
else
    USER_TO_ADD="$USER"
fi

echo "Adding $USER_TO_ADD to docker group..."
sudo usermod -aG docker "$USER_TO_ADD"

# Enable and start service
echo "Enabling Docker service..."
sudo systemctl enable docker
sudo systemctl start docker || {
    echo "⚠️  Failed to start Docker service"
    echo "   Check logs with: sudo journalctl -u docker"
}

# Verify installation
echo ""
echo "=== Verification ==="
docker --version 2>/dev/null || dockerd --version

echo ""
echo "✅ Docker installed successfully!"
echo ""
echo "⚠️  IMPORTANT: Log out and back in for group changes to take effect"
echo ""
echo "Then test with:"
echo "  docker run hello-world"
echo ""
echo "Or check status:"
echo "  systemctl status docker"
echo "  docker info"
echo ""
