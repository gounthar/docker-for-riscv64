# Gentoo Overlay Testing Suite

Comprehensive testing tools for validating the Docker RISC-V64 Gentoo overlay before deployment.

## Overview

This testing suite provides automated validation and testing scripts to ensure the Gentoo overlay is production-ready before triggering package builds or releasing to users.

## Test Scripts

### 1. validate-overlay-structure.sh

**Purpose**: Validates overlay structure without requiring Gentoo installation

**What it tests**:
- Overlay directory structure (metadata, profiles)
- Package structure (all 6 packages)
- Ebuild syntax validation
- Metadata XML validation
- Generator scripts presence and executability
- UpdateCLI manifests YAML syntax
- Documentation completeness

**Usage**:
```bash
./testing/validate-overlay-structure.sh
```

**Requirements**:
- Bash
- Optional: xmllint (for XML validation)
- Optional: python3 + PyYAML (for YAML validation)

**Output**: Test results with pass/fail status and summary statistics

---

### 2. run-all-tests.sh

**Purpose**: Comprehensive test runner that executes all validation and integration tests

**What it tests**:
1. Overlay structure validation
2. Phase 2 binary availability tests
3. Generator script execution
4. Docker integration tests (if Docker available)
5. Ebuild syntax validation
6. UpdateCLI manifest validation
7. Documentation completeness

**Usage**:
```bash
# Full test suite (requires Docker)
./testing/run-all-tests.sh

# Without Docker integration tests
./testing/run-all-tests.sh --skip-docker-tests
```

**Requirements**:
- Bash
- Optional: Docker (for integration tests)
- Optional: python3 + PyYAML (for YAML validation)

**Output**: Comprehensive test report with all results

---

### 3. trigger-package-builds.sh

**Purpose**: Triggers build workflows and prepares overlay for release

**What it does**:
1. Detects latest component versions from GitHub releases
2. Regenerates overlay with latest versions
3. Validates overlay structure
4. Commits changes (if any)
5. Optionally creates GitHub release tag

**Usage**:
```bash
# Dry run (shows what would happen)
./testing/trigger-package-builds.sh --dry-run

# Actually execute
./testing/trigger-package-builds.sh
```

**Requirements**:
- GitHub CLI (`gh`) authenticated
- Git repository with push access
- All validation scripts

**Output**: Updated overlay with latest versions, optional GitHub release

---

## Testing Workflow

### Local Development Testing

Run before committing changes:

```bash
# 1. Validate structure
./testing/validate-overlay-structure.sh

# 2. Run full test suite
./testing/run-all-tests.sh

# 3. If all pass, commit changes
git add gentoo-overlay
git commit -m "chore(gentoo): update overlay"
```

### Pre-Release Testing on RISC-V64

Run on actual RISC-V64 hardware before release:

```bash
# On RISC-V64 machine (192.168.1.185)

# 1. Clone/pull latest code
cd ~/docker-for-riscv64
git pull

# 2. Run comprehensive tests
./testing/run-all-tests.sh

# 3. If Docker is installed, test integration
./scripts/test-gentoo-integration.sh --full

# 4. Run performance benchmarks (optional)
./scripts/benchmark-gentoo-docker.sh

# 5. If all pass, proceed with trigger
./testing/trigger-package-builds.sh
```

### Release Workflow

Complete workflow from testing to release:

```bash
# 1. Ensure on latest main
git checkout main
git pull

# 2. Run local validation
./testing/validate-overlay-structure.sh

# 3. Transfer to RISC-V64 machine and test
scp -r . 192.168.1.185:~/docker-for-riscv64/
ssh 192.168.1.185
cd ~/docker-for-riscv64
./testing/run-all-tests.sh

# 4. If all tests pass, trigger builds
./testing/trigger-package-builds.sh

# 5. Create overlay release tag (optional)
# Script will prompt for this

# 6. Announce to community
# - Update README with test results
# - Post to Gentoo RISC-V forums
# - Create blog post
```

## Test Results Interpretation

### validate-overlay-structure.sh

**All tests pass**: Overlay structure is valid, ready for testing
**Some tests fail**: Fix structural issues before proceeding

Common failures:
- Missing ebuilds: Run generator scripts
- Syntax errors: Fix ebuild code
- Missing metadata: Ensure metadata.xml exists

### run-all-tests.sh

**All tests pass (0 failures)**: Ready for production deployment
**Some tests fail**: Review specific test output and fix issues
**Some tests skip**: Optional dependencies not available (OK if documented)

Test dependencies:
- `overlay_structure`: Must pass
- `phase2_tests`: Should pass (requires GitHub releases)
- `generator`: Must pass
- `docker_integration`: Should pass if Docker available
- `ebuild_syntax`: Must pass
- `updatecli_manifests`: Should pass if python3 available
- `documentation`: Must pass

### trigger-package-builds.sh

**Success**: Overlay updated and ready for user installation
**Failure**: Check error messages for specific issues

Common issues:
- No releases found: Ensure binaries have been built first
- Validation fails: Run validate-overlay-structure.sh first
- Git errors: Check repository permissions

## Running Tests on Different Systems

### On Developer Machine (WSL2/x86_64)

```bash
# Structure validation only (no architecture-specific tests)
./testing/validate-overlay-structure.sh

# Syntax validation
bash -n gentoo-overlay/**/*.ebuild
```

### On RISC-V64 Hardware

```bash
# Full test suite
./testing/run-all-tests.sh

# With Docker integration
docker info && ./testing/run-all-tests.sh

# Performance benchmarking
./scripts/benchmark-gentoo-docker.sh
```

### In CI/CD Pipeline

```yaml
# Example GitHub Actions workflow
jobs:
  test:
    runs-on: self-hosted-riscv64
    steps:
      - uses: actions/checkout@v3
      - name: Validate overlay structure
        run: ./testing/validate-overlay-structure.sh
      - name: Run comprehensive tests
        run: ./testing/run-all-tests.sh
```

## Test Coverage

### What's Tested

✅ **Overlay Structure**:
- Directory hierarchy
- Required files (metadata, profiles)
- Package organization

✅ **Package Integrity**:
- All 6 packages present
- Ebuilds exist and have valid syntax
- Metadata XML is well-formed
- Correct maintainer email

✅ **Generator Scripts**:
- All generators present and executable
- Can regenerate overlay successfully
- Correct email in generated files

✅ **Build Artifacts**:
- Binary availability in GitHub releases
- Correct versions in ebuilds
- Download URLs are valid

✅ **Documentation**:
- All required docs present
- Testing guides complete
- Security documentation

✅ **Docker Integration** (if available):
- Container operations
- Network/volume functionality
- Compose integration
- Package verification

### What's NOT Tested

❌ **Actual Gentoo Installation**: Requires real Gentoo system
❌ **Package Manager Integration**: Requires Portage/emerge
❌ **Runtime Behavior**: Requires installed packages
❌ **Performance on Production**: Requires production workloads

These require manual testing following GENTOO-TESTING.md.

## Troubleshooting

### Test Failures

**Overlay structure validation fails**:
```bash
# Regenerate overlay
./generate-gentoo-overlay-modular.sh

# Re-run validation
./testing/validate-overlay-structure.sh
```

**Python/YAML errors**:
```bash
# Install PyYAML
apt-get install python3-yaml  # Debian/Ubuntu
emerge -av dev-python/pyyaml  # Gentoo
```

**Docker integration tests fail**:
```bash
# Check Docker is running
docker info

# Run Docker-specific tests
./scripts/test-gentoo-integration.sh --quick
```

### Common Issues

**Issue**: "No releases found"
**Solution**: Build binaries first with weekly build workflows

**Issue**: "Git permission denied"
**Solution**: Ensure SSH keys are configured for GitHub

**Issue**: "Architecture not RISC-V64"
**Solution**: Run architecture-specific tests only on RISC-V64 hardware

## Best Practices

1. **Always validate locally first**: Run validate-overlay-structure.sh before pushing
2. **Test on actual hardware**: Use RISC-V64 machine for integration tests
3. **Review test logs**: Check /tmp/*.log files for detailed output
4. **Use dry-run first**: Test trigger scripts with --dry-run before executing
5. **Document failures**: Create issues for any persistent test failures
6. **Keep tests fast**: Quick validation should take <30 seconds
7. **Monitor releases**: Ensure binary releases exist before triggering package builds

## Test Automation

### Pre-commit Hook

```bash
# .git/hooks/pre-commit
#!/bin/bash
if [[ -f testing/validate-overlay-structure.sh ]]; then
    echo "Running overlay validation..."
    ./testing/validate-overlay-structure.sh || exit 1
fi
```

### Cron Job for Nightly Tests

```bash
# Run nightly on RISC-V64 machine
0 2 * * * cd /home/user/docker-for-riscv64 && ./testing/run-all-tests.sh > /tmp/nightly-test-$(date +\%Y\%m\%d).log 2>&1
```

## Contributing

When adding new features:

1. Update relevant test scripts
2. Add test cases for new functionality
3. Ensure all tests pass before submitting PR
4. Document new test requirements

## References

- **Main Testing Guide**: `../TESTING-RISC-V64.md`
- **Security Guide**: `../GENTOO-SECURITY.md`
- **Phase 2 Summary**: `../GENTOO-PHASE2-SUMMARY.md`
- **Integration Tests**: `../scripts/test-gentoo-integration.sh`
- **Benchmarks**: `../scripts/benchmark-gentoo-docker.sh`

---

**Last Updated**: 2025-11-01
**Maintainer**: gounthar@gmail.com
