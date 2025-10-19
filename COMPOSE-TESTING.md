# Docker Compose Testing Guide for RISC-V64

Testing guide for Docker Compose v2 plugin on RISC-V64 architecture.

## Prerequisites

- RISC-V64 hardware or emulator
- Docker Engine installed and running
- Git with submodules initialized

## Phase 1: Binary Build Testing

### Build Compose Binary

```bash
# Clone repository with submodules
git clone --recurse-submodules https://github.com/gounthar/docker-for-riscv64.git
cd docker-for-riscv64

# Check out compose submodule
cd compose
git describe --tags

# Build binary
make

# Verify binary
ls -lh bin/build/docker-compose
file bin/build/docker-compose
```

**Expected Output:**
- Binary: `bin/build/docker-compose`
- Size: ~10-12 MB
- Type: `ELF 64-bit LSB executable, RISC-V RV64`

### Test Binary Locally

```bash
# Copy to test location
cp bin/build/docker-compose /tmp/docker-compose
chmod +x /tmp/docker-compose

# Test version command
/tmp/docker-compose version

# Install as plugin
sudo mkdir -p /usr/libexec/docker/cli-plugins
sudo cp /tmp/docker-compose /usr/libexec/docker/cli-plugins/
sudo chmod +x /usr/libexec/docker/cli-plugins/docker-compose

# Test as plugin
docker compose version
```

**Expected Output:**
```
Docker Compose version v2.40.1
```

## Phase 2: Workflow Testing

### Trigger Manual Build

```bash
# Trigger compose build workflow
gh workflow run compose-weekly-build.yml

# Monitor build
gh run watch

# Check release
gh release list | grep compose
```

**Expected:**
- Build completes in ~5-10 minutes
- Release created: `compose-vX.Y.Z-riscv64` or `compose-vYYYYMMDD-dev`
- Binary uploaded to release

### Verify Release Assets

```bash
# Check release
RELEASE_TAG="compose-v2.40.1-riscv64"
gh release view $RELEASE_TAG

# Download and verify binary
gh release download $RELEASE_TAG -p docker-compose
chmod +x docker-compose
./docker-compose version
```

## Phase 3: Package Build Testing

### Trigger Package Build

```bash
# Trigger package build workflow
gh workflow run build-compose-package.yml -f release_tag=compose-v2.40.1-riscv64

# Monitor build
gh run watch
```

**Expected:**
- Package build completes in ~2-3 minutes
- `.deb` file uploaded to release

### Test Package Locally

```bash
# Download package
gh release download $RELEASE_TAG -p "docker-compose-plugin_*.deb"

# Install package
sudo dpkg -i docker-compose-plugin_*.deb

# Verify installation
dpkg -L docker-compose-plugin
docker compose version
which docker-compose
ls -l /usr/bin/docker-compose
```

**Expected Files:**
- Binary: `/usr/libexec/docker/cli-plugins/docker-compose`
- Symlink: `/usr/bin/docker-compose` → `/usr/libexec/docker/cli-plugins/docker-compose`

## Phase 4: Functional Testing

### Test Basic Commands

```bash
# Version
docker compose version

# Help
docker compose --help

# Backward compat
docker-compose version
```

### Test with Sample Compose File

Create `test-compose.yml`:

```yaml
services:
  web:
    image: nginx:alpine
    ports:
      - "8080:80"
    environment:
      - NGINX_PORT=80

  redis:
    image: redis:alpine
    command: redis-server --appendonly yes
```

**Test Commands:**

```bash
# Validate compose file
docker compose -f test-compose.yml config

# Pull images
docker compose -f test-compose.yml pull

# Start services
docker compose -f test-compose.yml up -d

# Check status
docker compose -f test-compose.yml ps

# View logs
docker compose -f test-compose.yml logs

# Test web service
curl http://localhost:8080

# Scale service (compose v2 feature)
docker compose -f test-compose.yml up -d --scale web=2

# Stop services
docker compose -f test-compose.yml stop

# Start again
docker compose -f test-compose.yml start

# Remove containers
docker compose -f test-compose.yml down

# Remove with volumes
docker compose -f test-compose.yml down -v
```

**Expected Results:**
- All commands execute successfully
- Web service responds on port 8080
- Services start/stop cleanly
- Scaling works correctly

### Test Multi-Service Application

Create `multi-service-compose.yml`:

```yaml
services:
  db:
    image: postgres:alpine
    environment:
      POSTGRES_PASSWORD: example
      POSTGRES_DB: testdb
    volumes:
      - db-data:/var/lib/postgresql/data

  adminer:
    image: adminer
    ports:
      - "8081:8080"
    depends_on:
      - db

volumes:
  db-data:
```

**Test:**

```bash
docker compose -f multi-service-compose.yml up -d
docker compose -f multi-service-compose.yml ps
docker compose -f multi-service-compose.yml logs db
curl http://localhost:8081  # Should show adminer UI
docker compose -f multi-service-compose.yml down -v
```

## Phase 5: APT Repository Testing

### Test APT Installation

**On clean RISC-V64 system:**

```bash
# Add repository
echo "deb [arch=riscv64] https://gounthar.github.io/docker-for-riscv64 trixie main" | \
  sudo tee /etc/apt/sources.list.d/docker-riscv64.list

# Update package list
sudo apt-get update

# Check available version
apt-cache policy docker-compose-plugin

# Install
sudo apt-get install docker-compose-plugin

# Verify
docker compose version
which docker-compose
dpkg -l docker-compose-plugin
```

**Expected:**
- Package installs cleanly
- No dependency errors
- Binary and symlink in correct locations

### Test Package Upgrade

```bash
# Check current version
docker compose version

# Simulate upgrade (after new release)
sudo apt-get update
sudo apt-get upgrade docker-compose-plugin

# Verify new version
docker compose version
```

## Phase 6: Regression Testing

### Test Backward Compatibility

```bash
# Both commands should work
docker compose version
docker-compose version

# Both should produce same output
docker compose config -f test-compose.yml
docker-compose config -f test-compose.yml
```

### Test with Docker CLI

```bash
# Verify compose is recognized as plugin
docker --help | grep compose

# Should show: compose* (Docker Compose)
```

### Test Edge Cases

```bash
# Invalid compose file
echo "invalid yaml" > invalid.yml
docker compose -f invalid.yml config  # Should error gracefully

# Missing file
docker compose -f nonexistent.yml up  # Should error with clear message

# Empty compose file
touch empty.yml
docker compose -f empty.yml config  # Should error appropriately
```

## Phase 7: Performance Testing

### Measure Startup Time

```bash
# Time compose operations
time docker compose -f test-compose.yml up -d
time docker compose -f test-compose.yml down
```

**Expected:**
- Startup: < 10 seconds for simple compose file
- Shutdown: < 5 seconds

### Test with Large Compose File

Create `large-compose.yml` with 10+ services and test performance.

## Success Criteria

- [ ] Binary builds successfully for RISC-V64
- [ ] Binary size ~10-12 MB
- [ ] `docker compose version` works
- [ ] Package installs cleanly via dpkg
- [ ] Package installs via APT repository
- [ ] Symlink created correctly for backward compatibility
- [ ] `docker-compose` command works (v1 compat)
- [ ] Basic compose commands work (up, down, ps, logs)
- [ ] Multi-service applications work
- [ ] Services with dependencies work (depends_on)
- [ ] Volume management works
- [ ] Network management works
- [ ] Environment variables work
- [ ] Port mapping works
- [ ] Scaling services works
- [ ] No errors in system logs
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
- Docker Compose: vX.Y.Z-riscv64
- Kernel: 5.15.x

## References

- Compose Specification: https://compose-spec.io
- Docker Compose Docs: https://docs.docker.com/compose/
- Issue #11: https://github.com/gounthar/docker-for-riscv64/issues/11
- PR #15: https://github.com/gounthar/docker-for-riscv64/pull/15
