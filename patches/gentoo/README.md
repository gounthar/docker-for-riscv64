# Gentoo Ebuild Patches for RISC-V64

This directory contains patches that transform official Gentoo ebuilds into RISC-V64-optimized versions using pre-built binaries.

## Patch Files

### docker-binary.patch
Transforms the standard Gentoo Docker ebuild to use pre-built binaries:

**Changes:**
- Replaces `SRC_URI` to download from our GitHub releases
- Removes build dependencies (go-md2man, etc.)
- Removes `go-module` inherit (no Go compilation needed)
- Simplifies `src_compile()` - skips all compilation
- Updates `src_install()` - just copies pre-built binaries
- Removes containerd/runc as RDEPEND (we bundle them)
- Updates version to match our releases

**Why:** Compiling Docker from source on RISC-V64 takes 1-2 hours. Pre-built binaries install in seconds.

## Applying Patches

Patches are applied automatically by the overlay generation script:

```bash
# Manual application (for testing)
cd upstream-gentoo-ebuilds/app-containers/docker
patch < ../../../patches/gentoo/docker-binary.patch
```

## Creating New Patches

When updating to a new Gentoo ebuild version:

1. Copy upstream ebuild
2. Make necessary modifications
3. Generate patch:
   ```bash
   diff -u docker-28.4.0.ebuild.orig docker-28.5.1.ebuild > patches/gentoo/docker-binary-28.5.1.patch
   ```
4. Test patch application
5. Update overlay generation script

## Patch Maintenance

**When Gentoo updates Docker:**
1. Download new ebuild to `upstream-gentoo-ebuilds/`
2. Test existing patch - may need updates if ebuild structure changed
3. Regenerate patch if needed
4. Test generated overlay works

**UpdateCLI automation:**
- Tracks new Docker versions in Gentoo repo
- Downloads new ebuilds automatically
- Creates PR with updated ebuilds and patches

## Patch Strategy

We maintain **minimal patches** that:
- Keep most of Gentoo's structure (dependencies, kernel checks, etc.)
- Only change what's needed for pre-built binaries
- Make updates easier when Gentoo changes ebuilds

This is similar to how `patches/` handles Moby source modifications.
