# Docker Engine for RISC-V64

Native Docker Engine binaries built for RISC-V64 architecture, enabling containerization on RISC-V hardware.

## Overview

This project provides pre-built Docker Engine binaries for RISC-V64 Linux systems. Built from the official [Moby](https://github.com/moby/moby) source with minimal patches for RISC-V compatibility, these binaries enable running Docker containers natively on RISC-V hardware.

**Key Features:**
- Native RISC-V64 compilation
- Debian APT repository for easy installation
- Automated `.deb` package creation
- Automated weekly builds
- Based on official Moby releases
- Built on Debian Trixie
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

## Architecture Support

**Supported:**
- ✅ RISC-V64 (riscv64)

**Tested Hardware:**
- BananaPi F3
- Other RISC-V64 SBCs (community tested)

**Operating Systems:**
- Debian Trixie (primary)
- Other RISC-V Linux distributions (may work)

## Releases

### Release Naming

- **Official Docker releases**: `vX.Y.Z-riscv64` (e.g., `v27.5.1-riscv64`)
- **Development builds**: `vYYYYMMDD-dev` (e.g., `v20251018-dev`)

### Automated Builds

- **Weekly builds**: Every Sunday at 02:00 UTC (latest Moby master)
- **Release tracking**: Daily check for new official Moby releases
- **Automatic builds**: New official releases trigger automatic RISC-V builds

### Components

Each release includes:
- **docker.io_*.deb** (~140MB) - Complete Debian package (all components)
- **dockerd** (73MB) - Docker Engine daemon
- **docker-proxy** (2.4MB) - Docker network proxy
- **containerd** (37MB) - Container runtime
- **runc** (15MB) - OCI runtime
- **containerd-shim-runc-v2** (13MB) - Containerd shim
- **VERSIONS.txt** - Component version information

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
