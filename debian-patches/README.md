# Debian Patches for RISC-V64

This directory contains patches applied to the upstream Debian docker.io packaging
to adapt it for RISC-V64 pre-built binaries.

## How It Works

1. Debian docker.io source is tracked as a git submodule (`upstream-debian-docker/`)
2. Patches in this directory are applied at build time
3. Patches are numbered for ordering: `001-xxx.patch`, `002-yyy.patch`, etc.

## Patch Series

See `series` file for the order in which patches are applied.

## Creating/Updating Patches

When Debian updates their packaging:
```bash
# Update submodule
git submodule update --remote upstream-debian-docker

# Test if patches still apply cleanly
./scripts/apply-debian-patches.sh

# If conflicts, resolve and regenerate patches
```

## Benefits

- ✅ Automatically get Debian packaging updates
- ✅ Our changes are isolated as patches
- ✅ Easy to see what's RISC-V64-specific
- ✅ Standard Debian approach (quilt-style)
