# Docker Engine & Compose for RISC-V64

Native Docker Engine and Docker Compose binaries built for RISC-V64 architecture, enabling containerization on RISC-V hardware.

## Overview

This project provides pre-built Docker Engine and Docker Compose binaries for RISC-V64 Linux systems. Built from official [Moby](https://github.com/moby/moby) and [Compose](https://github.com/docker/compose) sources with minimal patches for RISC-V compatibility, these binaries enable running Docker containers and multi-container applications natively on RISC-V hardware.

**Key Features:**
- Native RISC-V64 compilation on BananaPi F3 (Armbian Trixie)
- Docker Engine (dockerd, containerd, runc)
- Docker Compose v2 plugin
- Debian APT repository for easy installation
- Automated `.deb` package creation
- Automated weekly builds
- Based on official Moby and Compose releases
- Built and tested on Debian Trixie / Armbian Trixie
- Minimal patches for RISC-V compatibility

## Quick Start

### Installation

#### Option 1: APT Repository (Recommended)

Install from our Debian APT repository:

```bash
# Add repository
echo "deb [arch=riscv64] https://gounthar.github.io/docker-for-riscv64 trixie main" | \
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

#### Option 2: Direct .deb Package

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

#### Option 3: Manual Binary Installation

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

### Docker Compose Installation

Docker Compose v2 is available as a separate plugin package:

#### Option 1: APT Repository (Recommended)

```bash
# Add repository (if not already added)
echo "deb [arch=riscv64] https://gounthar.github.io/docker-for-riscv64 trixie main" | \
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
- **Docker Compose releases**: `compose-vX.Y.Z-riscv64` (e.g., `compose-v2.40.1-riscv64`)
- **Development builds**: `vYYYYMMDD-dev` or `compose-vYYYYMMDD-dev`

### Automated Builds

**Docker Engine:**
- Weekly builds: Every Sunday at 02:00 UTC (latest Moby master)
- Release tracking: Daily check for new official Moby releases
- Automatic builds: New official releases trigger automatic RISC-V builds

**Docker Compose:**
- Weekly builds: Every Sunday at 03:00 UTC (latest Compose main)
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

**Docker Compose releases** include:
- **docker-compose-plugin_*.deb** (~12MB) - Debian package
- **docker-compose** (~10MB) - Compose v2 binary
- Installed to: `/usr/libexec/docker/cli-plugins/`
- Symlink: `/usr/bin/docker-compose` (backward compat)

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
- **[COMPOSE-TESTING.md](COMPOSE-TESTING.md)** - Docker Compose testing and validation guide
- **[RUNNER-SETUP.md](RUNNER-SETUP.md)** - CI/CD runner setup for automated builds
- **[GitHub Actions Workflows](.github/workflows/)** - Automated build configurations

## Known Limitations

- **Development builds**: Current builds are marked as `version dev`
- **Docker CLI**: Not included; use official Docker CLI or build separately
- **Frozen images**: Disabled (no RISC-V64 manifests for busybox/hello-world)
- **Legacy CLI tests**: Disabled (old v18.06.3-ce integration tests)
- **Hardware testing**: Limited to specific RISC-V64 hardware

## Project Status

- ✅ **First release**: v1.0.0 (October 2025)
- ✅ **Automated builds**: Active (weekly + release tracking)
- ✅ **CI/CD**: Self-hosted RISC-V64 runner operational
- ✅ **Debian packaging**: Complete with APT repository
- ✅ **APT repository**: https://gounthar.github.io/docker-for-riscv64
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
