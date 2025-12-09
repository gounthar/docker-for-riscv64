# BuildKit Testing Guide for RISC-V64

Testing guide for BuildKit on RISC-V64 architecture.

## Prerequisites

- RISC-V64 hardware or emulator
- Docker Engine installed and running
- Docker Buildx plugin installed
- Git with submodules initialized
- GitHub CLI (gh) for automated scripts

> **Note:** This guide uses specific version numbers for illustration (e.g., `buildkit-v0.14.0-riscv64`).
> Always check the [releases page](https://github.com/gounthar/docker-for-riscv64/releases)
> for the latest BuildKit versions. See [Dynamic Version Detection](#dynamic-version-detection) below
> for automated scripts to fetch the latest release.

## Phase 1: Binary Build Testing

### Build BuildKit Binaries

```bash
# Clone repository with submodules
git clone --recurse-submodules https://github.com/gounthar/docker-for-riscv64.git
cd docker-for-riscv64

# Check out BuildKit submodule
cd buildkit
git describe --tags

# Build binaries
make binaries

# Verify binaries (buildx outputs to bin/build/)
ls -lh bin/build/
file bin/build/buildkitd
file bin/build/buildctl
```

**Expected Output:**
- Binary: `bin/build/buildkitd`
- Binary: `bin/build/buildctl`
- Size: buildkitd ~50-60 MB, buildctl ~30-40 MB
- Type: `ELF 64-bit LSB executable, RISC-V RV64`

### Test Binaries Locally

```bash
# Copy to test location
cp bin/build/buildkitd /tmp/buildkitd
cp bin/build/buildctl /tmp/buildctl
chmod +x /tmp/buildkitd /tmp/buildctl

# Test version commands
/tmp/buildkitd --version
/tmp/buildctl --version

# Test help
/tmp/buildkitd --help
/tmp/buildctl --help
```

**Expected Output:**
```text
buildkitd github.com/moby/buildkit v0.14.0
buildctl github.com/moby/buildkit v0.14.0
```

## Phase 2: Workflow Testing

### Trigger Manual Build

```bash
# Trigger BuildKit build workflow
gh workflow run buildkit-weekly-build.yml -f buildkit_ref=v0.14.0

# Monitor build
gh run watch

# Check release
gh release list | grep buildkit
```

**Expected:**
- Build completes in ~10-20 minutes
- Release created: `buildkit-vX.Y.Z-riscv64` or `buildkit-vYYYYMMDD-dev`
- Binaries uploaded to release
- Container image pushed to GHCR

### Verify Release Assets

```bash
# Check release
RELEASE_TAG="buildkit-v0.14.0-riscv64"
gh release view $RELEASE_TAG

# Download and verify binaries
gh release download $RELEASE_TAG -p buildkitd -p buildctl
chmod +x buildkitd buildctl
./buildkitd --version
./buildctl --version
```

## Phase 3: Container Image Testing

### Pull and Test Container Image

```bash
# Pull image from GHCR
docker pull ghcr.io/gounthar/buildkit-riscv64:latest

# Verify tini symlink exists
docker run --rm ghcr.io/gounthar/buildkit-riscv64:latest ls -la /sbin/docker-init

# Test tini via original path
docker run --rm ghcr.io/gounthar/buildkit-riscv64:latest /usr/bin/tini --version

# Test tini via symlink
docker run --rm ghcr.io/gounthar/buildkit-riscv64:latest /sbin/docker-init --version
```

**Expected Results:**
- Image pulls successfully
- Symlink `/sbin/docker-init` -> `/usr/bin/tini` exists
- Both tini paths work
- No "exec /sbin/docker-init: no such file or directory" errors

### Run BuildKit Daemon

```bash
# Run buildkitd in container
docker run -d --privileged \
  --name buildkitd-test \
  -v /var/lib/buildkit:/var/lib/buildkit \
  ghcr.io/gounthar/buildkit-riscv64:latest

# Check logs
docker logs buildkitd-test

# Verify daemon is running
docker ps | grep buildkitd-test

# Stop and remove
docker stop buildkitd-test
docker rm buildkitd-test
```

**Expected Results:**
- BuildKit daemon starts without errors
- Logs show successful initialization
- No tini-related errors

## Phase 4: Docker Buildx Integration Testing

### Create Buildx Builder

```bash
# Remove any existing builders
docker buildx rm riscv-builder || true

# Create builder with custom BuildKit image
docker buildx create \
  --name riscv-builder \
  --driver docker-container \
  --driver-opt image=ghcr.io/gounthar/buildkit-riscv64:latest \
  --use

# Bootstrap builder
docker buildx inspect --bootstrap

# Verify builder is running
docker buildx ls
```

**Expected Results:**
- Builder created successfully
- Bootstrap completes without tini errors
- Builder shows as "running" in `docker buildx ls`
- BuildKit container is running

### Test Builder Functionality

```bash
# Check BuildKit container is running
docker ps | grep buildkit

# List builder instances
docker buildx ls

# Check builder details
docker buildx inspect riscv-builder

# View builder logs
docker logs buildx_buildkit_riscv-builder0
```

**Expected Results:**
- Builder instance shows as "running"
- BuildKit version displayed correctly
- No errors in logs

## Phase 5: Multi-Platform Build Testing

### Simple Multi-Platform Build

```bash
# Create test Dockerfile
cat > Dockerfile.test << 'EOF'
FROM alpine:latest
RUN echo "Hello from $(uname -m)"
CMD ["uname", "-m"]
EOF

# Build for multiple platforms
docker buildx build \
  --platform linux/riscv64,linux/amd64 \
  -t test-multiarch:latest \
  -f Dockerfile.test \
  .

# Test RISC-V64 variant (on RISC-V64 host)
docker run --rm test-multiarch:latest
```

**Expected Results:**
- Multi-platform build completes
- RISC-V64 image runs and outputs "riscv64"
- AMD64 build succeeds (even if can't run on RISC-V64)

### Complex Multi-Stage Build

```bash
# Create multi-stage Dockerfile
cat > Dockerfile.complex << 'EOF'
FROM golang:1.25-alpine AS builder
WORKDIR /app
RUN echo 'package main\nimport "fmt"\nfunc main() { fmt.Println("Hello RISC-V") }' > main.go
RUN go build -o app main.go

FROM alpine:latest
COPY --from=builder /app/app /usr/local/bin/app
CMD ["/usr/local/bin/app"]
EOF

# Build and test
docker buildx build \
  --platform linux/riscv64 \
  -t test-complex:latest \
  -f Dockerfile.complex \
  --load \
  .

docker run --rm test-complex:latest
```

**Expected Results:**
- Multi-stage build completes
- Application runs successfully
- Outputs "Hello RISC-V"

## Phase 6: Advanced BuildKit Features Testing

### Test Build Cache

```bash
# First build (no cache)
time docker buildx build \
  --platform linux/riscv64 \
  -t test-cache:v1 \
  -f Dockerfile.test \
  .

# Modify Dockerfile slightly
echo 'RUN echo "Cache test"' >> Dockerfile.test

# Second build (should use cache)
time docker buildx build \
  --platform linux/riscv64 \
  -t test-cache:v2 \
  -f Dockerfile.test \
  .
```

**Expected Results:**
- Second build significantly faster
- Cache layers used where applicable
- Only changed layers rebuild

### Test Build Secrets

```bash
# Create a secret
echo "my-secret-value" > secret.txt

# Create Dockerfile using secrets
cat > Dockerfile.secret << 'EOF'
FROM alpine:latest
RUN --mount=type=secret,id=mysecret \
    cat /run/secrets/mysecret && \
    echo "Secret processed successfully"
EOF

# Build with secret
docker buildx build \
  --platform linux/riscv64 \
  --secret id=mysecret,src=secret.txt \
  -f Dockerfile.secret \
  .

# Cleanup
rm secret.txt
```

**Expected Results:**
- Build succeeds
- Secret is mounted during build
- Secret not visible in final image

### Test BuildKit Cache Export/Import

```bash
# Build with cache export
docker buildx build \
  --platform linux/riscv64 \
  --cache-to=type=local,dest=/tmp/buildkit-cache \
  -t test-export:latest \
  -f Dockerfile.test \
  .

# Clean local cache
docker buildx prune -af

# Build with cache import
docker buildx build \
  --platform linux/riscv64 \
  --cache-from=type=local,src=/tmp/buildkit-cache \
  -t test-import:latest \
  -f Dockerfile.test \
  .

# Cleanup
rm -rf /tmp/buildkit-cache
```

**Expected Results:**
- Cache exports successfully
- Cache imports and accelerates build
- Build completes faster with imported cache

## Phase 7: Release Tracking Testing

### Test Automatic Release Detection

```bash
# Manually trigger release tracking
gh workflow run track-buildkit-releases.yml

# Monitor workflow
gh run watch

# Check if issue was created (if new version exists)
gh issue list --label buildkit-release
```

**Expected Results:**
- Workflow checks for latest BuildKit release
- If new version exists, triggers build automatically
- Creates tracking issue with monitoring commands
- Issue contains verification checklist

## Phase 8: Performance Testing

### Measure Build Performance

```bash
# Time a multi-platform build
time docker buildx build \
  --platform linux/riscv64,linux/amd64 \
  -t perf-test:latest \
  -f Dockerfile.test \
  .
```

**Expected:**
- Build completes in reasonable time
- Performance comparable to native Docker builds
- No significant overhead from BuildKit

### Test Parallel Builds

```bash
# Create multiple build contexts
for i in {1..3}; do
  mkdir -p test-$i
  cat > test-$i/Dockerfile << EOF
FROM alpine:latest
RUN echo "Build $i on \$(uname -m)"
EOF
done

# Run parallel builds
for i in {1..3}; do
  docker buildx build \
    --platform linux/riscv64 \
    -t parallel-test-$i:latest \
    test-$i &
done

# Wait for all builds
wait

# Cleanup
rm -rf test-{1..3}
```

**Expected Results:**
- All builds complete successfully
- BuildKit handles parallel builds
- No resource conflicts

## Dynamic Version Detection

For testing automation or always using the latest BuildKit version, use these commands to dynamically detect the latest release:

### Fetch Latest BuildKit Release

```bash
# Using GitHub CLI (gh)
LATEST_BUILDKIT=$(gh release list --repo gounthar/docker-for-riscv64 --limit 20 --json tagName | \
  jq -r '[.[] | select(.tagName | test("^buildkit-v[0-9]+\\.[0-9]+\\.[0-9]+-riscv64$"))][0].tagName')

echo "Latest BuildKit: $LATEST_BUILDKIT"
```

### Using with Testing Scripts

Replace hardcoded versions in Phase 2 and Phase 3:

```bash
# Phase 2: Trigger Manual Build with latest version
LATEST_BUILDKIT_TAG=$(gh release list --repo gounthar/docker-for-riscv64 --limit 20 --json tagName | \
  jq -r '[.[] | select(.tagName | test("^buildkit-v[0-9]+\\.[0-9]+\\.[0-9]+-riscv64$"))][0].tagName')

LATEST_BUILDKIT_VERSION=$(echo "$LATEST_BUILDKIT_TAG" | sed 's/^buildkit-//' | sed 's/-riscv64$//')

# Trigger build
gh workflow run buildkit-weekly-build.yml -f buildkit_ref=$LATEST_BUILDKIT_VERSION

# Phase 3: Test with latest release
RELEASE_TAG=$LATEST_BUILDKIT_TAG
gh release view $RELEASE_TAG

# Download and verify binaries
gh release download $RELEASE_TAG -p buildkitd -p buildctl
chmod +x buildkitd buildctl
./buildkitd --version
./buildctl --version
```

### Automated Testing Script

Here's a complete script for automated BuildKit testing:

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

command -v docker &> /dev/null || {
  echo "Error: docker not found. Install Docker first."
  exit 1
}

# Fetch latest BuildKit release
echo "Detecting latest BuildKit release..."
LATEST_BUILDKIT=$(gh release list --repo gounthar/docker-for-riscv64 --limit 20 --json tagName | \
  jq -r '[.[] | select(.tagName | test("^buildkit-v[0-9]+\\.[0-9]+\\.[0-9]+-riscv64$"))][0].tagName')

if [[ -z "$LATEST_BUILDKIT" ]]; then
  echo "Error: No BuildKit releases found. Check repository and network connectivity."
  exit 1
fi

echo "Latest BuildKit: $LATEST_BUILDKIT"

# Pull container image
echo "Pulling BuildKit container image..."
docker pull ghcr.io/gounthar/buildkit-riscv64:latest

# Test container
echo "Testing BuildKit container..."
docker run --rm ghcr.io/gounthar/buildkit-riscv64:latest /sbin/docker-init --version

# Create builder
echo "Creating Docker Buildx builder..."
docker buildx rm test-builder || true
docker buildx create \
  --name test-builder \
  --driver docker-container \
  --driver-opt image=ghcr.io/gounthar/buildkit-riscv64:latest \
  --use

# Bootstrap
echo "Bootstrapping builder..."
docker buildx inspect --bootstrap

# Test multi-platform build
echo "Testing multi-platform build..."
cat > Dockerfile.test << 'EOF'
FROM alpine:latest
RUN echo "Test from $(uname -m)"
EOF

docker buildx build \
  --platform linux/riscv64,linux/amd64 \
  -t buildkit-test:latest \
  -f Dockerfile.test \
  .

echo "BuildKit testing completed successfully!"
echo "Builder: test-builder"
echo "Image: ghcr.io/gounthar/buildkit-riscv64:latest"

# Cleanup
read -p "Remove test builder? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker buildx rm test-builder
    echo "Test builder removed"
fi
```

## Success Criteria

- [ ] Binaries build successfully for RISC-V64
- [ ] Binary sizes appropriate (buildkitd ~50-60MB, buildctl ~30-40MB)
- [ ] `buildkitd --version` and `buildctl --version` work
- [ ] Container image builds and runs
- [ ] Tini symlink exists and works
- [ ] GHCR image pulls successfully
- [ ] Docker Buildx builder creates successfully
- [ ] Builder bootstraps without errors
- [ ] Multi-platform builds work (RISC-V64 + AMD64)
- [ ] Build cache functions correctly
- [ ] Secret mounting works
- [ ] Cache export/import works
- [ ] Release tracking detects new versions
- [ ] All commands complete without errors
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
- Docker Buildx: vX.Y.Z-riscv64
- BuildKit: vX.Y.Z-riscv64
- Kernel: 5.15.x

## Troubleshooting

### Builder Fails to Create

**Error:** "failed to create builder"

**Solution:**
```bash
# Remove existing builder
docker buildx rm riscv-builder

# Ensure BuildKit image is available
docker pull ghcr.io/gounthar/buildkit-riscv64:latest

# Recreate builder
docker buildx create \
  --name riscv-builder \
  --driver docker-container \
  --driver-opt image=ghcr.io/gounthar/buildkit-riscv64:latest \
  --use
```

### Tini Path Error

**Error:** "exec /sbin/docker-init: no such file or directory"

**Solution:**
```bash
# Verify symlink in container
docker run --rm ghcr.io/gounthar/buildkit-riscv64:latest ls -la /sbin/docker-init

# If missing, rebuild container image (report issue)
```

### Build Hangs or Times Out

**Possible causes:**
- Network connectivity issues
- Insufficient resources (RAM/disk)
- BuildKit daemon not responding

**Solution:**
```bash
# Check BuildKit daemon logs
docker logs buildx_buildkit_riscv-builder0

# Restart builder
docker buildx stop riscv-builder
docker buildx inspect --bootstrap riscv-builder

# If persistent, recreate builder
docker buildx rm riscv-builder
# Recreate as shown above
```

### Multi-Platform Build Fails

**Error:** "unknown/unsupported platform"

**Solution:**
Ensure QEMU user-mode emulation is set up:
```bash
# Install QEMU
sudo apt-get install qemu-user-static

# Register binfmt handlers
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
```

## References

- [BuildKit Documentation](https://github.com/moby/buildkit/blob/master/README.md)
- [Docker Buildx Documentation](https://docs.docker.com/buildx/)
- [BuildKit Container Registry](https://github.com/gounthar/docker-for-riscv64/pkgs/container/buildkit-riscv64)
- [Issue #207](https://github.com/gounthar/docker-for-riscv64/issues/207) - BuildKit binaries
- [Issue #208](https://github.com/gounthar/docker-for-riscv64/issues/208) - BuildKit container image
- [Issue #209](https://github.com/gounthar/docker-for-riscv64/issues/209) - BuildKit testing
- [Issue #210](https://github.com/gounthar/docker-for-riscv64/issues/210) - BuildKit automation
- [Docker for RISC-V64](https://github.com/gounthar/docker-for-riscv64)
