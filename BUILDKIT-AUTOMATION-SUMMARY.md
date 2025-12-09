# BuildKit RISC-V64 Automation - Summary

**Created:** 2025-12-09
**Status:** Ready for Testing
**Issue:** #207 (Phase 1: Automation Infrastructure)

## Quick Reference

### Files Created

| File | Purpose | Location |
|------|---------|----------|
| `buildkit-weekly-build.yml` | Weekly builds + releases | `.github/workflows/` |
| `track-buildkit-releases.yml` | Auto-detect new releases | `.github/workflows/` |
| `Dockerfile.buildkit-riscv64` | Container image definition | Repository root |
| Registry strategy doc | GHCR vs alternatives | `docs/BUILDKIT-CONTAINER-REGISTRY-STRATEGY.md` |
| Tini solution doc | Path symlink solution | `docs/BUILDKIT-TINI-PATH-SOLUTION.md` |
| Implementation guide | Complete testing guide | `docs/BUILDKIT-IMPLEMENTATION-GUIDE.md` |

### Key Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **Container Registry** | GitHub Container Registry (ghcr.io) | Zero-config auth, free unlimited public images |
| **Tini Path** | Symlink `/sbin/docker-init` → `/usr/bin/tini` | Simple, no patches, Docker-compatible |
| **Build Runner** | `[self-hosted, riscv64]` native | Consistent with project, avoids cross-compilation |
| **Base Image** | `debian:trixie-slim` | Matches project standards, Debian packages available |

### Container Image Details

**Registry:** `ghcr.io/gounthar/buildkit-riscv64`

**Tags:**
- `latest` - Tracks master branch
- `v{VERSION}-riscv64` - Official releases (e.g., `v0.14.0-riscv64`)
- `master-{DATE}` - Development builds (e.g., `master-20251209`)

**Pull Command:**
```bash
docker pull ghcr.io/gounthar/buildkit-riscv64:latest
```

### Quick Start

#### 1. Add Submodule
```bash
git submodule add https://github.com/moby/buildkit.git buildkit
git commit -m "chore: add buildkit submodule"
```

#### 2. Trigger Build
```bash
# Build latest stable
gh workflow run buildkit-weekly-build.yml -f buildkit_ref=v0.14.0

# Build from master
gh workflow run buildkit-weekly-build.yml
```

#### 3. Make Package Public
After first build: https://github.com/users/gounthar/packages/container/buildkit-riscv64/settings
→ Change visibility to "Public"

#### 4. Test Integration
```bash
# Pull image
docker pull ghcr.io/gounthar/buildkit-riscv64:latest

# Create buildx builder
docker buildx create \
  --name riscv-builder \
  --driver docker-container \
  --driver-opt image=ghcr.io/gounthar/buildkit-riscv64:latest \
  --use

# Bootstrap
docker buildx inspect --bootstrap

# Multi-platform build
docker buildx build --platform linux/riscv64,linux/amd64 -t test .
```

### Workflow Schedule

| Workflow | Schedule | Purpose |
|----------|----------|---------|
| `buildkit-weekly-build.yml` | Sunday 06:30 UTC | Weekly master builds |
| `track-buildkit-releases.yml` | Daily 09:00 UTC | Auto-detect new releases |

### Release Format

**Binary Releases:**
- Tag: `buildkit-v{VERSION}-riscv64`
- Assets: `buildkitd`, `buildctl`, `VERSION.txt`, metadata

**Container Images:**
- Registry: `ghcr.io/gounthar/buildkit-riscv64:{TAG}`
- Public access (after first build)

### Tini Integration

**Problem:** BuildKit expects `/sbin/docker-init`, project installs `/usr/bin/tini`

**Solution:** Dockerfile creates symlink
```dockerfile
RUN ln -sf /usr/bin/tini /sbin/docker-init
```

**Entrypoint:**
```dockerfile
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["buildkitd", "--addr", "tcp://0.0.0.0:1234"]
```

### Testing Checklist

Phase 1: Binary Build
- [ ] Trigger workflow
- [ ] Binaries compile
- [ ] Release created
- [ ] `buildkitd --version` works

Phase 2: Container Image
- [ ] Image builds
- [ ] Symlink exists
- [ ] Tini works
- [ ] GHCR push succeeds

Phase 3: Buildx Integration
- [ ] Builder creates
- [ ] Bootstrap succeeds
- [ ] No tini errors
- [ ] Builder runs

Phase 4: Multi-Platform Build
- [ ] RISC-V64 + AMD64 build
- [ ] Images tagged correctly
- [ ] RISC-V64 variant runs

Phase 5: Release Tracking
- [ ] Detects new versions
- [ ] Triggers builds
- [ ] Creates issues

### Next Steps

1. **Immediate:**
   - Add buildkit submodule
   - Trigger first test build
   - Verify binary compilation

2. **Short-term:**
   - Make GHCR package public
   - Test Docker Buildx integration
   - Run multi-platform build test

3. **Future:**
   - Create Debian/RPM packages
   - Add to Gentoo overlay
   - Document in README.md
   - Consider upstream contribution

### Troubleshooting

**Build fails:** Check submodule initialized
```bash
git submodule update --init --depth 1 buildkit
```

**GHCR push fails:** Verify `packages: write` permission in workflow

**Tini error:** Rebuild image with latest Dockerfile
```bash
docker run --rm IMAGE ls -la /sbin/docker-init
```

**Buildx fails:** Check symlink in container
```bash
docker run --rm ghcr.io/gounthar/buildkit-riscv64:latest /sbin/docker-init --version
```

### Documentation Links

- **Full implementation guide:** `docs/BUILDKIT-IMPLEMENTATION-GUIDE.md`
- **Registry strategy:** `docs/BUILDKIT-CONTAINER-REGISTRY-STRATEGY.md`
- **Tini solution:** `docs/BUILDKIT-TINI-PATH-SOLUTION.md`
- **Original TODO:** `BUILDKIT-RISCV64-TODO.md`

### Issue References

- #207 - BuildKit binaries and automation (this work)
- #208 - BuildKit container image
- #209 - BuildKit testing procedures
- #210 - BuildKit CI/CD automation

### Workflow Syntax Validation

Both workflows validated with Python YAML parser:
- ✓ `buildkit-weekly-build.yml` - Valid
- ✓ `track-buildkit-releases.yml` - Valid

### Estimated Timeline

- **Setup:** 15 minutes (add submodule, trigger build)
- **First build:** 10-20 minutes (workflow execution)
- **Testing:** 1-2 hours (all phases)
- **Documentation updates:** 30 minutes
- **Total to production:** 2-3 hours

### Success Criteria

All automation is ready when:
- [x] Workflows created and syntax-valid
- [x] Dockerfile created with tini solution
- [x] Container registry strategy documented
- [x] Implementation guide complete
- [ ] First successful build
- [ ] GHCR package public
- [ ] Docker Buildx integration tested
- [ ] Multi-platform build works

---

**Status:** 5/8 criteria met, ready for testing phase

**Next Action:** Add buildkit submodule and trigger first build

```bash
cd /path/to/docker-for-riscv64
git submodule add https://github.com/moby/buildkit.git buildkit
gh workflow run buildkit-weekly-build.yml -f buildkit_ref=master
```
