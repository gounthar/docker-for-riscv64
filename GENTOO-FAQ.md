# Gentoo Docker RISC-V64 - Frequently Asked Questions

## Why doesn't Gentoo have .deb or .rpm packages?

**Short answer:** Gentoo uses a completely different packaging system called Portage, which uses "ebuilds" instead of binary packages like .deb or .rpm.

### Understanding Gentoo's Packaging Philosophy

**Debian/Ubuntu (.deb) and Fedora/RHEL (.rpm):**
- Use **standalone binary packages** (.deb, .rpm files)
- Packages are downloaded and installed directly with `dpkg` or `rpm`
- Package contains all binaries, dependencies, and installation scripts
- Package manager (apt, dnf) handles dependencies

**Gentoo (Portage):**
- Uses **overlays** containing "ebuilds" (build recipes)
- Ebuilds are shell scripts that describe how to install software
- Traditionally compiles from source (Gentoo's philosophy)
- Package manager (emerge) executes ebuild instructions
- No standalone binary package files needed

### How Our Gentoo Overlay Works

Our overlay provides a **hybrid approach** that respects Gentoo's system while avoiding lengthy compilation:

```
Traditional Gentoo          Our Approach                Other Distros
┌──────────────┐           ┌──────────────┐           ┌──────────────┐
│  Ebuild      │           │  Ebuild      │           │  Binary      │
│  (recipe)    │           │  (recipe)    │           │  Package     │
│              │           │              │           │  (.deb/.rpm) │
│  Downloads   │           │  Downloads   │           │              │
│  source code │           │  pre-built   │           │  Contains    │
│              │           │  binaries    │           │  binaries    │
│  Compiles    │           │              │           │              │
│  (1-2 hours) │           │  Installs    │           │  Installs    │
│              │           │  (seconds)   │           │  (seconds)   │
│  Installs    │           │              │           │              │
└──────────────┘           └──────────────┘           └──────────────┘
```

### What We Provide for Each Distribution

| Distribution | Format | What Users Install | How It Works |
|--------------|--------|-------------------|--------------|
| **Debian/Ubuntu** | `.deb` package | `docker.io_28.5.1_riscv64.deb` | `apt install ./docker.io_*.deb` |
| **Fedora/RHEL** | `.rpm` package | `moby-engine-28.5.1.riscv64.rpm` | `dnf install moby-engine-*.rpm` |
| **Gentoo** | Overlay (ebuilds) | Overlay with ebuilds | `emerge app-containers/docker` |

### Why This Makes Sense

1. **Respects Gentoo's Architecture**
   - Gentoo users expect to use overlays and emerge
   - .deb/.rpm files would be foreign to Gentoo's Portage system

2. **Avoids Lengthy Compilation**
   - Traditional Gentoo: Compiles Docker from source (1-2 hours on RISC-V64)
   - Our approach: Downloads pre-built binaries (seconds)
   - Result: **Gentoo-native packaging with binary speed**

3. **Native Integration**
   - Works with existing Gentoo tools (`emerge`, `eselect`, `equery`)
   - Respects USE flags and dependencies
   - Integrates with systemd or OpenRC services

4. **Proper Dependency Management**
   - Portage tracks all dependencies
   - Can update components independently
   - Gentoo's package database stays consistent

### Example: What Users See

**Debian/Ubuntu users:**
```bash
# Download .deb package
wget https://github.com/.../docker.io_28.5.1_riscv64.deb

# Install standalone package
sudo apt install ./docker.io_28.5.1_riscv64.deb
```

**Gentoo users:**
```bash
# Add overlay (one-time setup)
eselect repository add docker-riscv64 git https://github.com/gounthar/docker-for-riscv64.git

# Install using emerge (Gentoo-native)
emerge -av app-containers/docker

# Portage automatically:
# 1. Reads ebuild
# 2. Downloads pre-built binary from our GitHub releases
# 3. Installs to proper locations
# 4. Sets up services
# 5. Tracks in Portage database
```

### What Our Ebuilds Do

When you run `emerge app-containers/docker`, the ebuild:

1. **Downloads** pre-built binaries from our GitHub releases:
   - Example: `https://github.com/gounthar/docker-for-riscv64/releases/download/v28.5.1-riscv64/dockerd`

2. **Verifies** checksums (via Manifest file)

3. **Installs** to proper Gentoo locations:
   - Binaries → `/usr/bin/`
   - Services → `/usr/lib/systemd/system/` or `/etc/init.d/`
   - Config → `/etc/docker/`

4. **Integrates** with Portage:
   - Tracks installed files
   - Records dependencies
   - Enables `emerge --unmerge` to cleanly remove

5. **Provides** post-install information:
   - Service management commands
   - Configuration tips
   - User group setup

### Binary Source

All pre-built binaries come from the **same GitHub releases** used for .deb/.rpm:

```
Release: v28.5.1-riscv64
├── dockerd                              ← Gentoo ebuilds download these
├── docker-proxy                         ← (same binaries as in .deb/.rpm)
├── containerd
├── runc
├── docker.io_28.5.1_riscv64.deb        ← Debian package
├── moby-engine-28.5.1.riscv64.rpm      ← RPM package
└── containerd-1.7.28.riscv64.rpm       ← RPM package
```

### Key Takeaway

**We don't create .deb/.rpm packages for Gentoo because Gentoo doesn't use them.** Instead, we provide ebuilds that:
- Download the same pre-built RISC-V64 binaries
- Install them in the Gentoo-native way
- Integrate properly with Portage
- Give users the speed of binaries with Gentoo's flexibility

This approach is **idiomatic Gentoo** while avoiding the traditional compilation overhead.

## Frequently Asked Questions

### Q: Why not just provide binary packages for Gentoo?

**A:** Gentoo's Portage system is fundamentally different from apt/dnf. Creating .deb-style binary packages for Gentoo would:
- Bypass Portage's dependency tracking
- Break integration with Gentoo's tools
- Not be the "Gentoo way"

Gentoo has its own binary package format (`.tbz2`), but overlays with ebuilds are the standard distribution method.

### Q: Are these really "pre-built" binaries if Gentoo is source-based?

**A:** Yes! Gentoo's philosophy is *flexibility*, not just compilation. Many Gentoo users use binary packages for large applications. Our approach:
- Provides ebuilds (Gentoo-native)
- Downloads pre-built binaries (practical for RISC-V64)
- Gives users choice: fast installation without sacrificing Gentoo's benefits

### Q: Will this conflict with official Gentoo Docker packages?

**A:** No. Our overlay uses the repository name `docker-riscv64`, while official Gentoo packages use the main repository. Since official Gentoo doesn't support RISC-V64 for Docker yet, there's no conflict.

If Gentoo officially supports RISC-V64 Docker in the future, users can choose:
- Our overlay (pre-built, latest versions)
- Official Gentoo (compiled from source, stable versions)

### Q: How do updates work?

**A:** Updates work through standard Gentoo mechanisms:

```bash
# Sync all overlays (including ours)
emerge --sync

# Update Docker
emerge -u app-containers/docker

# Or update world
emerge -avuDN @world
```

Our UpdateCLI workflow creates PRs when new versions are released, keeping the overlay current.

### Q: Can I see what the ebuild does before installing?

**A:** Absolutely! Ebuilds are transparent:

```bash
# View the ebuild
cat /var/db/repos/docker-riscv64/app-containers/docker/docker-28.5.1.ebuild

# See what files would be installed
emerge -p app-containers/docker

# Verify checksums
ebuild /var/db/repos/docker-riscv64/app-containers/docker/docker-28.5.1.ebuild manifest
```

### Q: What if I want to compile from source anyway?

**A:** Our ebuilds download pre-built binaries, but if you prefer to compile:

1. Clone our main repository
2. Use our build scripts: `make riscv64`
3. This will compile on your RISC-V64 machine (~35-40 minutes)

Or contribute a source-based ebuild to the overlay!

## Summary

| Question | Answer |
|----------|--------|
| Why no .deb/.rpm for Gentoo? | Gentoo uses overlays with ebuilds, not standalone binary packages |
| What do Gentoo users install? | An overlay with ebuilds that download pre-built binaries |
| Is this the "Gentoo way"? | Yes - overlays are the standard distribution method |
| Do binaries come from same releases? | Yes - same RISC-V64 binaries used for .deb/.rpm |
| How long does installation take? | Seconds (downloads binaries, no compilation) |
| Can I update like normal? | Yes - `emerge -u app-containers/docker` |

---

**For more information:**
- Overlay README: `gentoo-overlay/README.md`
- Testing guide: `GENTOO-TESTING.md`
- Phase 2 implementation: `GENTOO-PHASE2-SUMMARY.md`
