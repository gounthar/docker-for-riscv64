# Gentoo Phase 2 - Modular Packaging Implementation

## Summary

Phase 2 successfully implements modular Gentoo packaging for Docker RISC-V64, following Gentoo's standard practice of separate packages for each component. This replaces the monolithic Phase 1 approach with a proper dependency-based system.

## What Was Created

### 1. Individual Package Generation Scripts

Located in `scripts/`:
- `generate-containerd-ebuild.sh` - Generates containerd package
- `generate-runc-ebuild.sh` - Generates runc package
- `generate-docker-cli-ebuild.sh` - Generates docker-cli package
- `generate-docker-compose-ebuild.sh` - Generates docker-compose package
- `generate-tini-ebuild.sh` - Generates tini package

Each script:
- Creates proper ebuild structure
- Downloads binaries from appropriate releases
- Includes metadata.xml
- Handles systemd/OpenRC service files
- Provides installation messages

### 2. Master Generation Script

`generate-gentoo-overlay-modular.sh`:
- Orchestrates all individual package generators
- Creates complete overlay structure
- Generates modular Docker ebuild with proper dependencies
- Supports version override via command-line arguments
- Creates comprehensive README for the overlay

### 3. Generated Package Structure

The overlay creates 6 packages:

```
gentoo-overlay/
├── app-containers/
│   ├── containerd/
│   │   ├── containerd-1.7.28.ebuild
│   │   └── metadata.xml
│   ├── runc/
│   │   ├── runc-1.3.0.ebuild
│   │   └── metadata.xml
│   ├── docker-cli/
│   │   ├── docker-cli-28.5.1.ebuild
│   │   └── metadata.xml
│   ├── docker-compose/
│   │   ├── docker-compose-2.40.1.ebuild
│   │   └── metadata.xml
│   └── docker/
│       ├── docker-28.5.1.ebuild
│       ├── metadata.xml
│       └── files/
│           ├── daemon.json
│           ├── docker.service
│           ├── docker.initd
│           └── docker.confd
└── sys-process/
    └── tini/
        ├── tini-0.19.0.ebuild
        └── metadata.xml
```

### 4. Dependency Architecture

The main Docker package now depends on separate packages:

```
app-containers/docker-28.5.1
├── Installs: dockerd, docker-proxy
└── Depends on:
    ├── ~app-containers/containerd-1.7.28
    ├── ~app-containers/runc-1.3.0
    ├── >=app-containers/docker-cli-28.5.1
    └── container-init? ( >=sys-process/tini-0.19.0[static] )
```

Benefits:
- Each component can be updated independently
- Follows Gentoo's packaging philosophy
- Enables granular dependency management
- Users can install only needed components

### 5. UpdateCLI Integration

Created 5 manifests in `.updatecli.d/`:

| Manifest | Tracks | Creates PR for |
|----------|--------|----------------|
| `gentoo-containerd.yaml` | containerd versions from Docker Engine releases | containerd version updates |
| `gentoo-runc.yaml` | runc versions from Docker Engine releases | runc version updates |
| `gentoo-docker-cli.yaml` | Docker CLI release tags | docker-cli version updates |
| `gentoo-docker-compose.yaml` | Docker Compose release tags | docker-compose version updates |
| `gentoo-tini.yaml` | Tini release tags | tini version updates |

Each manifest:
- Monitors appropriate GitHub releases
- Validates binaries exist in releases
- Updates `generate-gentoo-overlay-modular.sh` default versions
- Creates automated PRs with proper labels

### 6. UpdateCLI Workflow

`.github/workflows/updatecli-gentoo.yml`:
- Scheduled: Daily at 08:00 UTC
- Matrix strategy: Runs each manifest separately
- Installs dependencies: UpdateCLI, GitHub CLI
- Can be manually triggered for specific manifests
- Creates PRs with proper labeling (gentoo, component-name, automated)

### 7. Documentation

Updated `CLAUDE.md` with comprehensive Phase 2 section:
- Modular packaging philosophy
- Package generation instructions
- Dependency structure diagram
- Binary source mapping
- UpdateCLI integration details
- Overlay location and structure

## Version Tracking

Current default versions:
- Docker Engine: 28.5.1
- Docker CLI: 28.5.1
- Docker Compose: 2.40.1
- containerd: 1.7.28
- runc: 1.3.0
- tini: 0.19.0

These are extracted from releases:
- containerd, runc: `v{VERSION}-riscv64` (Docker Engine releases)
- docker-cli: `cli-v{VERSION}-riscv64` (Docker CLI releases)
- docker-compose: `compose-v{VERSION}-riscv64` (Compose releases)
- tini: `tini-v{VERSION}-riscv64` (Tini releases)

## Testing the Implementation

### 1. Generate the Overlay

```bash
# With default versions
./generate-gentoo-overlay-modular.sh

# With specific versions
./generate-gentoo-overlay-modular.sh \
  --docker-version 28.5.1 \
  --cli-version 28.5.1 \
  --compose-version 2.40.1 \
  --containerd-version 1.7.28 \
  --runc-version 1.3.0 \
  --tini-version 0.19.0
```

### 2. Verify Generated Structure

```bash
# Count ebuilds (should be 6)
find gentoo-overlay -name "*.ebuild" | wc -l

# List all packages
find gentoo-overlay -name "*.ebuild"

# Verify metadata files
find gentoo-overlay -name "metadata.xml"
```

### 3. Test UpdateCLI Locally (Optional)

```bash
# Test containerd manifest
updatecli diff --config .updatecli.d/gentoo-containerd.yaml

# Test all manifests
for manifest in .updatecli.d/gentoo-*.yaml; do
    echo "Testing $manifest..."
    updatecli diff --config "$manifest"
done
```

### 4. Install on Gentoo System

```bash
# On a Gentoo RISC-V64 system:

# Copy overlay
sudo mkdir -p /var/db/repos/docker-riscv64
sudo cp -r gentoo-overlay/* /var/db/repos/docker-riscv64/

# Sync
emerge --sync docker-riscv64

# Install Docker (pulls in all dependencies)
emerge -av app-containers/docker

# Optional: Install Compose separately
emerge -av app-containers/docker-compose
```

## Migration Path

### From Phase 1 (Monolithic) to Phase 2 (Modular)

Users with Phase 1 installed should:

```bash
# 1. Uninstall old monolithic package
emerge -C =app-containers/docker-28.5.1-r1

# 2. Install new modular package
emerge -av app-containers/docker

# 3. Verify all components installed
equery list app-containers/containerd
equery list app-containers/runc
equery list app-containers/docker-cli
equery list app-containers/docker
```

## Next Steps

1. **Commit Changes**:
   ```bash
   git add scripts/ generate-gentoo-overlay-modular.sh .updatecli.d/ .github/workflows/updatecli-gentoo.yml CLAUDE.md
   git commit -m "feat(gentoo): implement Phase 2 modular packaging with UpdateCLI"
   ```

2. **Push to Remote**:
   ```bash
   git push origin feature/gentoo-phase2-separate-packages
   ```

3. **Create Pull Request**:
   ```bash
   gh pr create --title "feat(gentoo): Phase 2 modular packaging implementation" \
     --body "$(cat <<'EOF'
## Summary

Implements Phase 2 of Gentoo packaging using modular approach with separate packages for each Docker component.

## Architecture

**Modular Packages:**
- app-containers/containerd - Container runtime
- app-containers/runc - OCI runtime
- app-containers/docker-cli - Docker CLI
- app-containers/docker-compose - Compose v2 plugin
- app-containers/docker - Engine daemon (depends on above)
- sys-process/tini - Init process

**Benefits:**
- Follows Gentoo's standard packaging philosophy
- Independent component updates
- Granular dependency management
- Proper separation of concerns

## Implementation Details

**Generation:**
- Individual generators: scripts/generate-*-ebuild.sh
- Master generator: generate-gentoo-overlay-modular.sh
- Generated overlay: gentoo-overlay/

**Automation:**
- UpdateCLI manifests: .updatecli.d/gentoo-*.yaml
- Daily checks: .github/workflows/updatecli-gentoo.yml
- Automated PRs for version updates

**Documentation:**
- Updated CLAUDE.md with Phase 2 section
- Summary: GENTOO-PHASE2-SUMMARY.md
- Overlay README: gentoo-overlay/README.md

## Testing

- ✅ Generated overlay successfully
- ✅ Created 6 ebuilds with proper dependencies
- ✅ UpdateCLI manifests created
- ✅ Workflow configured
- ⏳ Needs testing on actual Gentoo RISC-V64 system

## Migration

Users with Phase 1 monolithic package should:
1. Unmerge old package
2. Emerge new modular Docker package
3. Dependencies will pull in all components automatically

Closes #11 (if Phase 2 was tracked in an issue)
EOF
)"
   ```

4. **Test Workflow**:
   - Wait for workflow to run on schedule (daily 08:00 UTC)
   - Or manually trigger: `gh workflow run updatecli-gentoo.yml`
   - Verify PRs are created when new versions available

5. **Test on Gentoo System**:
   - Deploy overlay to a Gentoo RISC-V64 system
   - Test installation: `emerge -av app-containers/docker`
   - Verify dependencies: `equery depends docker`
   - Test functionality: `docker version`, `docker compose version`

6. **Update Main README** (if needed):
   - Add Gentoo installation instructions for modular packages
   - Document component-specific installation options
   - Add troubleshooting for migration from Phase 1

## Benefits of Phase 2

1. **Modularity**: Each component is a separate package
2. **Flexibility**: Users can install only what they need
3. **Maintainability**: Easier to update individual components
4. **Standards Compliance**: Follows Gentoo packaging best practices
5. **Automation**: UpdateCLI tracks versions automatically
6. **Dependency Management**: Proper Portage dependency tree
7. **Granular Updates**: Update components independently

## Files Created

```
scripts/
├── generate-containerd-ebuild.sh
├── generate-runc-ebuild.sh
├── generate-docker-cli-ebuild.sh
├── generate-docker-compose-ebuild.sh
└── generate-tini-ebuild.sh

.updatecli.d/
├── gentoo-containerd.yaml
├── gentoo-runc.yaml
├── gentoo-docker-cli.yaml
├── gentoo-docker-compose.yaml
└── gentoo-tini.yaml

.github/workflows/
└── updatecli-gentoo.yml

generate-gentoo-overlay-modular.sh
GENTOO-PHASE2-SUMMARY.md (this file)

gentoo-overlay/ (generated)
├── app-containers/
│   ├── containerd/
│   ├── runc/
│   ├── docker-cli/
│   ├── docker-compose/
│   └── docker/
├── sys-process/
│   └── tini/
├── metadata/
├── profiles/
└── README.md
```

## Success Criteria

- ✅ All generation scripts created and executable
- ✅ Master generation script creates complete overlay
- ✅ Modular Docker ebuild with proper dependencies
- ✅ UpdateCLI manifests for all components
- ✅ GitHub Actions workflow for automation
- ✅ Documentation updated (CLAUDE.md)
- ⏳ PR created and merged
- ⏳ Tested on Gentoo RISC-V64 system
- ⏳ Users successfully migrate from Phase 1

---

**Phase 2 Implementation: COMPLETE ✅**

Generated: 2025-11-01
Branch: feature/gentoo-phase2-separate-packages
