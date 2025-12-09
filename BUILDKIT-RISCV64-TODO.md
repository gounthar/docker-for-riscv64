# BuildKit for RISC-V64 - Implementation Guide

**Status:** Not yet implemented
**Priority:** Medium (enables Docker Buildx multi-platform builds)
**Complexity:** Medium (Go-based, should compile cleanly)

## Problem Statement

Docker Buildx requires BuildKit to function. The official `moby/buildkit:buildx-stable-1` container image does not have proper RISC-V64 support, resulting in the error:

```
exec /sbin/docker-init: no such file or directory
```

This prevents users from running multi-platform builds with `docker buildx build --platform linux/riscv64,linux/amd64,...`

## Current Situation

### What Works
- ✅ Tini v0.19.0 is installed and available at `/usr/bin/tini` on BananaPi F3
- ✅ Docker v29 works perfectly on RISC-V64
- ✅ Docker Buildx binary (v0.19+) is built and packaged for RISC-V64
- ✅ Go 1.25.3 compiles native RISC-V64 binaries without issues

### What Doesn't Work
- ❌ BuildKit container image lacks RISC-V64 support
- ❌ `docker buildx create` fails when trying to bootstrap the builder
- ❌ Multi-platform builds cannot be performed from RISC-V64

## Goal

Build a RISC-V64 version of the BuildKit container image and integrate it into the docker-for-riscv64 automation pipeline.

## BuildKit Information

**Source Repository:** https://github.com/moby/buildkit
**Language:** Go
**License:** Apache 2.0
**Latest Release:** Check https://github.com/moby/buildkit/releases

**Key Components:**
- `buildkitd` - The BuildKit daemon (server)
- `buildctl` - BuildKit CLI client
- Container image with both binaries + tini

## Implementation Approach

### Phase 1: Build BuildKit Binaries

1. **Clone BuildKit repository:**
   ```bash
   cd /path/to/workspace
   git clone https://github.com/moby/buildkit.git
   cd buildkit
   git checkout <latest-release-tag>  # e.g., v0.14.0
   ```

2. **Build for RISC-V64:**
   ```bash
   # BuildKit uses make and Go
   GOOS=linux GOARCH=riscv64 make
   # OR
   GOOS=linux GOARCH=riscv64 make buildkitd buildctl
   ```

3. **Verify binaries:**
   ```bash
   file bin/buildkitd
   file bin/buildctl
   ./bin/buildkitd --version
   ./bin/buildctl --version
   ```

### Phase 2: Create Container Image

1. **Create Dockerfile for RISC-V64:**

   Reference the official BuildKit Dockerfile:
   https://github.com/moby/buildkit/blob/master/Dockerfile

   Key requirements:
   - Base on Alpine Linux riscv64 or Debian trixie riscv64
   - Include tini (already available as `/usr/bin/tini`)
   - Copy buildkitd and buildctl binaries
   - Set up proper entrypoint with tini

2. **Build container image:**
   ```bash
   docker build -t buildkit:riscv64 -f Dockerfile.riscv64 .
   ```

3. **Tag for compatibility:**
   ```bash
   docker tag buildkit:riscv64 moby/buildkit:buildx-stable-1
   ```

### Phase 3: Test BuildKit

1. **Test standalone buildkitd:**
   ```bash
   # Start buildkitd in a container
   docker run -d --privileged \
     --name buildkitd \
     -v /var/lib/buildkit:/var/lib/buildkit \
     buildkit:riscv64

   # Check it's running
   docker logs buildkitd
   ```

2. **Test with Docker Buildx:**
   ```bash
   # Remove any failed builders
   docker buildx rm riscv-builder || true

   # Create new builder using our buildkit image
   docker buildx create --name riscv-builder --use

   # Bootstrap and inspect
   docker buildx inspect --bootstrap

   # Should show available platforms
   ```

3. **Test multi-platform build:**
   ```bash
   cd /path/to/test-app

   # Try building for multiple platforms
   docker buildx build \
     --platform linux/riscv64,linux/amd64 \
     -t test-multiarch:latest \
     .
   ```

### Phase 4: Automation Integration

Follow the existing patterns in this repository:

1. **Create workflow:** `.github/workflows/buildkit-weekly-build.yml`
   - Similar to `docker-weekly-build.yml`
   - Runs on `[self-hosted, riscv64]`
   - Builds BuildKit from source
   - Creates container image
   - Publishes to GitHub Container Registry (ghcr.io)

2. **Create release tracking:** `.github/workflows/track-buildkit-releases.yml`
   - Similar to `track-moby-releases.yml`
   - Checks for new BuildKit releases daily
   - Triggers automatic builds

3. **Update documentation:**
   - Add BuildKit to README.md components list
   - Update installation instructions
   - Add to blog post

## References

### Existing Patterns in This Repository

| Pattern | Reference File | Use For |
|---------|----------------|---------|
| Weekly builds | `docker-weekly-build.yml` | BuildKit build workflow |
| Release tracking | `track-moby-releases.yml` | BuildKit release monitoring |
| Binary extraction | `build-docker-riscv64.sh` | Extracting buildkitd/buildctl |
| Container packaging | Moby Dockerfile patterns | BuildKit container image |

### BuildKit Documentation

- Official docs: https://github.com/moby/buildkit/blob/master/README.md
- Building from source: https://github.com/moby/buildkit/blob/master/docs/dev/dev-env.md
- Dockerfile reference: https://github.com/moby/buildkit/blob/master/Dockerfile

### Docker Buildx Integration

- Buildx documentation: https://docs.docker.com/build/buildx/
- Custom builder drivers: https://docs.docker.com/build/drivers/

## Success Criteria

- [ ] BuildKit binaries compile cleanly for RISC-V64
- [ ] `buildkitd --version` shows correct version
- [ ] Container image builds successfully with tini
- [ ] `docker buildx create` completes without errors
- [ ] `docker buildx inspect --bootstrap` shows builder is running
- [ ] Multi-platform build succeeds: `--platform linux/riscv64,linux/amd64`
- [ ] Automated workflow triggers on new BuildKit releases
- [ ] Documentation updated with BuildKit support

## Known Challenges

1. **Tini Path:** Official BuildKit expects tini at `/sbin/docker-init`. We have it at `/usr/bin/tini`. May need to:
   - Create symlink in container image
   - OR patch BuildKit to look in multiple locations
   - OR copy tini to expected location

2. **Container Privileges:** BuildKit requires privileged mode or specific capabilities. Ensure runner has proper permissions.

3. **Storage:** BuildKit manages its own cache. May need to configure storage paths for RISC-V runner.

## Testing Checklist

After implementation, verify:

```bash
# 1. Binary works
buildkitd --version

# 2. Container runs
docker run --rm buildkit:riscv64 buildkitd --version

# 3. Buildx integration
docker buildx create --name test-builder --use
docker buildx inspect --bootstrap

# 4. Multi-platform build
cd demo/examples/buildx-demo
docker buildx build --platform linux/riscv64,linux/amd64 -t test .

# 5. Cleanup
docker buildx rm test-builder
```

## Timeline Estimate

- **Phase 1 (Build binaries):** 1-2 hours
- **Phase 2 (Container image):** 2-3 hours (includes tini path debugging)
- **Phase 3 (Testing):** 1-2 hours
- **Phase 4 (Automation):** 2-3 hours

**Total: 6-10 hours** of focused work

## Questions for Implementation

1. Should we build from latest release or track specific versions?
2. Should we publish to ghcr.io or keep images local?
3. Do we want to contribute RISC-V support upstream to moby/buildkit?
4. Should we add BuildKit to the APT/RPM repositories as standalone packages?

## Related Issues

- BuildKit issue tracker: https://github.com/moby/buildkit/issues
- Search for RISC-V: https://github.com/moby/buildkit/issues?q=riscv

## Next Steps

1. Clone BuildKit repository
2. Attempt native RISC-V64 build
3. Debug any compilation issues
4. Create minimal Dockerfile
5. Test standalone
6. Test with Docker Buildx
7. Automate if successful

---

**Created:** 2025-12-09
**Repository:** https://github.com/gounthar/docker-for-riscv64
**For:** Future Claude session or human contributor

## Notes for AI Assistant

When implementing this:
- Check the latest BuildKit release version first
- Review the official Dockerfile structure before creating custom one
- Test incrementally - binary build → container → buildx integration
- Follow existing patterns in `.github/workflows/` directory
- Update this document with findings and any necessary adjustments
