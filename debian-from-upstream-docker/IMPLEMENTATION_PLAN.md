# Implementation Plan: Debian-Based Packaging

## Goal

Refactor our packaging to use the official Debian docker.io source as a base, adapting it to use our pre-built RISC-V64 binaries instead of building from Go source.

## Benefits

- ✅ All Debian policy compliance built-in
- ✅ Proper maintainer scripts (postinst, postrm, prerm)
- ✅ Better integration with Debian ecosystem
- ✅ Easier to track Debian changes
- ✅ More maintainable long-term

## Current Status

### Completed
- [x] Created issue #12
- [x] Created feature branch `feat/debian-source-base`
- [x] Copied official Debian source from https://salsa.debian.org/docker-team/docker
- [x] Analyzed Debian build process

### In Progress
- [ ] Adapt debian/rules for pre-built binaries
- [ ] Update debian/control for RISC-V64
- [ ] Modify debian/*.install files
- [ ] Test local build
- [ ] Update CI workflow

## Implementation Steps

### Phase 1: Simplify debian/rules

**Goal**: Replace Go build process with binary installation

**Current**: Debian builds from Go source using complex Makefiles
**Target**: Install pre-built binaries directly

**Changes needed**:
```makefile
# Remove:
- GOPATH setup
- Go build commands
- Engine/CLI compilation

# Keep:
- dh $@ command structure
- dh_installsystemd
- dh_installinit
- dh_apparmor
- maintainer script integration

# Add:
- Binary download/copy step
- Simplified dh_install
```

### Phase 2: Update debian/control

**Changes**:
- Architecture: riscv64 (currently: any)
- Remove Go build dependencies
- Keep runtime dependencies
- Add Pre-Depends: init-system-helpers
- Update version strings

### Phase 3: Modify install files

**debian/docker.io.install**:
```
# Current: _build/bin/dockerd usr/sbin/
# Target:  dockerd usr/bin/
#          docker-proxy usr/bin/
```

**debian/docker.io.links**:
```
# Change: /usr/bin/tini-static -> /usr/bin/docker-init
# To:     /usr/bin/tini -> /usr/bin/docker-init
```

### Phase 4: Handle symlinks

Debian source has symlinks to `../engine/contrib/`:
- docker.service
- docker.socket
- docker.udev

**Solution**: Copy actual files from our debian-docker/ or create them

### Phase 5: Update changelog

Merge our changelog entries with Debian format:
- Keep Debian's detailed history
- Add our RISC-V64 entries
- Maintain proper version ordering

### Phase 6: Test build

```bash
# Download pre-built binaries
gh release download v28.5.1-riscv64 -p "dockerd" -p "docker-proxy"

# Build package
dpkg-buildpackage -us -uc -b

# Test install
sudo dpkg -i ../docker.io_*.deb
```

### Phase 7: Update workflow

Modify `.github/workflows/build-versioned-packages.yml`:
- Use debian-from-upstream-docker/ instead of debian-docker/
- Keep binary download step
- Keep parallel build approach
- Update file paths

## Testing Plan

1. **Local build test**: Verify package builds without errors
2. **Installation test**: Install on clean system
3. **Service test**: Verify docker.socket and docker.service auto-enable
4. **Functionality test**: Run `docker run hello-world`
5. **Upgrade test**: Upgrade from v28.5.1-3 to new version
6. **Lintian test**: Check for packaging issues

## Rollout Plan

1. Complete implementation on `feat/debian-source-base` branch
2. Test thoroughly on BananaPi F3
3. Create PR to main
4. Build v28.5.1-4 with new approach
5. Update APT repository
6. Document changes in README

## References

- Issue: #12
- Debian source: https://salsa.debian.org/docker-team/docker
- Debian policy: https://www.debian.org/doc/debian-policy/
- Our current approach: debian-docker/, debian-containerd/, debian-runc/

## Questions to Answer

1. Should we keep the contrib scripts (dockerd-rootless.sh, etc.)?
2. Do we need the udev rules?
3. Should we include apparmor profile?
4. What about the docker-doc package?

## Timeline

- Phase 1-3: 1-2 hours (simplify rules, update control/install)
- Phase 4-5: 30 min (handle symlinks, changelog)
- Phase 6: 30 min (local testing)
- Phase 7: 1 hour (update workflow)
- Testing: 1-2 hours

**Total estimated**: 4-6 hours of focused work
