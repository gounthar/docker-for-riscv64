# Testing on RISC-V64 Hardware

Quick guide for testing the Gentoo overlay on your BananaPi F3 RISC-V64 machine.

## Prerequisites

- RISC-V64 machine (BananaPi F3) at <riscv64-ip-address>
- Docker installed and running
- Git and GitHub CLI configured
- SSH access configured

## Quick Start

### Step 1: Transfer Code to RISC-V64 Machine

```bash
# From development machine (WSL2/x86_64)
cd /path/to/your/docker-dev

# Sync to RISC-V64 machine
rsync -avz --exclude='.git' --exclude='moby' --exclude='compose' \
  . <riscv64-ip-address>:~/docker-for-riscv64/
```

### Step 2: SSH to RISC-V64 Machine

```bash
ssh <riscv64-ip-address>
cd ~/docker-for-riscv64
```

### Step 3: Run Comprehensive Tests

```bash
# Run all tests (including Docker integration)
./testing/run-all-tests.sh

# Expected output: All tests pass
```

### Step 4: If Tests Pass, Trigger Package Builds

```bash
# Dry run first (see what would happen)
./testing/trigger-package-builds.sh --dry-run

# Review output, then actually execute
./testing/trigger-package-builds.sh
```

## What Gets Tested

### Overlay Structure Validation (75 tests)

```bash
./testing/validate-overlay-structure.sh
```

Tests:
- ✓ Overlay directory structure
- ✓ All 6 packages present (containerd, runc, docker-cli, docker-compose, docker, tini)
- ✓ Ebuild syntax validation
- ✓ Metadata XML validation (all have gounthar@gmail.com)
- ✓ Generator scripts present and executable
- ✓ UpdateCLI manifests YAML syntax
- ✓ Documentation completeness

**Result**: 100% pass rate (75/75)

### Comprehensive Test Suite (7 sections)

```bash
./testing/run-all-tests.sh
```

Tests:
1. ✓ Overlay structure validation
2. ✓ Phase 2 binary availability (checks GitHub releases)
3. ✓ Generator scripts execution
4. ✓ Docker integration (containers, networks, volumes, builds)
5. ✓ Ebuild syntax validation
6. ✓ UpdateCLI manifest validation
7. ✓ Documentation completeness

### Docker Integration Tests (Optional)

```bash
# Quick test (~2 minutes)
./scripts/test-gentoo-integration.sh --quick

# Full test with stress tests (~10 minutes)
./scripts/test-gentoo-integration.sh --full
```

### Performance Benchmarks (Optional)

```bash
# Run benchmarks (~5-10 minutes)
./scripts/benchmark-gentoo-docker.sh

# Results saved to: benchmark-results-YYYYMMDD-HHMMSS.txt
```

## Troubleshooting

### Tests Fail on RISC-V64

**Issue**: Architecture detection fails
```bash
# Verify architecture
uname -m  # Should show: riscv64
```

**Issue**: Docker not available
```bash
# Check Docker status
docker info

# If not running
sudo systemctl start docker
sudo systemctl status docker
```

**Issue**: GitHub releases not found
```bash
# Check GitHub authentication
gh auth status

# If not authenticated
gh auth login

# Check releases exist
gh release list --limit 10
```

### Python/YAML Validation Fails

```bash
# Install PyYAML
sudo apt-get install python3-yaml
```

### Generator Scripts Fail

```bash
# Ensure all scripts are executable
chmod +x scripts/*.sh
chmod +x testing/*.sh
chmod +x generate-gentoo-overlay-modular.sh

# Re-run tests
./testing/validate-overlay-structure.sh
```

## Expected Results

### ✅ All Tests Pass

Output should show:
```
🎉 All tests passed! Gentoo overlay is ready for production!

Next steps:
  1. Run ./testing/trigger-package-builds.sh to prepare overlay release
  2. Test on actual Gentoo RISC-V64 system (see GENTOO-TESTING.md)
  3. Announce to Gentoo RISC-V community
```

If this is what you see, proceed with package builds!

### Trigger Package Builds

```bash
# This will:
# 1. Detect latest component versions from GitHub releases
# 2. Regenerate overlay with those versions
# 3. Validate the updated overlay
# 4. Optionally create a GitHub release tag

./testing/trigger-package-builds.sh
```

Expected output:
```
✓ Docker Engine: 28.5.1 (release: v28.5.1-riscv64)
✓ Docker CLI: 28.5.1 (release: cli-v28.5.1-riscv64)
✓ Docker Compose: 2.40.1 (release: compose-v2.40.1-riscv64)
✓ Containerd: 1.7.28
✓ Runc: 1.3.0
✓ Tini: 0.19.0
✓ Overlay regenerated
✓ Overlay validation passed
✓ Gentoo overlay is ready for use!
```

## What Happens After Trigger

1. **Overlay Updated**: Latest component versions installed in overlay
2. **Validation Passed**: All tests confirm overlay integrity
3. **Committed**: Changes committed to git (if on feature branch)
4. **Optional Release**: GitHub release tag created (if you choose)

## User Installation (After Release)

Users can then install with:

```bash
# Add overlay
eselect repository add docker-riscv64 git https://github.com/gounthar/docker-for-riscv64.git

# Sync
emerge --sync docker-riscv64

# Install
emerge -av app-containers/docker
```

## Automation Possibilities

### Cron Job for Nightly Tests

```bash
# On RISC-V64 machine
# Add to crontab: crontab -e
0 2 * * * cd $HOME/docker-for-riscv64 && ./testing/run-all-tests.sh > /tmp/nightly-test-$(date +\%Y\%m\%d).log 2>&1
```

### GitHub Actions (Future)

Could set up self-hosted runner workflow:

```yaml
name: Test Gentoo Overlay
on: [push, pull_request]
jobs:
  test:
    runs-on: self-hosted-riscv64
    steps:
      - uses: actions/checkout@v3
      - name: Run comprehensive tests
        run: ./testing/run-all-tests.sh
```

## Summary

**Local Tests** (WSL2):
```bash
./testing/validate-overlay-structure.sh  # 75/75 ✓
```

**RISC-V64 Tests**:
```bash
./testing/run-all-tests.sh  # All sections ✓
./scripts/test-gentoo-integration.sh --full  # Docker tests ✓
./scripts/benchmark-gentoo-docker.sh  # Performance data
```

**Package Builds**:
```bash
./testing/trigger-package-builds.sh  # Updates overlay ✓
```

**Result**: Production-ready Gentoo overlay for user installation!

---

**Quick Reference**:
- Test scripts: `testing/`
- Integration tests: `scripts/test-gentoo-integration.sh`
- Benchmarks: `scripts/benchmark-gentoo-docker.sh`
- Full guide: `GENTOO-TESTING.md`
- Security: `GENTOO-SECURITY.md`

**Support**: https://github.com/gounthar/docker-for-riscv64/issues
