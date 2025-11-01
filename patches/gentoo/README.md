# Gentoo Ebuild Modifications for RISC-V64

This directory is reserved for future patches to official Gentoo ebuilds for RISC-V64 optimization.

## Current Approach: Heredoc-Based Generation

**Note:** Currently, we do NOT use patches. The ebuild is generated using a heredoc in `generate-gentoo-overlay.sh`.

**Why heredoc instead of patches:**
- Simpler for initial implementation
- Full control over ebuild structure
- Easier to maintain for single-version overlay
- No patch failures when upstream structure changes

**How it works:**
1. `generate-gentoo-overlay.sh` contains the entire ebuild in a heredoc
2. Script generates the ebuild directly
3. Modifications for pre-built binaries are embedded in the heredoc

**Key modifications from upstream Gentoo ebuild:**
- Replaces `SRC_URI` to download from our GitHub releases
- Removes build dependencies (go-md2man, etc.)
- Removes `go-module` inherit (no Go compilation needed)
- Simplifies `src_compile()` - skips all compilation
- Updates `src_install()` - just copies pre-built binaries
- Currently bundles containerd/runc (Phase 1 - will be split in Phase 2)

## Future: Patch-Based Approach

As the overlay matures and needs to support multiple versions, we may transition to a patch-based approach:

### Potential patch files:
- `docker-binary.patch` - Transform upstream ebuild to use pre-built binaries

### Applying patches (future):
```bash
# Manual application (for testing)
cd upstream-gentoo-ebuilds/app-containers/docker
patch < ../../../patches/gentoo/docker-binary.patch
```

### Creating patches (future):
When updating to a new Gentoo ebuild version:

1. Copy upstream ebuild
2. Make necessary modifications
3. Generate patch:
   ```bash
   diff -u docker-28.4.0.ebuild.orig docker-28.5.1-r1.ebuild > patches/gentoo/docker-binary.patch
   ```
4. Test patch application
5. Update overlay generation script to apply patch

## UpdateCLI Automation

**Current status:**
- UpdateCLI tracks new Docker versions in Gentoo repo
- Downloads new ebuilds to `upstream-gentoo-ebuilds/` automatically
- Creates PRs with updated ebuilds
- Manual regeneration of overlay required after PR merge

**Implementation:** `.updatecli/updatecli.d/gentoo-docker-ebuild.yaml`

## Maintenance Workflow

**When Gentoo updates Docker:**
1. UpdateCLI detects new version and creates PR
2. Review upstream ebuild changes
3. Update `generate-gentoo-overlay.sh` heredoc if needed
4. Test generated overlay
5. Merge PR and regenerate overlay

**Why this approach:**
- Minimal maintenance overhead for single-package overlay
- Easy to understand the full ebuild structure
- No patch conflicts when upstream changes
- Transition to patches when supporting multiple versions

This is similar to how we handle other distributions (Debian, RPM) - use upstream as reference, generate our own packaging with modifications.
