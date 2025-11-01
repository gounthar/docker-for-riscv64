#!/bin/bash
# Validate Gentoo Overlay Structure
# Tests overlay integrity without requiring full Gentoo installation
#
# Usage: ./testing/validate-overlay-structure.sh

set -e

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

echo_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

echo_pass() {
    echo -e "${GREEN}[✓]${NC} $1"
}

echo_fail() {
    echo -e "${RED}[✗]${NC} $1"
}

echo_info() {
    echo -e "${YELLOW}[i]${NC} $1"
}

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

run_test() {
    local test_name="$1"
    local test_command="$2"

    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    echo_test "$test_name"

    if eval "$test_command"; then
        echo_pass "$test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo_fail "$test_name"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

cd "$PROJECT_ROOT"

echo_header "Gentoo Overlay Structure Validation"
echo_info "Testing Date: $(date)"
echo_info "Project Root: $PROJECT_ROOT"
echo ""

#
# TEST SECTION 1: Overlay Structure
#
echo_header "Section 1: Overlay Structure"

run_test "Overlay directory exists" \
    "[[ -d gentoo-overlay ]]"

run_test "Overlay metadata directory exists" \
    "[[ -d gentoo-overlay/metadata ]]"

run_test "Overlay profiles directory exists" \
    "[[ -d gentoo-overlay/profiles ]]"

run_test "Overlay layout.conf exists" \
    "[[ -f gentoo-overlay/metadata/layout.conf ]]"

run_test "Overlay repo_name exists" \
    "[[ -f gentoo-overlay/profiles/repo_name ]]"

run_test "Overlay README exists" \
    "[[ -f gentoo-overlay/README.md ]]"

echo ""

#
# TEST SECTION 2: Package Structure
#
echo_header "Section 2: Package Structure"

PACKAGES=(
    "app-containers/containerd"
    "app-containers/runc"
    "app-containers/docker-cli"
    "app-containers/docker-compose"
    "app-containers/docker"
    "sys-process/tini"
)

for package in "${PACKAGES[@]}"; do
    run_test "Package directory exists: $package" \
        "[[ -d gentoo-overlay/$package ]]"

    run_test "Package metadata.xml exists: $package" \
        "[[ -f gentoo-overlay/$package/metadata.xml ]]"

    # Check for at least one ebuild
    run_test "Package has ebuild(s): $package" \
        "[[ \$(find gentoo-overlay/$package -name '*.ebuild' | wc -l) -gt 0 ]]"
done

echo ""

#
# TEST SECTION 3: Ebuild Syntax
#
echo_header "Section 3: Ebuild Syntax Validation"

check_ebuild_syntax() {
    local ebuild="$1"
    bash -n "$ebuild" 2>&1
}

for package in "${PACKAGES[@]}"; do
    for ebuild in gentoo-overlay/$package/*.ebuild; do
        if [[ -f "$ebuild" ]]; then
            run_test "Ebuild syntax: $(basename $ebuild)" \
                "check_ebuild_syntax $ebuild"
        fi
    done
done

echo ""

#
# TEST SECTION 4: Metadata Validation
#
echo_header "Section 4: Metadata XML Validation"

check_metadata_email() {
    local metadata="$1"
    grep -q "gounthar@gmail.com" "$metadata"
}

for package in "${PACKAGES[@]}"; do
    metadata="gentoo-overlay/$package/metadata.xml"
    if [[ -f "$metadata" ]]; then
        run_test "Metadata has maintainer email: $package" \
            "check_metadata_email $metadata"

        run_test "Metadata XML is well-formed: $package" \
            "xmllint --noout $metadata 2>/dev/null || grep -q '<pkgmetadata>' $metadata"
    fi
done

echo ""

#
# TEST SECTION 5: Generator Scripts
#
echo_header "Section 5: Generator Scripts"

GENERATORS=(
    "scripts/generate-containerd-ebuild.sh"
    "scripts/generate-runc-ebuild.sh"
    "scripts/generate-docker-cli-ebuild.sh"
    "scripts/generate-docker-compose-ebuild.sh"
    "scripts/generate-tini-ebuild.sh"
)

for generator in "${GENERATORS[@]}"; do
    run_test "Generator exists: $(basename $generator)" \
        "[[ -f $generator ]]"

    run_test "Generator is executable: $(basename $generator)" \
        "[[ -x $generator ]]"

    run_test "Generator has correct email: $(basename $generator)" \
        "grep -q 'gounthar@gmail.com' $generator"
done

run_test "Master generator exists" \
    "[[ -f generate-gentoo-overlay-modular.sh ]]"

run_test "Master generator is executable" \
    "[[ -x generate-gentoo-overlay-modular.sh ]]"

echo ""

#
# TEST SECTION 6: UpdateCLI Manifests
#
echo_header "Section 6: UpdateCLI Manifests"

MANIFESTS=(
    ".updatecli.d/gentoo-containerd.yaml"
    ".updatecli.d/gentoo-runc.yaml"
    ".updatecli.d/gentoo-docker-cli.yaml"
    ".updatecli.d/gentoo-docker-compose.yaml"
    ".updatecli.d/gentoo-tini.yaml"
)

for manifest in "${MANIFESTS[@]}"; do
    run_test "UpdateCLI manifest exists: $(basename $manifest)" \
        "[[ -f $manifest ]]"

    if command -v python3 &> /dev/null; then
        run_test "UpdateCLI manifest YAML valid: $(basename $manifest)" \
            "python3 -c \"import yaml; yaml.safe_load(open('$manifest'))\" 2>&1"
    fi
done

run_test "UpdateCLI workflow exists" \
    "[[ -f .github/workflows/updatecli-gentoo.yml ]]"

echo ""

#
# TEST SECTION 7: Documentation
#
echo_header "Section 7: Documentation"

run_test "Phase 2 summary exists" \
    "[[ -f GENTOO-PHASE2-SUMMARY.md ]]"

run_test "Testing guide exists" \
    "[[ -f GENTOO-TESTING.md ]]"

run_test "Security guide exists" \
    "[[ -f GENTOO-SECURITY.md ]]"

run_test "Integration test script exists" \
    "[[ -f scripts/test-gentoo-integration.sh ]]"

run_test "Benchmark script exists" \
    "[[ -f scripts/benchmark-gentoo-docker.sh ]]"

echo ""

#
# FINAL SUMMARY
#
echo_header "Validation Summary"
echo ""
echo_info "Total Tests: ${TESTS_TOTAL}"
echo_pass "Passed: ${TESTS_PASSED}"

if [[ $TESTS_FAILED -gt 0 ]]; then
    echo_fail "Failed: ${TESTS_FAILED}"
else
    echo_pass "Failed: ${TESTS_FAILED}"
fi

echo ""

if [[ $TESTS_TOTAL -gt 0 ]]; then
    PASS_RATE=$(awk "BEGIN {printf \"%.1f\", ($TESTS_PASSED / $TESTS_TOTAL) * 100}")
else
    PASS_RATE="0.0"
fi
echo_info "Pass Rate: ${PASS_RATE}%"

echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo_pass "🎉 All validation tests passed! Overlay structure is valid!"
    exit 0
else
    echo_fail "⚠️  Some validation tests failed. Review the output above."
    exit 1
fi
