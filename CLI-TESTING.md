# Docker CLI Testing Guide for RISC-V64

Testing guide for Docker CLI on RISC-V64 architecture.

## Prerequisites

- RISC-V64 hardware or emulator
- Docker Engine installed and running
- Git with submodules initialized
- GitHub CLI (`gh`) for automated scripts

> **Note:** This guide uses specific version numbers for illustration (e.g., `cli-v28.5.1-riscv64`).
> Always check the [releases page](https://github.com/gounthar/docker-for-riscv64/releases)
> for the latest CLI versions. See [Dynamic Version Detection](#dynamic-version-detection) below
> for automated scripts to fetch the latest release.

## Phase 1: Binary Build Testing

### Build CLI Binary

```bash
# Clone repository with submodules
git clone --recurse-submodules https://github.com/gounthar/docker-for-riscv64.git
cd docker-for-riscv64

# Check out CLI submodule
cd cli
git describe --tags

# Build binary
make -f docker.Makefile binary

# Verify binary
ls -lh build/docker
file build/docker
```

**Expected Output:**
- Binary: `build/docker`
- Size: ~40-45 MB
- Type: `ELF 64-bit LSB executable, RISC-V RV64`

### Test Binary Locally

```bash
# Copy to test location
cp build/docker /tmp/docker
chmod +x /tmp/docker

# Test version command
/tmp/docker --version

# Test help
/tmp/docker --help

# Install to system
sudo cp /tmp/docker /usr/bin/docker

# Test system-wide
docker --version
docker info
```

**Expected Output:**
```text
Docker version 28.5.1, build <commit>
```

## Phase 2: Workflow Testing

### Trigger Manual Build

```bash
# Trigger CLI build workflow
gh workflow run cli-weekly-build.yml -f cli_ref=v28.5.1

# Monitor build
gh run watch

# Check release
gh release list | grep cli
```

**Expected:**
- Build completes in ~10-15 minutes
- Release created: `cli-vX.Y.Z-riscv64` or `cli-vYYYYMMDD-dev`
- Binary uploaded to release

### Verify Release Assets

```bash
# Check release
RELEASE_TAG="cli-v28.5.1-riscv64"
gh release view $RELEASE_TAG

# Download and verify binary
gh release download $RELEASE_TAG -p docker
chmod +x docker
./docker --version
```

## Phase 3: Package Build Testing

### Trigger Package Build

```bash
# Trigger package build workflow
gh workflow run build-cli-package.yml -f release_tag=cli-v28.5.1-riscv64

# Monitor build
gh run watch
```

**Expected:**
- Package build completes in ~2-3 minutes
- `.deb` file uploaded to release

### Test Package Locally

```bash
# Download package
gh release download $RELEASE_TAG -p "docker-cli_*.deb"

# Install package
sudo dpkg -i docker-cli_*.deb

# Verify installation
dpkg -L docker-cli
docker --version
which docker
ls -l /usr/bin/docker
```

**Expected Files:**
- Binary: `/usr/bin/docker`

## Phase 4: Functional Testing

### Test Basic Commands

```bash
# Version
docker --version
docker version

# Info
docker info

# Help
docker --help
docker run --help
docker ps --help
```

### Test Container Operations

**Pull an image:**
```bash
docker pull hello-world
docker images
```

**Run a container:**
```bash
docker run hello-world
docker run -d --name test-nginx nginx:alpine
docker ps
docker ps -a
```

**Inspect container:**
```bash
docker inspect test-nginx
docker logs test-nginx
docker stats --no-stream test-nginx
```

**Execute in container:**
```bash
docker exec test-nginx ls /usr/share/nginx/html
docker exec -it test-nginx sh
# exit
```

**Stop and remove:**
```bash
docker stop test-nginx
docker rm test-nginx
docker rmi nginx:alpine
```

### Test Image Operations

```bash
# Search
docker search alpine

# Pull specific version
docker pull alpine:3.18

# List images
docker images

# Tag image
docker tag alpine:3.18 my-alpine:latest

# Inspect image
docker inspect alpine:3.18

# Remove image
docker rmi my-alpine:latest
docker rmi alpine:3.18
```

### Test Volume Operations

```bash
# Create volume
docker volume create test-volume

# List volumes
docker volume ls

# Inspect volume
docker volume inspect test-volume

# Use volume with container
docker run -d --name vol-test -v test-volume:/data alpine sleep 3600
docker exec vol-test sh -c "echo 'test data' > /data/test.txt"
docker exec vol-test cat /data/test.txt

# Cleanup
docker stop vol-test
docker rm vol-test
docker volume rm test-volume
```

### Test Network Operations

```bash
# Create network
docker network create test-network

# List networks
docker network ls

# Inspect network
docker network inspect test-network

# Run container on network
docker run -d --name net-test --network test-network alpine sleep 3600

# Cleanup
docker stop net-test
docker rm net-test
docker network rm test-network
```

### Test Build Operations

Create `test-dockerfile`:
```dockerfile
FROM alpine:latest
RUN apk add --no-cache curl
CMD ["curl", "--version"]
```

**Test build:**
```bash
# Build image
docker build -t test-image:latest -f test-dockerfile .

# Run built image
docker run test-image:latest

# Check image
docker images test-image

# Remove image
docker rmi test-image:latest
```

## Phase 5: APT Repository Testing

### Test APT Installation

**On clean RISC-V64 system:**

```bash
# Add GPG key
wget -qO- https://github.com/gounthar/docker-for-riscv64/releases/download/gpg-key/docker-riscv64.gpg | \
  sudo tee /usr/share/keyrings/docker-riscv64.gpg > /dev/null

# Add signed repository
echo "deb [arch=riscv64 signed-by=/usr/share/keyrings/docker-riscv64.gpg] https://gounthar.github.io/docker-for-riscv64 trixie main" | \
  sudo tee /etc/apt/sources.list.d/docker-riscv64.list

# Update package list
sudo apt-get update

# Check available version
apt-cache policy docker-cli

# Install
sudo apt-get install docker-cli

# Verify
docker --version
which docker
dpkg -l docker-cli
```

**Expected:**
- Package installs cleanly
- No dependency errors
- Binary in correct location (/usr/bin/docker)

### Test Package Upgrade

```bash
# Check current version
docker --version

# Simulate upgrade (after new release)
sudo apt-get update
sudo apt-get upgrade docker-cli

# Verify new version
docker --version
```

## Phase 6: Integration Testing

### Test with Docker Engine

**Prerequisite:** Docker Engine must be running

```bash
# Start dockerd if not running
sudo systemctl start docker

# Test CLI connects to engine
docker version  # Should show both client and server versions
docker info     # Should show engine info

# Test full workflow
docker run -d --name integration-test nginx:alpine
docker ps | grep integration-test
docker logs integration-test
docker stop integration-test
docker rm integration-test
```

**Expected:**
- Client and server versions displayed
- All commands work seamlessly
- No connection errors

### Test with Docker Compose

**If docker-compose-plugin is installed:**

```bash
# Create test compose file
cat > test-compose.yml << 'EOF'
services:
  web:
    image: nginx:alpine
    ports:
      - "8080:80"
EOF

# Test compose integration
docker compose -f test-compose.yml up -d
docker ps
docker compose -f test-compose.yml down
```

### Test Multi-Architecture

```bash
# Check buildx availability
docker buildx version

# List builder instances
docker buildx ls

# Check supported platforms
docker buildx inspect --bootstrap
```

## Phase 7: Compatibility Testing

### Test Backward Compatibility

```bash
# Test old command formats still work
docker ps -a
docker images -a
docker system df
docker system prune --help
```

### Test Plugin System

```bash
# List CLI plugins
docker --help | grep -A 20 "Management Commands"

# Test plugin detection
ls -la /usr/libexec/docker/cli-plugins/
docker compose version  # If compose plugin installed
```

### Test Config Files

```bash
# Check config location
ls -la ~/.docker/

# Test custom config
mkdir -p ~/.docker
cat > ~/.docker/config.json << 'EOF'
{
  "auths": {},
  "detachKeys": "ctrl-q,ctrl-q"
}
EOF

# Verify config is read
docker info | grep -i config
```

## Phase 8: Performance Testing

### Measure Command Performance

```bash
# Time basic commands
time docker version
time docker images
time docker ps -a
```

**Expected:**
- version: < 1 second
- images: < 2 seconds
- ps: < 2 seconds

### Test with Many Containers

```bash
# Create multiple containers
for i in {1..10}; do
  docker run -d --name test-$i alpine sleep 300
done

# Test listing performance
time docker ps

# Cleanup
docker stop $(docker ps -q --filter "name=test-")
docker rm $(docker ps -aq --filter "name=test-")
```

### Test Large Image Operations

```bash
# Pull a larger image
time docker pull python:3.11

# Test inspect on large image
time docker inspect python:3.11

# Cleanup
docker rmi python:3.11
```

## Dynamic Version Detection

For testing automation or always using the latest CLI version, use these commands to dynamically detect the latest release:

### Fetch Latest CLI Release

```bash
# Using GitHub CLI (gh)
LATEST_CLI=$(gh release list --repo gounthar/docker-for-riscv64 --limit 20 --json tagName | \
  jq -r '[.[] | select(.tagName | test("^cli-v[0-9]+\\.[0-9]+\\.[0-9]+-riscv64$"))][0].tagName')

echo "Latest CLI: $LATEST_CLI"
```

### Using with Testing Scripts

Replace hardcoded versions in Phase 2 and Phase 3:

```bash
# Phase 2: Trigger Manual Build with latest version
LATEST_CLI_TAG=$(gh release list --repo gounthar/docker-for-riscv64 --limit 20 --json tagName | \
  jq -r '[.[] | select(.tagName | test("^cli-v[0-9]+\\.[0-9]+\\.[0-9]+-riscv64$"))][0].tagName')

LATEST_CLI_VERSION=$(echo "$LATEST_CLI_TAG" | sed 's/^cli-v//')

# Trigger build
gh workflow run cli-weekly-build.yml -f cli_ref=v${LATEST_CLI_VERSION}

# Phase 3: Test with latest release
RELEASE_TAG=$LATEST_CLI_TAG
gh release view $RELEASE_TAG

# Download and verify binary
gh release download $RELEASE_TAG -p docker
chmod +x docker
./docker --version
```

### Automated Testing Script

Here's a complete script for automated CLI testing:

```bash
#!/bin/bash
set -e

# Check for required dependencies
command -v gh &> /dev/null || {
  echo "Error: GitHub CLI (gh) not found. Install with: https://cli.github.com"
  exit 1
}

command -v jq &> /dev/null || {
  echo "Error: jq not found. Install with: sudo apt-get install jq"
  exit 1
}

# Fetch latest CLI release
echo "Detecting latest CLI release..."
LATEST_CLI=$(gh release list --repo gounthar/docker-for-riscv64 --limit 20 --json tagName | \
  jq -r '[.[] | select(.tagName | test("^cli-v[0-9]+\\.[0-9]+\\.[0-9]+-riscv64$"))][0].tagName')

if [[ -z "$LATEST_CLI" ]]; then
  echo "Error: No CLI releases found. Check repository and network connectivity."
  exit 1
fi

echo "Latest CLI: $LATEST_CLI"

# Download binary
echo "Downloading CLI binary..."
gh release download $LATEST_CLI -p docker --clobber

# Verify binary
chmod +x docker
echo "CLI Version:"
./docker --version

# Optional: Install system-wide
read -p "Install to /usr/bin/docker? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo install -m 0755 docker /usr/bin/docker
    echo "Installed successfully!"
    docker --version
fi
```

## Success Criteria

- [ ] Binary builds successfully for RISC-V64
- [ ] Binary size ~40-45 MB
- [ ] `docker --version` works
- [ ] Package installs cleanly via dpkg
- [ ] Package installs via APT repository
- [ ] Binary installed to /usr/bin/docker
- [ ] All basic commands work (version, info, help)
- [ ] Container operations work (run, stop, rm)
- [ ] Image operations work (pull, tag, rmi)
- [ ] Volume management works
- [ ] Network management works
- [ ] Build operations work
- [ ] CLI connects to Docker Engine successfully
- [ ] Integration with Docker Compose works
- [ ] No errors in CLI operations
- [ ] Performance acceptable on RISC-V64 hardware

## Known Issues

Document any issues discovered during testing:

- [ ] Issue 1: [Description]
- [ ] Issue 2: [Description]

## Testing Environment

**Hardware:**
- BananaPi F3 (RISC-V64)
- 8GB RAM
- Armbian Trixie

**Software:**
- Docker Engine: vX.Y.Z-riscv64
- Docker CLI: vX.Y.Z-riscv64
- Kernel: 5.15.x

## References

- [Docker CLI Docs](https://docs.docker.com/engine/reference/commandline/cli/)
- [Docker CLI Repository](https://github.com/docker/cli)
- [Issue #16](https://github.com/gounthar/docker-for-riscv64/issues/16)
- [Docker for RISC-V64](https://github.com/gounthar/docker-for-riscv64)
