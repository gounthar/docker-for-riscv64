# Debian Packaging for Docker RISC-V64

This directory contains Debian packaging files for creating `.deb` packages of Docker Engine built for RISC-V64 architecture.

## Package Strategy

**Debian packages are built ONLY for official tagged Moby releases** (e.g., v27.5.1), not for weekly development builds.

This ensures:
- Stable, versioned releases in Debian packages
- Clear correspondence to upstream Docker versions
- Production-ready binaries
- Proper version tracking in APT repositories

## Package: docker-engine-riscv64

**Version Format**: `<upstream-version>-<debian-revision>` (e.g., `27.5.1-1`)

**Contents**:
- `/usr/bin/dockerd` - Docker Engine daemon
- `/usr/bin/docker-proxy` - Docker network proxy
- `/lib/systemd/system/docker.service` - Systemd service
- `/lib/systemd/system/docker.socket` - Systemd socket
- `/etc/docker/daemon.json` - Configuration example

## Prerequisites

### On Build Machine

```bash
sudo apt-get install -y \
    debhelper \
    dh-make \
    dpkg-dev \
    lintian \
    systemd
```

### Binary Requirements

Before building, you need the pre-built binaries from a tagged release:

```bash
# Download from official release (e.g., v27.5.1-riscv64)
VERSION="v27.5.1-riscv64"
wget https://github.com/gounthar/docker-for-riscv64/releases/download/${VERSION}/dockerd
wget https://github.com/gounthar/docker-for-riscv64/releases/download/${VERSION}/docker-proxy

# Place in repository root
mv dockerd docker-proxy ../
chmod +x ../dockerd ../docker-proxy
```

## Building the Package

### 1. Prepare the Source

```bash
# Ensure you're in the repository root
cd /path/to/docker-for-riscv64

# Ensure binaries are present
ls -lh dockerd docker-proxy

# Update changelog for the new version
dch -v 27.5.1-1 "New upstream release 27.5.1"
```

### 2. Build the Package

```bash
# Build binary package
dpkg-buildpackage -us -uc -b

# The .deb file will be created in the parent directory
ls -lh ../docker-engine-riscv64_*.deb
```

### 3. Validate the Package

```bash
# Check with lintian
lintian --info --display-info --display-experimental --pedantic \
    ../docker-engine-riscv64_*.deb

# Inspect package contents
dpkg-deb --contents ../docker-engine-riscv64_*.deb

# Check package info
dpkg-deb --info ../docker-engine-riscv64_*.deb
```

## Installing the Package

### Manual Installation

```bash
# Install the package
sudo dpkg -i docker-engine-riscv64_*.deb

# Fix dependencies if needed
sudo apt-get install -f
```

### Post-Installation

```bash
# Add your user to docker group
sudo usermod -aG docker $USER

# Log out and back in, then start Docker
sudo systemctl start docker
sudo systemctl enable docker

# Verify
docker version
docker run hello-world  # Won't work yet - need to build for riscv64
```

## Creating an APT Repository

Once packages are built, you can host them in a custom APT repository:

```bash
# Install repository tools
sudo apt-get install reprepro

# Create repository structure
mkdir -p apt-repo/conf

# Configure reprepro
cat > apt-repo/conf/distributions << EOF
Origin: docker-riscv64
Label: Docker RISC-V64
Codename: trixie
Architectures: riscv64
Components: main
Description: Docker Engine for RISC-V64
SignWith: yes
EOF

# Add package to repository
cd apt-repo
reprepro includedeb trixie /path/to/docker-engine-riscv64_*.deb

# Serve with HTTP server or upload to GitHub Pages
```

## Automated Builds

A GitHub Actions workflow should be created to:
1. Trigger on new official Moby releases (vX.Y.Z-riscv64)
2. Download the binaries from that release
3. Build the Debian package
4. Upload to APT repository or attach to GitHub release

## Troubleshooting

### Missing Dependencies

```bash
# Install build dependencies
sudo apt-get build-dep .
```

### Lintian Warnings

Common warnings and how to fix them:
- `binary-without-manpage`: Add man pages to debian/
- `no-copyright-file`: Ensure debian/copyright is complete
- `systemd-service-file-missing`: Check debian/*.service files

### Package Installation Fails

```bash
# Check dependencies
dpkg -I docker-engine-riscv64_*.deb | grep Depends

# Install missing dependencies
sudo apt-get install -f
```

## Files in This Directory

- `control` - Package metadata and dependencies
- `changelog` - Version history (Debian format)
- `copyright` - License information
- `rules` - Build instructions (Makefile)
- `postinst` - Post-installation script (creates docker group)
- `prerm` - Pre-removal script (stops services)
- `docker.service` - Systemd service file
- `docker.socket` - Systemd socket file
- `daemon.json` - Example Docker daemon configuration

## Version Management

When a new official Moby release is available:

1. Build new RISC-V64 binaries (via GitHub Actions)
2. Download binaries from release
3. Update `debian/changelog`:
   ```bash
   dch -v 27.6.0-1 "New upstream release 27.6.0"
   ```
4. Build new package
5. Upload to APT repository

## References

- [Debian New Maintainers' Guide](https://www.debian.org/doc/manuals/maint-guide/)
- [Debian Policy Manual](https://www.debian.org/doc/debian-policy/)
- [Systemd Integration](https://wiki.debian.org/systemd/Integration)
- [Docker Packaging](https://github.com/docker/docker-ce-packaging)

## Support

For issues with the Debian packages:
- GitHub Issues: https://github.com/gounthar/docker-for-riscv64/issues
- Tag issues with `debian-packaging` label
