# Test Suite for GitHub Actions Workflows and Documentation

This directory contains comprehensive tests for the GitHub Actions workflows and documentation files modified in the current branch.

## Test Files

### 1. `test-github-workflows.bats`
Bats (Bash Automated Testing System) tests for GitHub Actions workflow files:
- **docker-weekly-build.yml**: Tests workflow structure, release creation, heredoc usage
- **track-moby-releases.yml**: Tests issue creation, moby tracking, labels
- **track-runner-releases.yml**: Tests runner tracking, update instructions
- Cross-workflow validation for consistency

### 2. `test-workflow-edge-cases.bats`
Additional Bats tests for edge cases and advanced scenarios:
- Error handling and authentication
- Security validations
- Edge case handling (special characters, escaping)
- Performance considerations
- Compatibility and maintainability checks

### 3. `test_workflow_validation.py`
Python-based comprehensive YAML validation:
- Schema validation
- Trigger configuration testing
- Heredoc usage validation
- Cross-workflow consistency checks
- Specific workflow feature testing

### 4. `test_markdown_validation.py`
Python-based markdown documentation validation:
- Structure validation (headers, code blocks)
- Link validation
- Formatting consistency
- Content-specific tests for RUNNER-SETUP.md

## Running the Tests

### Run All Tests
```bash
./tests/run-all-tests.sh
```

### Run Individual Test Suites

**Bats tests** (requires bats):
```bash
bats tests/test-github-workflows.bats
bats tests/test-workflow-edge-cases.bats
```

**Python tests** (requires Python 3 and PyYAML):
```bash
python3 tests/test_workflow_validation.py
python3 tests/test_markdown_validation.py
```

## Dependencies

### Required
- Python 3.x
- PyYAML: `pip install pyyaml`

### Optional (for Bats tests)
- Bats: `npm install -g bats` or `brew install bats-core`

## Test Coverage

### Changed Files Tested
- `.github/workflows/docker-weekly-build.yml` ✓
- `.github/workflows/track-moby-releases.yml` ✓
- `.github/workflows/track-runner-releases.yml` ✓
- `RUNNER-SETUP.md` ✓

### Test Categories
1. **Structure Tests**: YAML/Markdown structure validity
2. **Content Tests**: Required fields and sections
3. **Format Tests**: Heredoc usage, consistent formatting
4. **Security Tests**: Token handling, input validation
5. **Edge Cases**: Special characters, error handling
6. **Cross-file Tests**: Consistency across workflows
7. **Best Practices**: GitHub Actions and Markdown conventions

## What's Being Tested

### Heredoc Changes (Main Focus)
The primary changes in the workflows involve moving from inline strings to heredocs:
- ✓ Heredoc EOF markers are balanced
- ✓ Using `--notes-file` and `--body-file` instead of inline `--notes` and `--body`
- ✓ Proper heredoc syntax and escaping
- ✓ Markdown formatting within heredocs
- ✓ Variable substitution in heredocs

### Workflow Functionality
- ✓ Proper job definitions and triggers
- ✓ Correct use of GitHub CLI (gh)
- ✓ Authentication with GH_TOKEN
- ✓ Release and issue creation
- ✓ Labels and metadata

### Documentation
- ✓ Removal of Author line from RUNNER-SETUP.md
- ✓ Proper Markdown formatting
- ✓ No trailing whitespace
- ✓ Consistent metadata fields

## Adding New Tests

To add tests for new changes:

1. **For Bats tests**: Add new `@test` blocks to appropriate .bats files
2. **For Python tests**: Add methods to validator classes or create new test functions
3. **Update this README**: Document new test coverage

## Continuous Integration

These tests can be integrated into CI/CD pipelines:

```yaml
- name: Run workflow tests
  run: |
    pip install pyyaml
    python3 tests/test_workflow_validation.py
    python3 tests/test_markdown_validation.py
```

## Test Philosophy

Following the principle of "bias for action", these tests:
- ✓ Cover happy paths and edge cases
- ✓ Validate both structure and content
- ✓ Check for common pitfalls
- ✓ Ensure consistency across files
- ✓ Validate best practices
- ✓ Are maintainable and clearly documented