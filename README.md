# Docker Engine, CLI & Compose for RISC-V64

Native Docker Engine, CLI, and Compose binaries built for RISC-V64 architecture, enabling full containerization on RISC-V hardware.

## Overview

This project provides pre-built Docker Engine, CLI, and Compose binaries for RISC-V64 Linux systems. Built from official [Moby](https://github.com/moby/moby), [CLI](https://github.com/docker/cli), and [Compose](https://github.com/docker/compose) sources with minimal patches for RISC-V compatibility, these binaries enable running Docker containers and multi-container applications natively on RISC-V hardware.

**Key Features:**
- Native RISC-V64 compilation on BananaPi F3 (Armbian Trixie)
- Docker Engine (dockerd, containerd, runc)
- Docker CLI (docker command-line interface)
- Docker Compose v2 plugin
- Tini - tiny init for containers
- Debian APT repository for easy installation
- RPM repository for Fedora/RHEL/Rocky/AlmaLinux
- Automated `.deb` and `.rpm` package creation
- Automated weekly builds
- Based on official Moby, CLI, Compose, and Tini releases
- Built and tested on Debian Trixie / Armbian Trixie and Fedora RISC-V64
- Minimal patches for RISC-V compatibility

## Quick Start

> **Note:** The examples below use specific version numbers for illustration.
> Always check the [releases page](https://github.com/gounthar/docker-for-riscv64/releases)
> for the latest versions, or use the [Advanced Version Detection](#advanced-version-detection)
> section to automatically fetch the latest release tags.

### Repository Security

Our APT repository uses GPG signing to ensure package authenticity and integrity. To verify package signatures:

```bash
# Download and install the repository GPG key
wget -qO- https://github.com/gounthar/docker-for-riscv64/releases/download/gpg-key/docker-riscv64.gpg | \
  sudo tee /usr/share/keyrings/docker-riscv64.gpg > /dev/null

# Add signed repository
echo "deb [arch=riscv64 signed-by=/usr/share/keyrings/docker-riscv64.gpg] https://gounthar.github.io/docker-for-riscv64 trixie main" | \
  sudo tee /etc/apt/sources.list.d/docker-riscv64.list
```

**GPG Key Information:**
- Key ID: `56188341425B007407229B48FB1963FC3575A39D`
- Key Name: Docker RISC-V64 Repository
- Fingerprint: `5618 8341 425B 0074 0722  9B48 FB19 63FC 3575 A39D`

### Installation

Choose your Linux distribution:

#### Debian / Ubuntu / Armbian

##### Option 1: APT Repository (Recommended)

Install from our signed Debian APT repository:

```bash
# Add GPG key
wget -qO- https://github.com/gounthar/docker-for-riscv64/releases/download/gpg-key/docker-riscv64.gpg | \
  sudo tee /usr/share/keyrings/docker-riscv64.gpg > /dev/null

# Add signed repository
echo "deb [arch=riscv64 signed-by=/usr/share/keyrings/docker-riscv64.gpg] https://gounthar.github.io/docker-for-riscv64 trixie main" | \
  sudo tee /etc/apt/sources.list.d/docker-riscv64.list

# Update and install
sudo apt-get update
sudo apt-get install docker.io

# Add your user to docker group
sudo usermod -aG docker $USER

# Enable and start service
sudo systemctl enable --now docker
```

**Note**: Log out and back in for group changes to take effect.

##### Option 2: Direct .deb Package

Download and install the `.deb` package:

```bash
# Get latest release
VERSION="v28.5.1-riscv64"

# Download package
wget "https://github.com/gounthar/docker-for-riscv64/releases/download/${VERSION}/docker.io_${VERSION#v}_riscv64.deb"

# Install
sudo dpkg -i docker.io_*.deb
sudo apt-get install -f  # Fix any dependencies
```

#### Fedora / RHEL / Rocky Linux / AlmaLinux

##### Option 1: DNF Repository (Recommended)

Install from our signed RPM repository:

```bash
# Add the repository
sudo curl -L https://gounthar.github.io/docker-for-riscv64/rpm/docker-riscv64.repo \
  -o /etc/yum.repos.d/docker-riscv64.repo

# Install Docker Engine
sudo dnf install -y moby-engine docker-cli

# Add your user to docker group
sudo usermod -aG docker $USER

# Enable and start service
sudo systemctl enable --now docker
```

**Note**: Log out and back in for group changes to take effect.

##### Option 2: Direct .rpm Package

Download and install the `.rpm` packages:

```bash
# Get latest release
VERSION="v28.5.1-riscv64"

# Download packages
wget "https://github.com/gounthar/docker-for-riscv64/releases/download/${VERSION}/runc-1.3.0-1.fc*.riscv64.rpm"
wget "https://github.com/gounthar/docker-for-riscv64/releases/download/${VERSION}/containerd-1.7.28-1.fc*.riscv64.rpm"
wget "https://github.com/gounthar/docker-for-riscv64/releases/download/${VERSION}/moby-engine-${VERSION#v}-1.fc*.riscv64.rpm"

# Install all packages (dnf will resolve dependencies)
sudo dnf install -y ./*.riscv64.rpm
```

#### Gentoo Linux

##### Option 1: Portage Overlay (Recommended)

Install from our Gentoo overlay using emerge:

```bash
# Add the overlay
eselect repository add docker-riscv64 git https://github.com/gounthar/docker-for-riscv64.git

# Sync the overlay
emerge --sync docker-riscv64

# Install Docker
emerge -av app-containers/docker

# For systemd users
systemctl enable docker
systemctl start docker

# For OpenRC users
rc-update add docker default
rc-service docker start

# Add your user to docker group
usermod -aG docker $USER
```

**Note**: Log out and back in for group changes to take effect.

**Features:**
- Pre-built binaries (no 1-2 hour compilation!)
- Latest Docker versions for RISC-V64
- Full Portage integration
- Choice of systemd or OpenRC

**Why no .deb/.rpm for Gentoo?** Gentoo uses overlays with ebuilds (not standalone binary packages). Our ebuilds download pre-built binaries from GitHub releases and install them in the Gentoo-native way. See [GENTOO-FAQ.md](GENTOO-FAQ.md) for a detailed explanation.

See `gentoo-overlay/README.md` for detailed Gentoo installation instructions.

#### Manual Binary Installation (Any Distribution)

Download the latest release binaries:

```bash
# Get latest version from https://github.com/gounthar/docker-for-riscv64/releases
VERSION="v28.5.1-riscv64"

# Download binaries
for binary in dockerd docker-proxy containerd runc containerd-shim-runc-v2; do
  wget "https://github.com/gounthar/docker-for-riscv64/releases/download/${VERSION}/${binary}"
done

# Make executable
chmod +x dockerd docker-proxy containerd runc containerd-shim-runc-v2

# Install (requires root)
sudo install -m 755 dockerd docker-proxy containerd runc containerd-shim-runc-v2 /usr/local/bin/
```

See [INSTALL.md](INSTALL.md) for detailed installation instructions.

### Running Docker

```bash
# Start dockerd (requires root)
sudo dockerd &

# Verify installation
docker version
docker info
```

### Docker CLI Installation

The Docker CLI (command-line interface) is available as a separate package:

#### Option 1: APT Repository (Recommended)

```bash
# Add GPG key and repository (if not already added)
wget -qO- https://github.com/gounthar/docker-for-riscv64/releases/download/gpg-key/docker-riscv64.gpg | \
  sudo tee /usr/share/keyrings/docker-riscv64.gpg > /dev/null

echo "deb [arch=riscv64 signed-by=/usr/share/keyrings/docker-riscv64.gpg] https://gounthar.github.io/docker-for-riscv64 trixie main" | \
  sudo tee /etc/apt/sources.list.d/docker-riscv64.list

# Install CLI
sudo apt-get update
sudo apt-get install docker-cli

# Verify
docker --version
```

#### Option 2: Direct .deb Package

```bash
# Get latest CLI release
CLI_VERSION="cli-v28.5.1-riscv64"

# Download package
wget "https://github.com/gounthar/docker-for-riscv64/releases/download/${CLI_VERSION}/docker-cli_*.deb"

# Install
sudo dpkg -i docker-cli_*.deb
sudo apt-get install -f  # Fix any dependencies
```

#### Option 3: Manual Binary Installation

```bash
# Download binary
CLI_VERSION="cli-v28.5.1-riscv64"
wget "https://github.com/gounthar/docker-for-riscv64/releases/download/${CLI_VERSION}/docker"

# Install to system
chmod +x docker
sudo mv docker /usr/bin/

# Verify
docker --version
```

### Docker Compose Installation

Docker Compose v2 is available as a separate plugin package:

#### Option 1: APT Repository (Recommended)

```bash
# Add GPG key and repository (if not already added)
wget -qO- https://github.com/gounthar/docker-for-riscv64/releases/download/gpg-key/docker-riscv64.gpg | \
  sudo tee /usr/share/keyrings/docker-riscv64.gpg > /dev/null

echo "deb [arch=riscv64 signed-by=/usr/share/keyrings/docker-riscv64.gpg] https://gounthar.github.io/docker-for-riscv64 trixie main" | \
  sudo tee /etc/apt/sources.list.d/docker-riscv64.list

# Install compose plugin
sudo apt-get update
sudo apt-get install docker-compose-plugin

# Verify
docker compose version
```

#### Option 2: Direct .deb Package

```bash
# Get latest compose release
COMPOSE_VERSION="compose-v2.40.1-riscv64"

# Download package
wget "https://github.com/gounthar/docker-for-riscv64/releases/download/${COMPOSE_VERSION}/docker-compose-plugin_*.deb"

# Install
sudo dpkg -i docker-compose-plugin_*.deb
sudo apt-get install -f  # Fix any dependencies
```

#### Option 3: Manual Binary Installation

```bash
# Download binary
COMPOSE_VERSION="compose-v2.40.1-riscv64"
wget "https://github.com/gounthar/docker-for-riscv64/releases/download/${COMPOSE_VERSION}/docker-compose"

# Install as Docker CLI plugin
sudo mkdir -p /usr/libexec/docker/cli-plugins
sudo mv docker-compose /usr/libexec/docker/cli-plugins/
sudo chmod +x /usr/libexec/docker/cli-plugins/docker-compose

# Verify
docker compose version
```

**Backward Compatibility:**

The package automatically creates a symlink at `/usr/bin/docker-compose` for backward compatibility with v1 commands:

```bash
# Both work
docker compose version
docker-compose version
```

### Using Docker Compose

```bash
# Create a sample compose.yml
cat > compose.yml << 'EOF'
services:
  web:
    image: nginx:alpine
    ports:
      - "8080:80"
EOF

# Start services
docker compose up -d

# Check status
docker compose ps

# View logs
docker compose logs

# Stop and remove
docker compose down
```

## Advanced Version Detection

For automation or to always use the latest versions, you can dynamically detect the latest release tags using the GitHub CLI or API:

### Using GitHub CLI (gh)

```bash
# Check for required dependencies
command -v gh &> /dev/null || {
  echo "Error: gh not found. Install from https://cli.github.com"
  exit 1
}

# Automatically fetch latest versions
LATEST_ENGINE=$(gh release list --repo gounthar/docker-for-riscv64 --limit 20 | \
  grep -E '^\s*v[0-9]+\.[0-9]+\.[0-9]+-riscv64' | \
  grep -v 'cli-v' | grep -v 'compose-v' | \
  head -1 | awk '{print $1}')

LATEST_CLI=$(gh release list --repo gounthar/docker-for-riscv64 --limit 20 | \
  grep -E '^\s*cli-v[0-9]+\.[0-9]+\.[0-9]+-riscv64' | \
  head -1 | awk '{print $1}')

LATEST_COMPOSE=$(gh release list --repo gounthar/docker-for-riscv64 --limit 20 | \
  grep -E '^\s*compose-v[0-9]+\.[0-9]+\.[0-9]+-riscv64' | \
  head -1 | awk '{print $1}')

# Validate all versions were detected
[[ -z "$LATEST_ENGINE" ]] && { echo "Error: No Engine releases found"; exit 1; }
[[ -z "$LATEST_CLI" ]] && { echo "Error: No CLI releases found"; exit 1; }
[[ -z "$LATEST_COMPOSE" ]] && { echo "Error: No Compose releases found"; exit 1; }

# Display detected versions
echo "Latest Engine: $LATEST_ENGINE"
echo "Latest CLI: $LATEST_CLI"
echo "Latest Compose: $LATEST_COMPOSE"

# Example: Download Docker Engine binaries
for binary in dockerd docker-proxy containerd runc containerd-shim-runc-v2; do
  wget "https://github.com/gounthar/docker-for-riscv64/releases/download/${LATEST_ENGINE}/${binary}"
done
```

### Using GitHub API (curl)

```bash
# Check for required dependencies
for cmd in curl jq; do
  command -v $cmd &> /dev/null || {
    echo "Error: $cmd not found"
    exit 1
  }
done

# Fetch latest Engine release (no authentication required)
LATEST_ENGINE=$(curl -s https://api.github.com/repos/gounthar/docker-for-riscv64/releases | \
  jq -r '[.[] | select(.tag_name | test("^v[0-9]+\\.[0-9]+\\.[0-9]+-riscv64$"))] |
  .[0].tag_name')

# Fetch latest CLI release
LATEST_CLI=$(curl -s https://api.github.com/repos/gounthar/docker-for-riscv64/releases | \
  jq -r '[.[] | select(.tag_name | test("^cli-v[0-9]+\\.[0-9]+\\.[0-9]+-riscv64$"))] |
  .[0].tag_name')

# Fetch latest Compose release
LATEST_COMPOSE=$(curl -s https://api.github.com/repos/gounthar/docker-for-riscv64/releases | \
  jq -r '[.[] | select(.tag_name | test("^compose-v[0-9]+\\.[0-9]+\\.[0-9]+-riscv64$"))] |
  .[0].tag_name')

# Validate all versions were detected
[[ -z "$LATEST_ENGINE" ]] && { echo "Error: No Engine releases found"; exit 1; }
[[ -z "$LATEST_CLI" ]] && { echo "Error: No CLI releases found"; exit 1; }
[[ -z "$LATEST_COMPOSE" ]] && { echo "Error: No Compose releases found"; exit 1; }

echo "Latest Engine: $LATEST_ENGINE"
echo "Latest CLI: $LATEST_CLI"
echo "Latest Compose: $LATEST_COMPOSE"
```

### Automated Installation Script

Here's a complete script that detects and installs the latest versions:

> **Note:** This script installs Docker Engine and CLI only. To also install Docker Compose,
> see [COMPOSE-TESTING.md Dynamic Version Detection](COMPOSE-TESTING.md#dynamic-version-detection) section.

```bash
#!/bin/bash
set -e

# Check for required dependencies
command -v gh &> /dev/null || {
  echo "Error: gh not found. Install from https://cli.github.com"
  exit 1
}

command -v wget &> /dev/null || {
  echo "Error: wget not found. Install with: sudo apt-get install wget"
  exit 1
}

# Detect latest releases
echo "Detecting latest versions..."
LATEST_ENGINE=$(gh release list --repo gounthar/docker-for-riscv64 --limit 20 | \
  grep -E '^\s*v[0-9]+\.[0-9]+\.[0-9]+-riscv64' | \
  grep -v 'cli-v' | grep -v 'compose-v' | \
  head -1 | awk '{print $1}')

LATEST_CLI=$(gh release list --repo gounthar/docker-for-riscv64 --limit 20 | \
  grep -E '^\s*cli-v[0-9]+\.[0-9]+\.[0-9]+-riscv64' | \
  head -1 | awk '{print $1}')

# Validate versions were detected
[[ -z "$LATEST_ENGINE" ]] && { echo "Error: No Engine releases found"; exit 1; }
[[ -z "$LATEST_CLI" ]] && { echo "Error: No CLI releases found"; exit 1; }

echo "Latest Engine: $LATEST_ENGINE"
echo "Latest CLI: $LATEST_CLI"

# Download and install Engine
echo "Downloading Docker Engine..."
for binary in dockerd docker-proxy containerd runc containerd-shim-runc-v2; do
  wget -q "https://github.com/gounthar/docker-for-riscv64/releases/download/${LATEST_ENGINE}/${binary}"
  chmod +x "$binary"
done

echo "Installing Docker Engine..."
sudo install -m 755 dockerd docker-proxy containerd runc containerd-shim-runc-v2 /usr/local/bin/

# Download and install CLI
echo "Downloading Docker CLI..."
wget -q "https://github.com/gounthar/docker-for-riscv64/releases/download/${LATEST_CLI}/docker"
chmod +x docker
sudo mv docker /usr/bin/

echo "Installation complete!"
docker --version
```

## Architecture Support

**Supported:**
- ✅ RISC-V64 (riscv64)

**Tested Hardware:**
- BananaPi F3 (running Armbian Trixie)
- Other RISC-V64 SBCs (community tested)

**Operating Systems:**
- Debian Trixie (primary)
- Armbian Trixie (tested on BananaPi F3)
- Other RISC-V Linux distributions (may work)

## Releases

### Release Naming

- **Docker Engine releases**: `vX.Y.Z-riscv64` (e.g., `v27.5.1-riscv64`)
- **Docker CLI releases**: `cli-vX.Y.Z-riscv64` (e.g., `cli-v28.5.1-riscv64`)
- **Docker Compose releases**: `compose-vX.Y.Z-riscv64` (e.g., `compose-v2.40.1-riscv64`)
- **Tini releases**: `tini-vX.Y.Z-riscv64` (e.g., `tini-v0.19.0-riscv64`)
- **Development builds**: `vYYYYMMDD-dev`, `cli-vYYYYMMDD-dev`, `compose-vYYYYMMDD-dev`, or `tini-vYYYYMMDD-dev`

### Automated Builds

**Docker Engine:**
- Weekly builds: Every Sunday at 02:00 UTC (latest Moby master)
- Release tracking: Daily check for new official Moby releases
- Automatic builds: New official releases trigger automatic RISC-V builds

**Docker CLI:**
- Weekly builds: Every Sunday at 04:00 UTC (latest CLI master)
- Release tracking: Daily check for new official CLI releases
- Manual trigger support for specific versions

**Docker Compose:**
- Weekly builds: Every Sunday at 03:00 UTC (latest Compose main)
- Manual trigger support for specific versions

**Tini:**
- Weekly builds: Every Sunday at 05:00 UTC (latest Tini master)
- Manual trigger support for specific versions

### Components

**Docker Engine releases** include:
- **docker.io_*.deb** (~140MB) - Complete Debian package
- **dockerd** (73MB) - Docker Engine daemon
- **docker-proxy** (2.4MB) - Docker network proxy
- **containerd** (37MB) - Container runtime
- **runc** (15MB) - OCI runtime
- **containerd-shim-runc-v2** (13MB) - Containerd shim
- **VERSIONS.txt** - Component version information

**Docker CLI releases** include:
- **docker-cli_*.deb** (~45MB) - Debian package
- **docker** (~43MB) - Docker CLI binary
- Installed to: `/usr/bin/docker`

**Docker Compose releases** include:
- **docker-compose-plugin_*.deb** (~12MB) - Debian package
- **docker-compose** (~10MB) - Compose v2 binary
- Installed to: `/usr/libexec/docker/cli-plugins/`
- Symlink: `/usr/bin/docker-compose` (backward compat)

**Tini releases** include:
- **tini-*.rpm** (~50KB) - RPM package for main binary
- **tini-static-*.rpm** (~2MB) - RPM package for static binary
- **tini** (~30KB) - Dynamic init binary
- **tini-static** (~2MB) - Static init binary
- Installed to: `/usr/bin/tini` and `/usr/bin/tini-static`
- Used by Docker with `--init` flag for proper signal handling

## Building from Source

### Prerequisites

- RISC-V64 hardware or emulator
- Debian Trixie (or compatible)
- Docker installed (for building)
- Go 1.25.3+
- Git with submodules

### Build Steps

```bash
# Clone repository with submodules
git clone --recurse-submodules https://github.com/gounthar/docker-for-riscv64.git
cd docker-for-riscv64

# Update moby submodule to desired version
cd moby
git fetch origin
git checkout v27.5.1  # or 'master' for latest
cd ..

# Build Docker binaries (takes ~35-40 minutes on BananaPi F3)
docker build \
  --build-arg BASE_DEBIAN_DISTRO=trixie \
  --build-arg GO_VERSION=1.25.3 \
  --target=binary \
  -f moby/Dockerfile \
  .

# Extract binaries from the build
docker run --rm -v $(pwd):/out <image-id> \
  sh -c 'cp /usr/local/bin/dockerd /usr/local/bin/docker-proxy /out/'
```

See build logs and details in the repository's GitHub Actions workflows.

## Documentation

- **[INSTALL.md](INSTALL.md)** - Detailed installation guide
- **[CLI-TESTING.md](CLI-TESTING.md)** - Docker CLI testing and validation guide
- **[COMPOSE-TESTING.md](COMPOSE-TESTING.md)** - Docker Compose testing and validation guide
- **[RUNNER-SETUP.md](RUNNER-SETUP.md)** - CI/CD runner setup for automated builds
- **[GitHub Actions Workflows](.github/workflows/)** - Automated build configurations

## Known Limitations

- **Development builds**: Current builds are marked as `version dev`
- **Frozen images**: Disabled (no RISC-V64 manifests for busybox/hello-world)
- **Legacy CLI tests**: Disabled (old v18.06.3-ce integration tests)
- **Hardware testing**: Limited to specific RISC-V64 hardware

## Project Status

- ✅ **First release**: v1.0.0 (October 2025)
- ✅ **Automated builds**: Active (weekly + release tracking)
- ✅ **CI/CD**: Self-hosted RISC-V64 runner operational
- ✅ **Debian packaging**: Complete with APT repository
- ✅ **APT repository**: https://gounthar.github.io/docker-for-riscv64
- ✅ **Docker CLI support**: Native RISC-V64 CLI builds available
- 🚧 **Extended testing**: Community feedback welcome

## Contributing

Contributions are welcome! Areas where help is needed:

- Testing on different RISC-V64 hardware
- RPM package creation (Fedora/SUSE)
- Documentation improvements
- Bug reports and fixes
- Testing APT repository on various Debian-based RISC-V64 systems

**Before contributing:**
1. Check existing issues and pull requests
2. Create an issue for major changes
3. Follow conventional commit format
4. Test on RISC-V64 hardware when possible

## Credits

**Built with:**
- [Moby Project](https://github.com/moby/moby) - Docker Engine upstream
- [github-act-runner](https://github.com/ChristopherHX/github-act-runner) - Go-based GitHub Actions runner
- BananaPi F3 - RISC-V64 build hardware
- Debian Trixie - Base distribution

**Community:**
- Thanks to all testers and contributors
- RISC-V community for architecture support

## Support

- **Issues**: [GitHub Issues](https://github.com/gounthar/docker-for-riscv64/issues)
- **Releases**: [GitHub Releases](https://github.com/gounthar/docker-for-riscv64/releases)
- **Upstream**: [Moby Project](https://github.com/moby/moby)

## License

This project follows the licensing of its upstream components:
- Docker/Moby components: Apache License 2.0
- Build scripts and documentation: See repository license

---

**Note**: This is an unofficial build of Docker Engine for RISC-V64. For production use, always verify binaries and test thoroughly on your target hardware.
