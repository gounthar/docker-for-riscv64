# Comprehensive Unit Test Suite

## Overview

This test suite provides thorough coverage for the files changed between `feature/add-riscv64-support` and the current branch (HEAD).

## Files Under Test

Based on `git diff feature/add-riscv64-support..HEAD`:

1. **`.github/workflows/docker-weekly-build.yml`** - Docker build workflow with heredoc refactoring
2. **`.github/workflows/track-moby-releases.yml`** - Moby release tracking with heredoc refactoring  
3. **`.github/workflows/track-runner-releases.yml`** - Runner release tracking with heredoc refactoring
4. **`RUNNER-SETUP.md`** - Documentation with metadata cleanup

## Test Suite Components

### 1. `tests/test-github-workflows.bats`
#### Primary workflow validation tests using Bats

Tests include:
- File existence and readability
- YAML structure validation (name, on, jobs fields)
- Heredoc usage verification (`cat > file << EOF` pattern)
- Correct use of `--notes-file` and `--body-file` flags
- GH_TOKEN environment variable configuration
- Release notes content validation
- Issue creation validation
- Label verification
- Runner configuration (riscv64, ubuntu-latest)
- EOF marker balance checking

**Test Count:** ~24 tests

### 2. `tests/test-workflow-edge-cases.bats`
#### Edge case and security validation using Bats

Tests include:
- Error handling patterns
- File write location safety
- Authentication handling
- Release tag special character handling
- Date format consistency
- Variable substitution in heredocs
- Code block escaping in heredocs
- Relative vs absolute paths
- Secret exposure prevention
- Workflow timeout configuration
- Heredoc size limits
- GitHub Actions version pinning
- Git operation safety
- Markdown formatting in heredocs

**Test Count:** ~20 tests

### 3. `tests/test_workflow_validation.py`
#### Python-based comprehensive YAML validation

Features:
- Custom test runner framework (no external test dependencies)
- YAML parsing and structure validation
- Trigger configuration validation
- Heredoc usage pattern validation
- Workflow-specific feature testing
- Cross-workflow consistency checks

Test functions:
- `test_docker_weekly_build()` - Docker workflow specifics
- `test_track_moby_releases()` - Moby tracking specifics
- `test_track_runner_releases()` - Runner tracking specifics
- `test_cross_workflow_consistency()` - Multi-file validation

**Test Count:** ~40+ assertions

### 4. `tests/test_markdown_validation.py`
#### Python-based markdown documentation validation

Features:
- Structure validation (headers, code blocks)
- Link validation (well-formed URLs, no empty text)
- Consistency checks (header hierarchy, code block tagging)
- Content-specific validation for RUNNER-SETUP.md
- Trailing whitespace detection
- Multiple blank line detection

Validations:
- `validate_structure()` - Headers, code blocks, whitespace
- `validate_links()` - Link format and completeness
- `validate_consistency()` - Formatting uniformity
- `test_runner_setup_md()` - File-specific tests

**Test Count:** ~15+ assertions

### 5. `tests/run-all-tests.sh`
#### Unified test runner script

Features:
- Runs all Bats and Python tests
- Checks for required dependencies
- Provides clear success/failure reporting
- Returns appropriate exit codes

## Key Changes Being Tested

### Primary Change: Heredoc Refactoring

**Before (Inline String):**
```yaml
gh release create "v${DATE}" \
  --notes "Very long
multi-line
content here"
```

**After (Heredoc):**
```yaml
cat > release-notes.md << EOF
Very long
multi-line  
content here
EOF

gh release create "v${DATE}" \
  --notes-file release-notes.md
```

**Tests verify:**
- ✓ Heredoc markers are balanced (EOF opening and closing)
- ✓ Using `--notes-file` / `--body-file` instead of inline strings
- ✓ Proper indentation and escaping
- ✓ Markdown formatting preserved
- ✓ Variable substitution works correctly

### Secondary Change: Documentation Cleanup

**RUNNER-SETUP.md changes:**
- Removed `Author:` field
- Preserved `Last Updated:` and `Hardware:` fields
- Cleaned up trailing whitespace

**Tests verify:**
- ✓ Author field removed
- ✓ Required metadata fields present
- ✓ No trailing whitespace in metadata
- ✓ Markdown structure intact

## Running the Tests

### Prerequisites

```bash
# Required
pip install pyyaml

# Optional (for Bats tests)
npm install -g bats
# OR
brew install bats-core
```

### Execute All Tests

```bash
cd /home/jailuser/git
./tests/run-all-tests.sh
```

### Execute Individual Test Suites

```bash
# Bats tests
bats tests/test-github-workflows.bats
bats tests/test-workflow-edge-cases.bats

# Python tests
python3 tests/test_workflow_validation.py
python3 tests/test_markdown_validation.py
```

### Expected Output