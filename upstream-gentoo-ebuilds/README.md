# Upstream Gentoo Ebuilds

This directory contains reference copies of official Gentoo ebuilds for Docker and related packages.

## Purpose

These files serve as the **upstream reference** for our RISC-V64 Gentoo overlay. Following the same pattern as `moby/` and `compose/` submodules, we:

1. Keep upstream ebuilds here as reference
2. Use them to understand Gentoo's structure and requirements
3. Generate RISC-V64-optimized ebuilds via `generate-gentoo-overlay.sh`

**Note:** Currently we use **heredoc-based generation** (not patches). See `patches/gentoo/README.md` for details.

## Files

### app-containers/docker/
- `docker-28.4.0.ebuild` - Official Gentoo Docker ebuild (latest with ~riscv keyword)
- `metadata.xml` - Package metadata (USE flags, maintainer info)
- `files/` - Service files (systemd, OpenRC, configs)
  - `docker.service` - systemd unit file
  - `docker.initd` - OpenRC init script
  - `docker.confd` - OpenRC configuration

## Update Process

### Automated (UpdateCLI)

UpdateCLI automatically detects new Gentoo Docker versions and creates PRs:

```yaml
# Configuration: .updatecli/updatecli.d/gentoo-docker-ebuild.yaml
# When triggered:
# 1. Detects latest Docker ebuild in Gentoo repo
# 2. Downloads it to upstream-gentoo-ebuilds/
# 3. Creates PR with the new ebuild
```

### Manual Updates

If needed, you can manually update:

```bash
# Update upstream ebuild
VERSION="28.5.1"
curl -sL "https://raw.githubusercontent.com/gentoo/gentoo/master/app-containers/docker/docker-${VERSION}.ebuild" \
  -o "upstream-gentoo-ebuilds/app-containers/docker/docker-${VERSION}.ebuild"

# Update service files (if Gentoo changed them)
curl -sL "https://gitweb.gentoo.org/repo/gentoo.git/plain/app-containers/docker/files/docker.service" \
  -o "upstream-gentoo-ebuilds/app-containers/docker/files/docker.service"

# Review changes
git diff upstream-gentoo-ebuilds/

# Update generate-gentoo-overlay.sh if needed
# Test generated overlay
./generate-gentoo-overlay.sh ${VERSION}
```

## Source

Official Gentoo repository: https://github.com/gentoo/gentoo

Direct link to Docker package:
https://github.com/gentoo/gentoo/tree/master/app-containers/docker

Web interface:
https://gitweb.gentoo.org/repo/gentoo.git/tree/app-containers/docker

## Why Not a Git Submodule?

The Gentoo repository is **~4GB** - too large for a submodule. Instead, we:
- Download specific ebuild files we need via UpdateCLI
- Track them in version control
- Update automatically when Gentoo releases new versions
- Much lighter and faster than submodule approach

This is similar to how Debian/RPM packaging works in this project:
- Reference upstream package definitions
- Generate our own with pre-built binary modifications
- Keep process simple and maintainable

## Diff from Our Packages

Our RISC-V64 ebuilds differ from upstream:

- **SRC_URI**: Points to our GitHub releases (pre-built binaries)
- **DEPEND**: Removes build-time Go dependencies (go-md2man, etc.)
- **inherit**: Removes `go-module` (no Go compilation needed)
- **src_unpack()**: Skipped (binaries are already built)
- **src_compile()**: Skipped (binaries are pre-built)
- **src_install()**: Simplified (just copy binaries)
- **KEYWORDS**: Focuses on `~riscv`
- **Phase 1**: Bundles containerd/runc (will be split in Phase 2)

## Generation Workflow

1. **Upstream reference** - This directory contains official Gentoo ebuilds
2. **Generation script** - `generate-gentoo-overlay.sh` contains ebuild in heredoc
3. **Overlay output** - `gentoo-overlay/` contains final generated files

The heredoc approach:
- Provides full control over ebuild structure
- Easier to maintain for single-version overlay
- No patch application failures
- Simple to understand and modify

See `patches/gentoo/README.md` for rationale and future patch-based approach.
