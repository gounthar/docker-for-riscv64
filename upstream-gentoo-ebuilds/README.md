# Upstream Gentoo Ebuilds

This directory contains reference copies of official Gentoo ebuilds for Docker and related packages.

## Purpose

These files serve as the **upstream base** for our RISC-V64 Gentoo overlay. Following the same pattern as `moby/` and `compose/` submodules, we:

1. Keep upstream ebuilds here as reference
2. Create patches in `patches/gentoo/` directory
3. Apply patches to generate RISC-V64-optimized ebuilds

## Files

### app-containers/docker/
- `docker-28.4.0.ebuild` - Official Gentoo Docker ebuild (latest with ~riscv keyword)
- `metadata.xml` - Package metadata
- `files/` - Service files (systemd, OpenRC, configs)

## Update Process

When Gentoo updates their Docker package:

```bash
# Update upstream ebuild
curl -sL https://raw.githubusercontent.com/gentoo/gentoo/master/app-containers/docker/docker-X.Y.Z.ebuild \
  -o upstream-gentoo-ebuilds/app-containers/docker/docker-X.Y.Z.ebuild

# Review changes
git diff upstream-gentoo-ebuilds/

# Update patches if needed
# See patches/gentoo/README.md
```

## Source

Official Gentoo repository: https://github.com/gentoo/gentoo

Direct link to Docker package:
https://github.com/gentoo/gentoo/tree/master/app-containers/docker

## Why Not a Git Submodule?

The Gentoo repository is **~4GB** - too large for a submodule. Instead, we:
- Download specific ebuild files we need
- Track them in version control
- Update manually when Gentoo releases new versions
- Much lighter and faster than submodule approach

## Diff from Our Packages

Our RISC-V64 ebuilds differ from upstream:

- **SRC_URI**: Points to our GitHub releases (pre-built binaries)
- **DEPEND**: Removes build-time Go dependencies
- **src_compile()**: Skipped (binaries are pre-built)
- **src_install()**: Simplified (just copy binaries)
- **KEYWORDS**: Focuses on `~riscv`

See `patches/gentoo/` for the exact transformations.
