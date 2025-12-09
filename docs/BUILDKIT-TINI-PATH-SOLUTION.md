# BuildKit Tini Path Solution

**Created:** 2025-12-09
**Status:** Recommended Solution Implemented
**Related Issues:** #207, #208

## Problem Statement

BuildKit (and Docker Buildx) expects the tini init process to be available at `/sbin/docker-init`. However, the docker-for-riscv64 project installs tini at `/usr/bin/tini` (via Debian/RPM packages).

This path mismatch causes the error:
```
exec /sbin/docker-init: no such file or directory
```

When users try to create a Docker Buildx builder using the BuildKit container image.

## Current State

### Tini Installation Locations

**On BananaPi F3 RISC-V64 Host:**
- `/usr/bin/tini` - Dynamic binary (Debian package: `tini`)
- `/usr/bin/tini-static` - Static binary (RPM package: `tini-static`)

**Official BuildKit Dockerfile:**
- Expects tini at: `/sbin/docker-init`
- Uses Alpine package manager: `apk add tini`
- Alpine installs tini symlinked to: `/sbin/tini` → `/sbin/docker-init`

## Evaluated Solutions

### Option 1: Symlink in Dockerfile - RECOMMENDED ✅

**Approach:** Create symlink `/sbin/docker-init` → `/usr/bin/tini` in the container image

**Implementation:**
```dockerfile
# Install tini from Debian repository
RUN apt-get update && apt-get install -y tini

# Create symlink for Docker compatibility
RUN ln -sf /usr/bin/tini /sbin/docker-init
```

**Pros:**
- ✅ Simple and clean solution
- ✅ No source code modifications needed
- ✅ Follows filesystem hierarchy conventions
- ✅ Compatible with official BuildKit expectations
- ✅ Works with both `/usr/bin/tini` and `/sbin/docker-init` references
- ✅ Minimal container image changes

**Cons:**
- None significant

**Status:** **IMPLEMENTED** in `Dockerfile.buildkit-riscv64`

### Option 2: Copy Tini Binary

**Approach:** Copy tini from `/usr/bin/tini` to `/sbin/docker-init`

**Implementation:**
```dockerfile
RUN apt-get update && apt-get install -y tini
RUN cp /usr/bin/tini /sbin/docker-init
```

**Pros:**
- Works with both paths
- No symlink management

**Cons:**
- Duplicates binary (wastes ~80KB)
- Two binaries need updates if tini is patched
- Less elegant than symlink

**Status:** Not recommended

### Option 3: Patch BuildKit Source Code

**Approach:** Modify BuildKit's hardcoded `/sbin/docker-init` path to `/usr/bin/tini`

**Implementation:**
```bash
# In buildkit source
sed -i 's|/sbin/docker-init|/usr/bin/tini|g' executor/oci/*.go
```

**Pros:**
- Native path resolution
- No container image workarounds

**Cons:**
- ❌ Requires maintaining patches
- ❌ Diverges from upstream BuildKit
- ❌ Patch must be updated for each BuildKit release
- ❌ Conflicts with project philosophy (no submodule edits)
- ❌ Makes contributing upstream harder

**Status:** **Rejected** - Violates "no submodule edits" principle

### Option 4: Environment Variable Configuration

**Approach:** Configure BuildKit via environment variable to specify tini path

**Research Finding:**
BuildKit does NOT support configurable tini path via environment variables or command-line flags.

**Status:** **Not Possible** - BuildKit hardcodes the path

### Option 5: Multi-Location Tini Installation

**Approach:** Install tini to multiple locations

**Implementation:**
```dockerfile
RUN apt-get install -y tini
RUN ln -s /usr/bin/tini /sbin/docker-init
RUN ln -s /usr/bin/tini /sbin/tini
```

**Pros:**
- Maximum compatibility
- Works with any path expectation

**Cons:**
- Overkill for the problem
- Clutters filesystem

**Status:** Not necessary (symlink alone is sufficient)

## Selected Solution: Symlink Strategy

### Implementation Details

**Dockerfile.buildkit-riscv64:**
```dockerfile
FROM debian:trixie-slim

# Install tini from Debian repository
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        tini \
        ca-certificates \
        fuse-overlayfs \
        iptables \
        git \
        openssh-client && \
    rm -rf /var/lib/apt/lists/*

# Create symlink for Docker compatibility
# Docker/BuildKit expects tini at /sbin/docker-init
# Debian installs it at /usr/bin/tini
RUN ln -sf /usr/bin/tini /sbin/docker-init

# Use tini as entrypoint
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["buildkitd", "--addr", "tcp://0.0.0.0:1234"]
```

### Why This Works

1. **Debian Package Management:**
   - `apt-get install tini` installs binary to `/usr/bin/tini`
   - Standard Debian filesystem layout

2. **Symlink Creation:**
   - `ln -sf /usr/bin/tini /sbin/docker-init` creates symlink
   - `-s`: Create symbolic link
   - `-f`: Force (overwrite if exists)

3. **Path Resolution:**
   - BuildKit looks for `/sbin/docker-init` → symlink → `/usr/bin/tini`
   - Any code referencing either path works correctly

4. **Entrypoint:**
   - Can use either `/usr/bin/tini` or `/sbin/docker-init`
   - We use `/usr/bin/tini` for clarity (shows real binary path)

### Verification

**Test that both paths work:**
```bash
# Build image
docker build -f Dockerfile.buildkit-riscv64 -t buildkit-test .

# Test direct tini path
docker run --rm buildkit-test /usr/bin/tini --version

# Test symlinked path
docker run --rm buildkit-test /sbin/docker-init --version

# Test entrypoint
docker run --rm buildkit-test buildkitd --version
```

All commands should succeed without errors.

## Alternative: Host-Level Tini Configuration

If users experience issues even with the container symlink, they can create a host-level symlink:

**On RISC-V64 host (BananaPi F3):**
```bash
# Create symlink on host
sudo ln -sf /usr/bin/tini /sbin/docker-init

# Verify
ls -la /sbin/docker-init
# Output: /sbin/docker-init -> /usr/bin/tini
```

This ensures tini is available at the expected path when BuildKit runs with volume mounts.

**Not Recommended:** Container-level symlink should be sufficient.

## Integration with Docker Buildx

With the symlink in place, Docker Buildx can use the BuildKit image:

```bash
# Create builder with custom BuildKit image
docker buildx create \
  --name riscv-builder \
  --driver docker-container \
  --driver-opt image=ghcr.io/gounthar/buildkit-riscv64:latest \
  --use

# Bootstrap builder (starts BuildKit container)
docker buildx inspect --bootstrap

# BuildKit container will:
# 1. Start with tini as PID 1
# 2. Tini handles signal forwarding
# 3. BuildKit processes run as tini children
# 4. Graceful shutdown on SIGTERM/SIGINT

# Build multi-platform image
docker buildx build \
  --platform linux/riscv64,linux/amd64 \
  -t myimage:latest \
  .
```

## Troubleshooting

### Issue: "exec /sbin/docker-init: no such file or directory"

**Cause:** Symlink not created in container image

**Solution:**
1. Rebuild container image with latest Dockerfile
2. Verify symlink exists:
   ```bash
   docker run --rm buildkit:latest ls -la /sbin/docker-init
   ```

### Issue: Tini not installed in container

**Cause:** Debian package `tini` not installed

**Solution:**
```dockerfile
RUN apt-get update && apt-get install -y tini
```

### Issue: Permission denied on symlink creation

**Cause:** Non-root user in Dockerfile

**Solution:** Ensure symlink creation runs as root (before USER directive)

## Testing Checklist

After implementing the solution:

- [x] Dockerfile installs tini via `apt-get`
- [x] Dockerfile creates symlink: `/sbin/docker-init` → `/usr/bin/tini`
- [ ] Build container image successfully
- [ ] Verify symlink exists: `docker run --rm IMAGE ls -la /sbin/docker-init`
- [ ] Test tini via original path: `docker run --rm IMAGE /usr/bin/tini --version`
- [ ] Test tini via symlink: `docker run --rm IMAGE /sbin/docker-init --version`
- [ ] Create Docker Buildx builder with custom image
- [ ] Bootstrap builder without errors
- [ ] Run multi-platform build successfully

## Documentation Updates

Update the following files to reference the tini symlink solution:

- [x] `Dockerfile.buildkit-riscv64` - Implementation
- [x] `docs/BUILDKIT-TINI-PATH-SOLUTION.md` - This document
- [x] `.github/workflows/buildkit-weekly-build.yml` - Uses Dockerfile
- [ ] `README.md` - Add BuildKit usage section
- [ ] `BUILDKIT-RISCV64-TODO.md` - Mark tini issue as resolved

## Upstream Contribution Potential

Consider contributing RISC-V64 support to upstream BuildKit:

**Potential PR to moby/buildkit:**
- Add RISC-V64 to supported architectures
- Update Dockerfile to support Debian-based builds
- Document tini path flexibility

**Benefits:**
- Official RISC-V64 support in BuildKit
- Reduced maintenance burden
- Community benefit

**Next Steps:**
1. Verify our BuildKit build works perfectly
2. Create clean upstream-compatible patch
3. Open issue in moby/buildkit for RISC-V64 support
4. Submit PR with Dockerfile improvements

## References

- Tini repository: https://github.com/krallin/tini
- BuildKit Dockerfile: https://github.com/moby/buildkit/blob/master/Dockerfile
- Docker init process: https://docs.docker.com/engine/reference/run/#specify-an-init-process
- Filesystem Hierarchy Standard: https://refspecs.linuxfoundation.org/FHS_3.0/fhs/index.html

## Conclusion

**Symlink creation** (`/sbin/docker-init` → `/usr/bin/tini`) is the optimal solution:

- ✅ Simple and maintainable
- ✅ No source code changes
- ✅ Compatible with Docker/BuildKit expectations
- ✅ Follows project conventions (no submodule edits)
- ✅ Works with both Debian and RPM package layouts
- ✅ Minimal container image overhead

This solution is **implemented** in the BuildKit RISC-V64 Dockerfile and ready for testing.
