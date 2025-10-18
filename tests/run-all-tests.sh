#!/usr/bin/env bash

set -euo pipefail

echo "========================================"
echo "Running All Test Suites"
echo "========================================"

cd /home/jailuser/git

EXIT_CODE=0

# Run Bats tests if available
if command -v bats >/dev/null 2>&1; then
    echo ""
    echo "Running Bats tests..."
    echo "----------------------------------------"
    bats tests/test-github-workflows.bats || EXIT_CODE=1
    bats tests/test-workflow-edge-cases.bats || EXIT_CODE=1
else
    echo ""
    echo "WARNING: bats not installed, skipping Bats tests"
    echo "Install with: npm install -g bats"
fi

# Run Python tests
if command -v python3 >/dev/null 2>&1; then
    echo ""
    echo "Running Python workflow validation tests..."
    echo "----------------------------------------"
    python3 tests/test_workflow_validation.py || EXIT_CODE=1
    
    echo ""
    echo "Running Python markdown validation tests..."
    echo "----------------------------------------"
    python3 tests/test_markdown_validation.py || EXIT_CODE=1
else
    echo ""
    echo "ERROR: python3 not installed, cannot run Python tests"
    EXIT_CODE=1
fi

echo ""
echo "========================================"
if [ $EXIT_CODE -eq 0 ]; then
    echo "✓ All tests passed!"
else
    echo "✗ Some tests failed"
fi
echo "========================================"

exit $EXIT_CODE