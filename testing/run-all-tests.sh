#!/bin/bash
# Comprehensive Test Runner for Gentoo Overlay
# Runs all validation and testing scripts on RISC-V64 machine
#
# Usage: ./testing/run-all-tests.sh [--skip-docker-tests]

set -e

SKIP_DOCKER_TESTS=false
if [[ "$1" == "--skip-docker-tests" ]]; then
    SKIP_DOCKER_TESTS=true
    echo "Skipping Docker integration tests (Docker not required)"
    echo ""
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo_header() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

echo_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

echo_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

echo_fail() {
    echo -e "${RED}[✗]${NC} $1"
}

echo_warn() {
    echo -e "${YELLOW}[!]${NC} $1"
}

cd "$PROJECT_ROOT"

# Test results tracking
declare -A TEST_RESULTS

echo_header "Comprehensive Gentoo Overlay Test Suite"
echo_info "Date: $(date)"
echo_info "Hostname: $(hostname)"
echo_info "Architecture: $(uname -m)"
echo_info "Project Root: $PROJECT_ROOT"
echo ""

# Verify we're on RISC-V64
if [[ "$(uname -m)" != "riscv64" ]]; then
    echo_warn "Not running on RISC-V64 architecture (detected: $(uname -m))"
    echo_warn "Some tests may not be representative"
    echo ""
fi

#
# TEST 1: Overlay Structure Validation
#
echo_header "Test 1: Overlay Structure Validation"
if ./testing/validate-overlay-structure.sh; then
    TEST_RESULTS["overlay_structure"]="PASS"
    echo_success "Overlay structure validation passed"
else
    TEST_RESULTS["overlay_structure"]="FAIL"
    echo_fail "Overlay structure validation failed"
fi
echo ""

#
# TEST 2: Phase 2 Test Suite
#
echo_header "Test 2: Phase 2 Binary Availability"
if [[ -f scripts/test-phase2-on-riscv64.sh ]]; then
    echo_info "Running Phase 2 test suite..."
    if ./scripts/test-phase2-on-riscv64.sh > /tmp/phase2-tests.log 2>&1; then
        TEST_RESULTS["phase2_tests"]="PASS"
        echo_success "Phase 2 tests passed"
        tail -20 /tmp/phase2-tests.log
    else
        TEST_RESULTS["phase2_tests"]="FAIL"
        echo_fail "Phase 2 tests failed"
        tail -50 /tmp/phase2-tests.log
    fi
else
    TEST_RESULTS["phase2_tests"]="SKIP"
    echo_warn "Phase 2 test script not found"
fi
echo ""

#
# TEST 3: Generator Scripts
#
echo_header "Test 3: Generator Scripts Execution"
echo_info "Testing overlay regeneration..."

# Create backup
if [[ -d gentoo-overlay ]]; then
    cp -r gentoo-overlay gentoo-overlay.backup
    echo_info "Created backup: gentoo-overlay.backup/"
fi

# Run generator
if ./generate-gentoo-overlay-modular.sh > /tmp/generator.log 2>&1; then
    TEST_RESULTS["generator"]="PASS"
    echo_success "Overlay regeneration successful"
else
    TEST_RESULTS["generator"]="FAIL"
    echo_fail "Overlay regeneration failed"
    tail -20 /tmp/generator.log
fi

# Restore backup if needed
if [[ -d gentoo-overlay.backup ]]; then
    rm -rf gentoo-overlay
    mv gentoo-overlay.backup gentoo-overlay
    echo_info "Restored original overlay"
fi
echo ""

#
# TEST 4: Docker Integration Tests (if Docker is available)
#
if [[ "$SKIP_DOCKER_TESTS" == "false" ]]; then
    echo_header "Test 4: Docker Integration Tests"

    if command -v docker &> /dev/null && docker info &> /dev/null 2>&1; then
        echo_info "Docker is available, running integration tests..."

        if [[ -f scripts/test-gentoo-integration.sh ]]; then
            # Run quick test
            if ./scripts/test-gentoo-integration.sh --quick > /tmp/docker-integration.log 2>&1; then
                TEST_RESULTS["docker_integration"]="PASS"
                echo_success "Docker integration tests passed"
                tail -20 /tmp/docker-integration.log
            else
                TEST_RESULTS["docker_integration"]="FAIL"
                echo_fail "Docker integration tests failed"
                tail -50 /tmp/docker-integration.log
            fi
        else
            TEST_RESULTS["docker_integration"]="SKIP"
            echo_warn "Docker integration test script not found"
        fi
    else
        TEST_RESULTS["docker_integration"]="SKIP"
        echo_warn "Docker not available, skipping integration tests"
    fi
else
    TEST_RESULTS["docker_integration"]="SKIP"
    echo_info "Docker integration tests skipped (--skip-docker-tests)"
fi
echo ""

#
# TEST 5: Ebuild Syntax Validation
#
echo_header "Test 5: Ebuild Syntax Validation"
EBUILD_ERRORS=0

for ebuild in gentoo-overlay/**/*.ebuild; do
    if [[ -f "$ebuild" ]]; then
        if bash -n "$ebuild" 2>&1; then
            echo_info "$(basename $ebuild): OK"
        else
            echo_fail "$(basename $ebuild): SYNTAX ERROR"
            EBUILD_ERRORS=$((EBUILD_ERRORS + 1))
        fi
    fi
done

if [[ $EBUILD_ERRORS -eq 0 ]]; then
    TEST_RESULTS["ebuild_syntax"]="PASS"
    echo_success "All ebuilds have valid syntax"
else
    TEST_RESULTS["ebuild_syntax"]="FAIL"
    echo_fail "$EBUILD_ERRORS ebuild(s) have syntax errors"
fi
echo ""

#
# TEST 6: UpdateCLI Manifest Validation
#
echo_header "Test 6: UpdateCLI Manifest Validation"

if command -v python3 &> /dev/null; then
    YAML_ERRORS=0

    for manifest in .updatecli.d/gentoo-*.yaml; do
        if [[ -f "$manifest" ]]; then
            if python3 -c "import yaml; yaml.safe_load(open('$manifest'))" 2>&1; then
                echo_info "$(basename $manifest): Valid YAML"
            else
                echo_fail "$(basename $manifest): Invalid YAML"
                YAML_ERRORS=$((YAML_ERRORS + 1))
            fi
        fi
    done

    if [[ $YAML_ERRORS -eq 0 ]]; then
        TEST_RESULTS["updatecli_manifests"]="PASS"
        echo_success "All UpdateCLI manifests are valid"
    else
        TEST_RESULTS["updatecli_manifests"]="FAIL"
        echo_fail "$YAML_ERRORS manifest(s) have YAML errors"
    fi
else
    TEST_RESULTS["updatecli_manifests"]="SKIP"
    echo_warn "Python3 not available, skipping YAML validation"
fi
echo ""

#
# TEST 7: Documentation Completeness
#
echo_header "Test 7: Documentation Completeness"

REQUIRED_DOCS=(
    "README.md"
    "GENTOO-PHASE2-SUMMARY.md"
    "GENTOO-TESTING.md"
    "GENTOO-SECURITY.md"
    "gentoo-overlay/README.md"
)

DOC_MISSING=0
for doc in "${REQUIRED_DOCS[@]}"; do
    if [[ -f "$doc" ]]; then
        echo_info "$(basename $doc): Found"
    else
        echo_fail "$(basename $doc): Missing"
        DOC_MISSING=$((DOC_MISSING + 1))
    fi
done

if [[ $DOC_MISSING -eq 0 ]]; then
    TEST_RESULTS["documentation"]="PASS"
    echo_success "All required documentation is present"
else
    TEST_RESULTS["documentation"]="FAIL"
    echo_fail "$DOC_MISSING required document(s) missing"
fi
echo ""

#
# FINAL SUMMARY
#
echo_header "Test Results Summary"
echo ""

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

for test_name in "${!TEST_RESULTS[@]}"; do
    result="${TEST_RESULTS[$test_name]}"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    case "$result" in
        PASS)
            echo_success "$test_name: PASSED"
            PASSED_TESTS=$((PASSED_TESTS + 1))
            ;;
        FAIL)
            echo_fail "$test_name: FAILED"
            FAILED_TESTS=$((FAILED_TESTS + 1))
            ;;
        SKIP)
            echo_warn "$test_name: SKIPPED"
            SKIPPED_TESTS=$((SKIPPED_TESTS + 1))
            ;;
    esac
done

echo ""
echo_info "Total Tests: $TOTAL_TESTS"
echo_success "Passed: $PASSED_TESTS"
echo_fail "Failed: $FAILED_TESTS"
echo_warn "Skipped: $SKIPPED_TESTS"

if [[ $TOTAL_TESTS -gt 0 && $SKIPPED_TESTS -lt $TOTAL_TESTS ]]; then
    PASS_RATE=$(awk "BEGIN {printf \"%.1f\", ($PASSED_TESTS / ($TOTAL_TESTS - $SKIPPED_TESTS)) * 100}")
    echo_info "Pass Rate: ${PASS_RATE}% (excluding skipped)"
fi

echo ""

if [[ $FAILED_TESTS -eq 0 ]]; then
    echo_success "🎉 All tests passed! Gentoo overlay is ready for production!"
    echo ""
    echo_info "Next steps:"
    echo "  1. Run ./testing/trigger-package-builds.sh to prepare overlay release"
    echo "  2. Test on actual Gentoo RISC-V64 system (see GENTOO-TESTING.md)"
    echo "  3. Announce to Gentoo RISC-V community"
    exit 0
else
    echo_fail "⚠️  Some tests failed. Please review and fix issues before proceeding."
    exit 1
fi
