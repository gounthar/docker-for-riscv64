# BuildKit RISC-V64 Implementation Guide

**Created:** 2025-12-09
**Status:** Ready for Testing
**Related Issues:** #207 (binaries), #208 (container), #209 (testing), #210 (automation)

## Overview

This guide documents the complete BuildKit RISC-V64 automation infrastructure created for Phase 1 of Issue #207.

## What Was Created

### 1. GitHub Actions Workflows

#### **buildkit-weekly-build.yml**
Location: `.github/workflows/buildkit-weekly-build.yml`

**Purpose:** Build BuildKit binaries and container image for RISC-V64

**Features:**
- Runs on self-hosted RISC-V64 runner (native compilation)
- Scheduled weekly builds (Sunday 06:30 UTC)
- Manual trigger with configurable BuildKit version
- Builds `buildkitd` and `buildctl` binaries
- Creates BuildKit container image with tini
- Pushes to GitHub Container Registry (ghcr.io)
- Creates GitHub releases with binaries and metadata

**Trigger Options:**
```bash
# Build latest (master)
gh workflow run buildkit-weekly-build.yml

# Build specific version
gh workflow run buildkit-weekly-build.yml -f buildkit_ref=v0.14.0

# Build specific commit
gh workflow run buildkit-weekly-build.yml -f buildkit_ref=abc123
```

**Build Time:** ~10-15 minutes (estimated)

**Outputs:**
- Release: `buildkit-v{VERSION}-riscv64`
- Binaries: `buildkitd`, `buildctl`
- Container: `ghcr.io/gounthar/buildkit-riscv64:{TAG}`
- Metadata: `VERSION.txt`, `IMAGE_TAG.txt`, `REGISTRY.txt`

#### **track-buildkit-releases.yml**
Location: `.github/workflows/track-buildkit-releases.yml`

**Purpose:** Monitor moby/buildkit releases and trigger builds automatically

**Features:**
- Runs daily at 09:00 UTC
- Checks for new BuildKit releases via GitHub API
- Triggers `buildkit-weekly-build.yml` when new version detected
- Creates tracking issue with build status
- Labels: `build-in-progress`, `buildkit-release`

**Manual Trigger:**
```bash
gh workflow run track-buildkit-releases.yml
```

**Tracking Issue Format:**
- Title: "Building BuildKit v{VERSION} for RISC-V64"
- Body includes: monitoring commands, verification checklist
- Auto-closes when build completes

### 2. Container Image Dockerfile

#### **Dockerfile.buildkit-riscv64**
Location: `Dockerfile.buildkit-riscv64`

**Base Image:** `debian:trixie-slim`

**Key Features:**
- Installs tini from Debian repository
- Creates symlink: `/sbin/docker-init` → `/usr/bin/tini` (Docker compatibility)
- Includes runtime dependencies (fuse-overlayfs, iptables, git, ssh)
- Uses tini as entrypoint for proper signal handling
- Exposes port 1234 (BuildKit API)
- Volume mounts for `/var/lib/buildkit` and `/tmp`

**Runtime Dependencies:**
- `ca-certificates` - SSL/TLS certificates
- `fuse-overlayfs` - Rootless overlay filesystem
- `iptables`, `ip6tables` - Network management
- `git` - Git operations in builds
- `openssh-client` - SSH operations
- `pigz` - Parallel gzip compression
- `xz-utils` - XZ compression
- `tini` - Init process manager

**Entrypoint:**
```dockerfile
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["buildkitd", "--addr", "tcp://0.0.0.0:1234"]
```

**Build Command:**
```bash
cd buildkit
docker build \
  --build-arg BUILDKIT_VERSION="$(git describe --tags --always)" \
  -f ../Dockerfile.buildkit-riscv64 \
  -t buildkit:latest \
  .
```

### 3. Documentation

Created comprehensive documentation:

1. **BUILDKIT-CONTAINER-REGISTRY-STRATEGY.md**
   - Evaluated registry options (GHCR, Docker Hub, self-hosted, Quay)
   - Recommended GitHub Container Registry (ghcr.io)
   - Justification: zero-config auth, free unlimited public images, GitHub integration
   - Image naming conventions
   - Multi-architecture future support

2. **BUILDKIT-TINI-PATH-SOLUTION.md**
   - Problem: BuildKit expects tini at `/sbin/docker-init`, we install at `/usr/bin/tini`
   - Solution: Symlink in Dockerfile
   - Evaluated alternatives (copy, patch source, env vars)
   - Testing checklist
   - Troubleshooting guide

3. **BUILDKIT-IMPLEMENTATION-GUIDE.md** (this document)
   - Complete implementation overview
   - Testing procedures
   - Deployment steps
   - Troubleshooting guide

## Architecture Decisions

### Native Compilation Only

**Decision:** All builds run on `[self-hosted, riscv64]` runner

**Rationale:**
- Consistent with project patterns (Docker, Compose, CLI, Buildx, cagent)
- Avoids cross-compilation complexity
- Ensures proper RISC-V64 binary generation
- Simpler workflow configuration

### GitHub Container Registry

**Decision:** Use `ghcr.io/gounthar/buildkit-riscv64` for container images

**Rationale:**
- Automatic authentication via `GITHUB_TOKEN` (no secrets management)
- Unlimited free public images
- Native GitHub integration
- Multi-architecture support for future expansion
- No rate limits for public images

**Alternative:** Docker Hub was considered but rejected due to:
- Rate limits (100-200 pulls/6 hours)
- Requires separate account and token secret
- Less integrated with GitHub Actions

### Tini Path Symlink

**Decision:** Create symlink `/sbin/docker-init` → `/usr/bin/tini`

**Rationale:**
- Simple solution (one line in Dockerfile)
- No source code patches needed
- Compatible with Docker/BuildKit expectations
- Follows project philosophy (no submodule edits)
- Works with both Debian and RPM installations

**Rejected Alternatives:**
- Patch BuildKit source: Violates no-submodule-edit rule
- Copy binary: Wastes space and requires dual maintenance
- Environment variable: BuildKit doesn't support configurable tini path

### Weekly Build Schedule

**Decision:** Sunday 06:30 UTC (after cagent build)

**Rationale:**
- Consistent with other component schedules
- Offset 30 minutes after cagent (Sunday 06:00 UTC)
- Ensures latest BuildKit master is built weekly
- Daily release tracking auto-triggers on new versions

## Implementation Status

### Completed ✅

- [x] Create `buildkit-weekly-build.yml` workflow
- [x] Create `track-buildkit-releases.yml` workflow
- [x] Design `Dockerfile.buildkit-riscv64`
- [x] Document container registry strategy
- [x] Document tini path solution
- [x] Create implementation guide

### Next Steps (Testing Phase)

- [ ] Add BuildKit submodule to repository
- [ ] Trigger first manual build
- [ ] Verify binaries compile successfully
- [ ] Verify container image builds
- [ ] Test GHCR authentication and push
- [ ] Make GHCR package public (manual GitHub UI step)
- [ ] Test unauthenticated image pull
- [ ] Test Docker Buildx integration
- [ ] Run multi-platform build test

### Future Enhancements

- [ ] Create Debian package for BuildKit binaries
- [ ] Create RPM package for BuildKit binaries
- [ ] Add BuildKit to Gentoo overlay
- [ ] Document BuildKit in README.md
- [ ] Create BuildKit testing guide
- [ ] Consider upstream contribution

## Testing Procedures

### Phase 1: Binary Build Test

**Objective:** Verify BuildKit binaries compile natively on RISC-V64

```bash
# Clone repository
cd /path/to/docker-dev

# Add buildkit as submodule (if not exists)
git submodule add https://github.com/moby/buildkit.git buildkit
git submodule update --init --depth 1 buildkit

# Trigger workflow manually
gh workflow run buildkit-weekly-build.yml -f buildkit_ref=master

# Monitor build
gh run watch

# Check release was created
gh release list | grep buildkit

# Download and test binaries
RELEASE=$(gh release list | grep buildkit | head -1 | awk '{print $3}')
gh release download $RELEASE
chmod +x buildkitd buildctl

# Verify versions
./buildkitd --version
./buildctl --version
```

**Expected Results:**
- Binaries compile without errors
- `buildkitd --version` shows version
- `buildctl --version` shows version
- Release created with tag `buildkit-v{DATE}-dev`

### Phase 2: Container Image Test

**Objective:** Verify BuildKit container image builds and runs

```bash
# Pull image from GHCR (after making package public)
docker pull ghcr.io/gounthar/buildkit-riscv64:latest

# Verify tini symlink exists
docker run --rm ghcr.io/gounthar/buildkit-riscv64:latest ls -la /sbin/docker-init

# Test tini via original path
docker run --rm ghcr.io/gounthar/buildkit-riscv64:latest /usr/bin/tini --version

# Test tini via symlink
docker run --rm ghcr.io/gounthar/buildkit-riscv64:latest /sbin/docker-init --version

# Run buildkitd
docker run -d --privileged \
  --name buildkitd-test \
  -v /var/lib/buildkit:/var/lib/buildkit \
  ghcr.io/gounthar/buildkit-riscv64:latest

# Check logs
docker logs buildkitd-test

# Stop and remove
docker stop buildkitd-test
docker rm buildkitd-test
```

**Expected Results:**
- Image pulls successfully
- Symlink `/sbin/docker-init` → `/usr/bin/tini` exists
- Both tini paths work
- BuildKit daemon starts without errors
- No "exec /sbin/docker-init: no such file or directory" errors

### Phase 3: Docker Buildx Integration Test

**Objective:** Verify BuildKit works with Docker Buildx

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

# Check BuildKit container is running
docker ps | grep buildkit
```

**Expected Results:**
- Builder created successfully
- Bootstrap completes without tini errors
- Builder shows as "running" in `docker buildx ls`
- BuildKit container is running

### Phase 4: Multi-Platform Build Test

**Objective:** Verify multi-platform builds work

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

### Phase 5: Release Tracking Test

**Objective:** Verify automatic release detection works

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
- If new version exists, triggers build
- Creates tracking issue
- Issue contains monitoring commands and checklist

## Deployment Steps

### Step 1: Add BuildKit Submodule

```bash
cd /path/to/docker-for-riscv64

# Add submodule
git submodule add https://github.com/moby/buildkit.git buildkit

# Commit
git add .gitmodules buildkit
git commit -m "chore: add buildkit submodule for RISC-V64 support"
```

### Step 2: Trigger First Build

```bash
# Trigger workflow with latest stable release
gh workflow run buildkit-weekly-build.yml -f buildkit_ref=v0.14.0

# Or build from master
gh workflow run buildkit-weekly-build.yml -f buildkit_ref=master
```

### Step 3: Make GHCR Package Public

After first successful build:

1. Navigate to: https://github.com/users/gounthar/packages/container/buildkit-riscv64/settings
2. Change visibility from "Private" to "Public"
3. Confirm the change

This allows unauthenticated pulls:
```bash
docker pull ghcr.io/gounthar/buildkit-riscv64:latest
```

### Step 4: Update Documentation

Add BuildKit section to `README.md`:

```markdown
## Docker Buildx Support

Multi-platform builds are supported via BuildKit for RISC-V64.

**Install BuildKit:**
```bash
docker pull ghcr.io/gounthar/buildkit-riscv64:latest
```

**Create Buildx Builder:**
```bash
docker buildx create \
  --name riscv-builder \
  --driver docker-container \
  --driver-opt image=ghcr.io/gounthar/buildkit-riscv64:latest \
  --use
```

**Build for Multiple Platforms:**
```bash
docker buildx build \
  --platform linux/riscv64,linux/amd64 \
  -t myimage:latest \
  .
```
```

### Step 5: Enable Release Tracking

Release tracking is already configured and will run daily at 09:00 UTC.

No manual action needed - it will automatically:
- Check for new BuildKit releases
- Trigger builds
- Create tracking issues

## Troubleshooting

### Build Failure: Submodule Not Found

**Error:** "buildkit directory not found"

**Solution:**
```bash
git submodule update --init --depth 1 buildkit
```

### Build Failure: Go Compilation Error

**Error:** "cannot find package" or Go build errors

**Solution:**
1. Check Go version matches project standard (1.25.3+)
2. Verify GOARCH=riscv64 is set
3. Check BuildKit version supports RISC-V64

### Container Build Failure: Tini Not Found

**Error:** "tini: command not found"

**Solution:**
Ensure Dockerfile includes:
```dockerfile
RUN apt-get update && apt-get install -y tini
```

### GHCR Push Failure: Authentication

**Error:** "unauthorized: authentication required"

**Solution:**
1. Verify workflow has `packages: write` permission
2. Check `GITHUB_TOKEN` is available in workflow
3. Ensure `gh` CLI is authenticated

### Buildx Failure: Tini Path Error

**Error:** "exec /sbin/docker-init: no such file or directory"

**Solution:**
1. Verify symlink exists in container:
   ```bash
   docker run --rm IMAGE ls -la /sbin/docker-init
   ```
2. Rebuild container image with latest Dockerfile
3. Check Dockerfile includes:
   ```dockerfile
   RUN ln -sf /usr/bin/tini /sbin/docker-init
   ```

### Release Already Exists

**Error:** "release already exists"

**Solution:**
For development builds (`-dev` suffix):
- Workflow automatically deletes and recreates

For official releases:
- Workflow skips creation (intentional)
- Check if release needs updating or version needs incrementing

## Performance Considerations

### Build Time Estimates

- **Binary compilation:** ~5-10 minutes
- **Container image build:** ~2-5 minutes
- **GHCR push:** ~1-3 minutes
- **Total workflow time:** ~10-20 minutes

### Resource Usage

**Self-Hosted Runner (BananaPi F3):**
- CPU: Moderate (Go compilation)
- RAM: ~2-4 GB during build
- Disk: ~500 MB per build (binaries + cache)
- Network: ~100-200 MB (image push)

**Recommendations:**
- Ensure runner has 8+ GB RAM
- Monitor disk space: `/var/lib/docker`
- Clean old images periodically

## Security Considerations

### Container Image Security

**Current:**
- Base image: `debian:trixie-slim` (official Debian)
- Packages from official Debian repository
- No custom PPAs or third-party sources

**Future Enhancements:**
- Implement container image scanning (Trivy)
- Sign images with Cosign
- Regular base image updates
- Vulnerability monitoring

### Secrets Management

**Current:**
- Uses `GITHUB_TOKEN` (automatic, scoped, time-limited)
- No long-lived credentials
- No hardcoded secrets

**Best Practices:**
- Never commit GPG keys or API tokens
- Use GitHub Actions secrets for sensitive data
- Rotate tokens regularly

## Maintenance

### Regular Tasks

**Weekly:**
- Monitor build status (automated via tracking workflow)
- Review build logs for warnings

**Monthly:**
- Update base image to latest Debian release
- Review and merge Dependabot PRs
- Check for BuildKit upstream changes

**Quarterly:**
- Review and update documentation
- Evaluate container registry usage
- Consider upstream contribution

### Monitoring Checklist

- [ ] Weekly builds succeed
- [ ] Release tracking detects new versions
- [ ] Container images push successfully to GHCR
- [ ] No build failures in past month
- [ ] Runner disk space healthy (> 20% free)
- [ ] Runner service running (systemctl status github-runner)

## References

### Created Files

- `.github/workflows/buildkit-weekly-build.yml`
- `.github/workflows/track-buildkit-releases.yml`
- `Dockerfile.buildkit-riscv64`
- `docs/BUILDKIT-CONTAINER-REGISTRY-STRATEGY.md`
- `docs/BUILDKIT-TINI-PATH-SOLUTION.md`
- `docs/BUILDKIT-IMPLEMENTATION-GUIDE.md` (this file)

### External Documentation

- BuildKit: https://github.com/moby/buildkit
- Docker Buildx: https://docs.docker.com/buildx/
- GitHub Container Registry: https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry
- Tini: https://github.com/krallin/tini
- Docker init: https://docs.docker.com/engine/reference/run/#specify-an-init-process

### Related Issues

- #207 - BuildKit binaries (Phase 1: Automation)
- #208 - BuildKit container image
- #209 - BuildKit testing
- #210 - BuildKit automation

## Conclusion

All infrastructure for BuildKit RISC-V64 automation is now in place:

✅ **Workflows Created:**
- Weekly build workflow (native compilation)
- Release tracking workflow (automatic builds)

✅ **Container Image:**
- Production-ready Dockerfile
- Tini integration with symlink solution
- GHCR deployment configured

✅ **Documentation:**
- Container registry strategy
- Tini path solution
- Implementation guide (this document)

**Next Step:** Add BuildKit submodule and trigger first test build.

**Estimated Time to Production:** 1-2 hours (testing and verification)

---

**Implementation completed:** 2025-12-09
**Ready for:** Testing and deployment
**Contact:** See project maintainers in MAINTAINER.md
