# RPM Package Testing Guide

This document outlines the testing procedures for Docker RPM packages built for RISC-V64 architecture on Fedora and other RPM-based distributions.

## Prerequisites

### Hardware/Environment
- RISC-V64 hardware (e.g., BananaPi F3)
- Fedora 39+ RISC-V64 (or other RPM-based distribution)
- Internet connection for downloading packages
- Root/sudo access

### Test Environment Setup

```bash
# Verify architecture
uname -m  # Should output: riscv64

# Verify distribution
cat /etc/fedora-release  # For Fedora
# OR
cat /etc/redhat-release  # For RHEL/Rocky/AlmaLinux

# Update system
sudo dnf update -y

# Install testing utilities
sudo dnf install -y rpm-build rpmlint createrepo_c
```

## Phase 1: Build Testing

### 1.1 Trigger Manual Build

```bash
# Trigger manual workflow for a specific version
gh workflow run build-rpm-package.yml -f release_tag=v28.5.1-riscv64

# Monitor build progress
gh run watch

# Check for errors
gh run list --workflow=build-rpm-package.yml --limit 5
```

### 1.2 Verify Build Outputs

```bash
# Check release assets
VERSION="v28.5.1-riscv64"
gh release view $VERSION

# Expected RPM files:
# - runc-1.3.0-1.fc*.riscv64.rpm
# - containerd-1.7.28-1.fc*.riscv64.rpm
# - moby-engine-28.5.1-1.fc*.riscv64.rpm
```

## Phase 2: Package Validation

### 2.1 Download and Inspect Packages

```bash
VERSION="v28.5.1-riscv64"

# Download all RPM packages
mkdir -p ~/rpm-test && cd ~/rpm-test
gh release download $VERSION --pattern '*.rpm' --repo gounthar/docker-for-riscv64

# Verify package integrity
for rpm in *.rpm; do
    echo "=== Checking: $rpm ==="
    rpm -qip "$rpm"
    echo ""
done
```

### 2.2 Run rpmlint Checks

```bash
# Check all packages for issues
rpmlint *.rpm

# Common acceptable warnings:
# - no-documentation (expected for minimal packages)
# - no-manual-page-for-binary (expected)

# Red flags:
# - unstripped-binary-or-object (should be stripped)
# - invalid-directory-reference
# - missing-dependency
```

### 2.3 Verify Package Contents

```bash
# List files in each package
for rpm in *.rpm; do
    echo "=== Contents of $rpm ==="
    rpm -qlp "$rpm"
    echo ""
done

# Expected files:
# runc: /usr/bin/runc
# containerd: /usr/bin/containerd, /usr/bin/containerd-shim-runc-v2, /usr/lib/systemd/system/containerd.service
# moby-engine: /usr/bin/dockerd, /usr/bin/docker-proxy, /usr/lib/systemd/system/docker.service, /usr/lib/systemd/system/docker.socket
```

### 2.4 Check Dependencies

```bash
# Verify package dependencies
for rpm in *.rpm; do
    echo "=== Dependencies for $rpm ==="
    rpm -qRp "$rpm"
    echo ""
done

# Verify no missing dependencies
sudo dnf install --downloadonly *.rpm
```

## Phase 3: Installation Testing

### 3.1 Clean Install Test

```bash
# Remove any existing Docker installation
sudo systemctl stop docker 2>/dev/null || true
sudo dnf remove -y docker* moby* containerd runc 2>/dev/null || true

# Install packages in dependency order
sudo dnf install -y runc-*.rpm
sudo dnf install -y containerd-*.rpm
sudo dnf install -y moby-engine-*.rpm

# Verify installation
rpm -qa | grep -E 'runc|containerd|moby-engine'
```

### 3.2 Verify Binary Installation

```bash
# Check binary versions
runc --version
containerd --version
dockerd --version

# Verify file permissions
ls -l /usr/bin/{runc,containerd,dockerd,docker-proxy}

# All should be:
# -rwxr-xr-x root root
```

### 3.3 Service Configuration Test

```bash
# Check systemd units
systemctl list-unit-files | grep -E 'docker|containerd'

# Expected units:
# - docker.service (enabled)
# - docker.socket (enabled)
# - containerd.service (enabled)

# Check service status (before starting)
systemctl status containerd --no-pager
systemctl status docker --no-pager
```

## Phase 4: Functional Testing

### 4.1 Start Docker Services

```bash
# Start containerd
sudo systemctl start containerd
sudo systemctl status containerd --no-pager

# Start Docker
sudo systemctl start docker
sudo systemctl status docker --no-pager

# Check for errors
sudo journalctl -u containerd -n 50 --no-pager
sudo journalctl -u docker -n 50 --no-pager
```

### 4.2 Basic Docker Operations

```bash
# Add current user to docker group (if not already)
sudo usermod -aG docker $USER
newgrp docker  # Apply group without logging out

# Test Docker info
docker info
docker version

# Pull and run test image
docker run --rm hello-world

# Expected: "Hello from Docker!" message
```

### 4.3 Container Lifecycle Test

```bash
# Run interactive container
docker run -it --rm alpine sh -c "echo 'Test successful'; uname -m"
# Expected output: "Test successful" and "riscv64"

# Run detached container
docker run -d --name test-nginx nginx:alpine
docker ps

# Check logs
docker logs test-nginx

# Stop and remove
docker stop test-nginx
docker rm test-nginx
```

### 4.4 Volume and Network Test

```bash
# Create volume
docker volume create test-vol
docker volume ls

# Create network
docker network create test-net
docker network ls

# Run container with volume and network
docker run -d --name test-app \
  -v test-vol:/data \
  --network test-net \
  alpine sleep 3600

# Verify
docker inspect test-app | grep -A 5 "Mounts"
docker inspect test-app | grep -A 5 "Networks"

# Cleanup
docker stop test-app
docker rm test-app
docker volume rm test-vol
docker network rm test-net
```

## Phase 5: RPM Repository Testing

### 5.1 Add Repository

```bash
# Add repository configuration
sudo curl -L https://gounthar.github.io/docker-for-riscv64/rpm/docker-riscv64.repo \
  -o /etc/yum.repos.d/docker-riscv64.repo

# Verify repository configuration
cat /etc/yum.repos.d/docker-riscv64.repo

# Check repository metadata
sudo dnf makecache --repo docker-riscv64
sudo dnf repolist
```

### 5.2 Repository Installation Test

```bash
# Remove manually installed packages
sudo dnf remove -y moby-engine containerd runc

# Install from repository
sudo dnf install -y moby-engine

# Verify installation source
rpm -qi moby-engine | grep -E 'Name|Version|Release|Source'

# Test functionality
sudo systemctl start docker
docker run --rm hello-world
```

### 5.3 Update Test

```bash
# Simulate update scenario
# (After a new version is released)

# Check for updates
sudo dnf check-update moby-engine containerd runc

# Update packages
sudo dnf update -y moby-engine

# Verify new version
dockerd --version
```

## Phase 6: Compose Plugin Testing

### 6.1 Install Compose Plugin RPM

```bash
VERSION="compose-v2.40.1-riscv64"

# Download and install
cd ~/rpm-test
gh release download $VERSION --pattern 'docker-compose-plugin*.rpm' --repo gounthar/docker-for-riscv64
sudo dnf install -y docker-compose-plugin-*.rpm

# Verify installation
docker compose version
ls -l /usr/libexec/docker/cli-plugins/docker-compose
ls -l /usr/bin/docker-compose  # Should be symlink
```

### 6.2 Compose Functional Test

```bash
# Create test compose file
cat > docker-compose.yml << 'EOF'
services:
  web:
    image: nginx:alpine
    ports:
      - "8080:80"

  app:
    image: alpine
    command: sleep 3600
EOF

# Test compose commands
docker compose config
docker compose up -d
docker compose ps
docker compose logs web
docker compose down

# Cleanup
rm docker-compose.yml
```

## Phase 7: CLI Package Testing

### 7.1 Install Docker CLI RPM

```bash
VERSION="cli-v28.5.1-riscv64"

# Download and install
cd ~/rpm-test
gh release download $VERSION --pattern 'docker-cli*.rpm' --repo gounthar/docker-for-riscv64
sudo dnf install -y docker-cli-*.rpm

# Verify installation
docker --version
which docker
```

## Phase 8: Upgrade/Downgrade Testing

### 8.1 Upgrade Test

```bash
# Install older version first (if available)
OLD_VERSION="v28.4.0-riscv64"
gh release download $OLD_VERSION --pattern '*.rpm'
sudo dnf install -y moby-engine-*.rpm

# Verify old version
dockerd --version

# Upgrade to newer version
NEW_VERSION="v28.5.1-riscv64"
gh release download $NEW_VERSION --pattern 'moby-engine*.rpm'
sudo dnf upgrade -y moby-engine-*.rpm

# Verify upgrade
dockerd --version
sudo systemctl status docker
```

### 8.2 Downgrade Test

```bash
# Downgrade (if needed)
sudo dnf downgrade moby-engine

# Verify
dockerd --version
```

## Phase 9: Uninstall Testing

### 9.1 Clean Removal

```bash
# Stop services
sudo systemctl stop docker
sudo systemctl stop containerd

# Remove packages
sudo dnf remove -y moby-engine containerd runc docker-cli docker-compose-plugin

# Verify removal
rpm -qa | grep -E 'docker|moby|containerd|runc'

# Check for leftover files (expected: none in /usr/bin)
ls -l /usr/bin/{docker,dockerd,containerd,runc} 2>/dev/null || echo "Binaries removed successfully"

# Check services (should be gone)
systemctl list-unit-files | grep -E 'docker|containerd' || echo "Services removed successfully"
```

### 9.2 Data Cleanup

```bash
# Optional: Remove Docker data (containers, images, volumes)
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd

# Remove docker group
sudo groupdel docker 2>/dev/null || true
```

## Expected Results

### Success Criteria

✅ All RPM packages install without dependency errors
✅ Binary versions match expected versions
✅ Services start and run without errors
✅ Basic Docker operations (run, stop, rm) work
✅ Compose plugin integrates correctly
✅ Repository installation works
✅ Packages can be upgraded/downgraded
✅ Clean uninstallation leaves no artifacts

### Common Issues

**Issue**: `Error: nothing provides libseccomp`
**Solution**: `sudo dnf install -y libseccomp`

**Issue**: `Error: nothing provides iptables`
**Solution**: `sudo dnf install -y iptables`

**Issue**: `Permission denied` when running docker
**Solution**: Add user to docker group and re-login

**Issue**: `Cannot connect to Docker daemon`
**Solution**: Start docker service: `sudo systemctl start docker`

## Test Report Template

```markdown
# RPM Package Test Report

**Date**: YYYY-MM-DD
**Tester**: [Name]
**Hardware**: BananaPi F3
**Distribution**: Fedora XX RISC-V64
**Package Version**: vX.Y.Z-riscv64

## Test Results

| Phase | Test | Result | Notes |
|-------|------|--------|-------|
| 1 | Build Testing | ✅ / ❌ | |
| 2 | Package Validation | ✅ / ❌ | |
| 3 | Installation | ✅ / ❌ | |
| 4 | Functional Testing | ✅ / ❌ | |
| 5 | Repository Testing | ✅ / ❌ | |
| 6 | Compose Plugin | ✅ / ❌ | |
| 7 | CLI Package | ✅ / ❌ | |
| 8 | Upgrade/Downgrade | ✅ / ❌ | |
| 9 | Uninstall | ✅ / ❌ | |

## Issues Found

[List any issues discovered during testing]

## Recommendations

[Any recommendations for improvements]
```

## Automation

For CI/CD integration, see `.github/workflows/build-rpm-package.yml` for automated testing steps.
