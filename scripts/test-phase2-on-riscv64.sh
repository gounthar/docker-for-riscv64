#!/bin/bash
# Comprehensive Phase 2 testing script for RISC-V64 machine
# Tests everything we can without actually installing Gentoo packages
#
# What this tests:
# 1. Binary availability in releases
# 2. Binary functionality (download and test)
# 3. Generation scripts
# 4. Ebuild syntax
# 5. Dependency structure validation
# 6. UpdateCLI manifest syntax

set -e

COLORS_ENABLED=true
if [[ ! -t 1 ]]; then
    COLORS_ENABLED=false
fi

# Color functions
if $COLORS_ENABLED; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    MAGENTA='\033[0;35m'
    CYAN='\033[0;36m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    MAGENTA=''
    CYAN=''
    NC=''
fi

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

echo_warn() {
    echo -e "${YELLOW}[!]${NC} $1"
}

echo_info() {
    echo -e "${MAGENTA}[i]${NC} $1"
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

# Default versions (from generate-gentoo-overlay-modular.sh)
DOCKER_VERSION="28.5.1"
CLI_VERSION="28.5.1"
COMPOSE_VERSION="2.40.1"
CONTAINERD_VERSION="1.7.28"
RUNC_VERSION="1.3.0"
TINI_VERSION="0.19.0"

TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo_header "Phase 2 Gentoo Packaging Test Suite"
echo_info "Testing Date: $(date)"
echo_info "Hostname: $(hostname)"
echo_info "Architecture: $(uname -m)"
echo_info "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '"')"
echo ""

#
# TEST SECTION 1: Generation Scripts
#
echo_header "Section 1: Generation Scripts"

run_test "Master generation script exists" \
    "[[ -x ./generate-gentoo-overlay-modular.sh ]]"

run_test "Containerd generator exists" \
    "[[ -x ./scripts/generate-containerd-ebuild.sh ]]"

run_test "Runc generator exists" \
    "[[ -x ./scripts/generate-runc-ebuild.sh ]]"

run_test "Docker CLI generator exists" \
    "[[ -x ./scripts/generate-docker-cli-ebuild.sh ]]"

run_test "Docker Compose generator exists" \
    "[[ -x ./scripts/generate-docker-compose-ebuild.sh ]]"

run_test "Tini generator exists" \
    "[[ -x ./scripts/generate-tini-ebuild.sh ]]"

echo ""

#
# TEST SECTION 2: Overlay Generation
#
echo_header "Section 2: Overlay Generation"

echo_test "Regenerating overlay with test output..."
./generate-gentoo-overlay-modular.sh > "$TEMP_DIR/generation.log" 2>&1

run_test "Overlay generation succeeded" \
    "[[ -d gentoo-overlay ]]"

run_test "Containerd ebuild generated" \
    "[[ -f gentoo-overlay/app-containers/containerd/containerd-${CONTAINERD_VERSION}.ebuild ]]"

run_test "Runc ebuild generated" \
    "[[ -f gentoo-overlay/app-containers/runc/runc-${RUNC_VERSION}.ebuild ]]"

run_test "Docker CLI ebuild generated" \
    "[[ -f gentoo-overlay/app-containers/docker-cli/docker-cli-${CLI_VERSION}.ebuild ]]"

run_test "Docker Compose ebuild generated" \
    "[[ -f gentoo-overlay/app-containers/docker-compose/docker-compose-${COMPOSE_VERSION}.ebuild ]]"

run_test "Tini ebuild generated" \
    "[[ -f gentoo-overlay/sys-process/tini/tini-${TINI_VERSION}.ebuild ]]"

run_test "Main Docker ebuild generated" \
    "[[ -f gentoo-overlay/app-containers/docker/docker-${DOCKER_VERSION}.ebuild ]]"

run_test "Overlay has metadata" \
    "[[ -f gentoo-overlay/metadata/layout.conf ]]"

run_test "Overlay has repo name" \
    "[[ -f gentoo-overlay/profiles/repo_name ]]"

echo ""

#
# TEST SECTION 3: Ebuild Syntax Validation
#
echo_header "Section 3: Ebuild Syntax"

check_ebuild_syntax() {
    local ebuild="$1"
    bash -n "$ebuild" 2>&1
}

run_test "Containerd ebuild syntax valid" \
    "check_ebuild_syntax gentoo-overlay/app-containers/containerd/containerd-${CONTAINERD_VERSION}.ebuild"

run_test "Runc ebuild syntax valid" \
    "check_ebuild_syntax gentoo-overlay/app-containers/runc/runc-${RUNC_VERSION}.ebuild"

run_test "Docker CLI ebuild syntax valid" \
    "check_ebuild_syntax gentoo-overlay/app-containers/docker-cli/docker-cli-${CLI_VERSION}.ebuild"

run_test "Docker Compose ebuild syntax valid" \
    "check_ebuild_syntax gentoo-overlay/app-containers/docker-compose/docker-compose-${COMPOSE_VERSION}.ebuild"

run_test "Tini ebuild syntax valid" \
    "check_ebuild_syntax gentoo-overlay/sys-process/tini/tini-${TINI_VERSION}.ebuild"

run_test "Main Docker ebuild syntax valid" \
    "check_ebuild_syntax gentoo-overlay/app-containers/docker/docker-${DOCKER_VERSION}.ebuild"

echo ""

#
# TEST SECTION 4: Dependency Structure
#
echo_header "Section 4: Dependency Validation"

DOCKER_EBUILD="gentoo-overlay/app-containers/docker/docker-${DOCKER_VERSION}.ebuild"
CONTAINERD_EBUILD="gentoo-overlay/app-containers/containerd/containerd-${CONTAINERD_VERSION}.ebuild"
COMPOSE_EBUILD="gentoo-overlay/app-containers/docker-compose/docker-compose-${COMPOSE_VERSION}.ebuild"

run_test "Docker ebuild depends on containerd" \
    "grep -q 'containerd-${CONTAINERD_VERSION}' '$DOCKER_EBUILD'"

run_test "Docker ebuild depends on runc" \
    "grep -q 'runc-${RUNC_VERSION}' '$DOCKER_EBUILD'"

run_test "Docker ebuild depends on docker-cli" \
    "grep -q 'docker-cli-${CLI_VERSION}' '$DOCKER_EBUILD'"

run_test "Docker ebuild has tini USE flag" \
    "grep -q 'container-init' '$DOCKER_EBUILD'"


run_test "Docker ebuild has overlay2 USE flag" \
    "grep -q 'overlay2' '$DOCKER_EBUILD'"

run_test "Containerd ebuild depends on runc" \
    "grep -q 'app-containers/runc-${RUNC_VERSION}' '$CONTAINERD_EBUILD'"

run_test "Docker Compose ebuild depends on docker-cli" \
    "grep -q 'app-containers/docker-cli-${CLI_VERSION}' '$COMPOSE_EBUILD'"
echo ""

#
# TEST SECTION 5: Binary Availability in Releases
#
echo_header "Section 5: Binary Availability in GitHub Releases"

echo_info "Checking Docker Engine release v${DOCKER_VERSION}-riscv64..."
DOCKER_ASSETS=$(gh release view "v${DOCKER_VERSION}-riscv64" --json assets --jq '.assets[].name' 2>/dev/null || echo "")

run_test "dockerd binary exists in release" \
    "echo '$DOCKER_ASSETS' | grep -q '^dockerd$'"

run_test "docker-proxy binary exists in release" \
    "echo '$DOCKER_ASSETS' | grep -q '^docker-proxy$'"

run_test "containerd binary exists in release" \
    "echo '$DOCKER_ASSETS' | grep -q '^containerd$'"

run_test "containerd-shim-runc-v2 binary exists in release" \
    "echo '$DOCKER_ASSETS' | grep -q '^containerd-shim-runc-v2$'"

run_test "runc binary exists in release" \
    "echo '$DOCKER_ASSETS' | grep -q '^runc$'"

echo_info "Checking Docker CLI release cli-v${CLI_VERSION}-riscv64..."
CLI_ASSETS=$(gh release view "cli-v${CLI_VERSION}-riscv64" --json assets --jq '.assets[].name' 2>/dev/null || echo "")

run_test "docker CLI binary exists in release" \
    "echo '$CLI_ASSETS' | grep -q '^docker$'"

echo_info "Checking Docker Compose release compose-v${COMPOSE_VERSION}-riscv64..."
COMPOSE_ASSETS=$(gh release view "compose-v${COMPOSE_VERSION}-riscv64" --json assets --jq '.assets[].name' 2>/dev/null || echo "")

run_test "docker-compose binary exists in release" \
    "echo '$COMPOSE_ASSETS' | grep -q '^docker-compose$'"

echo_info "Checking Tini release tini-v${TINI_VERSION}-riscv64..."
TINI_ASSETS=$(gh release view "tini-v${TINI_VERSION}-riscv64" --json assets --jq '.assets[].name' 2>/dev/null || echo "")

run_test "tini binary exists in release" \
    "echo '$TINI_ASSETS' | grep -q '^tini$'"

run_test "tini-static binary exists in release" \
    "echo '$TINI_ASSETS' | grep -q '^tini-static$'"

echo ""

#
# TEST SECTION 6: Binary Functionality Tests
#
echo_header "Section 6: Binary Functionality Tests"

echo_info "Downloading and testing binaries on RISC-V64..."

# Download and test dockerd
echo_test "Downloading dockerd..."
gh release download "v${DOCKER_VERSION}-riscv64" -p "dockerd" -D "$TEMP_DIR" --clobber 2>/dev/null
chmod +x "$TEMP_DIR/dockerd"

run_test "dockerd binary is executable" \
    "[[ -x $TEMP_DIR/dockerd ]]"

run_test "dockerd --version works" \
    "$TEMP_DIR/dockerd --version > /dev/null 2>&1"

run_test "dockerd is RISC-V64 binary" \
    "file $TEMP_DIR/dockerd | grep -q 'RISC-V'"

# Download and test containerd
echo_test "Downloading containerd..."
gh release download "v${DOCKER_VERSION}-riscv64" -p "containerd" -D "$TEMP_DIR" --clobber 2>/dev/null
chmod +x "$TEMP_DIR/containerd"

run_test "containerd binary is executable" \
    "[[ -x $TEMP_DIR/containerd ]]"

run_test "containerd --version works" \
    "$TEMP_DIR/containerd --version > /dev/null 2>&1"

run_test "containerd is RISC-V64 binary" \
    "file $TEMP_DIR/containerd | grep -q 'RISC-V'"

# Download and test runc
echo_test "Downloading runc..."
gh release download "v${DOCKER_VERSION}-riscv64" -p "runc" -D "$TEMP_DIR" --clobber 2>/dev/null
chmod +x "$TEMP_DIR/runc"

run_test "runc binary is executable" \
    "[[ -x $TEMP_DIR/runc ]]"

run_test "runc --version works" \
    "$TEMP_DIR/runc --version > /dev/null 2>&1"

run_test "runc is RISC-V64 binary" \
    "file $TEMP_DIR/runc | grep -q 'RISC-V'"

# Download and test docker CLI
echo_test "Downloading docker CLI..."
gh release download "cli-v${CLI_VERSION}-riscv64" -p "docker" -D "$TEMP_DIR" --clobber 2>/dev/null
chmod +x "$TEMP_DIR/docker"

run_test "docker CLI binary is executable" \
    "[[ -x $TEMP_DIR/docker ]]"

run_test "docker --version works" \
    "$TEMP_DIR/docker --version > /dev/null 2>&1"

run_test "docker CLI is RISC-V64 binary" \
    "file $TEMP_DIR/docker | grep -q 'RISC-V'"

# Download and test docker-compose
echo_test "Downloading docker-compose..."
gh release download "compose-v${COMPOSE_VERSION}-riscv64" -p "docker-compose" -D "$TEMP_DIR" --clobber 2>/dev/null
chmod +x "$TEMP_DIR/docker-compose"

run_test "docker-compose binary is executable" \
    "[[ -x $TEMP_DIR/docker-compose ]]"

run_test "docker compose version works" \
    "$TEMP_DIR/docker-compose version > /dev/null 2>&1"

run_test "docker-compose is RISC-V64 binary" \
    "file $TEMP_DIR/docker-compose | grep -q 'RISC-V'"

# Download and test tini
echo_test "Downloading tini..."
gh release download "tini-v${TINI_VERSION}-riscv64" -p "tini" -D "$TEMP_DIR" --clobber 2>/dev/null
chmod +x "$TEMP_DIR/tini"

run_test "tini binary is executable" \
    "[[ -x $TEMP_DIR/tini ]]"

run_test "tini --version works" \
    "$TEMP_DIR/tini --version > /dev/null 2>&1"

run_test "tini is RISC-V64 binary" \
    "file $TEMP_DIR/tini | grep -q 'RISC-V'"

echo ""

#
# TEST SECTION 7: UpdateCLI Manifests
#
echo_header "Section 7: UpdateCLI Manifest Validation"

run_test "UpdateCLI directory exists" \
    "[[ -d .updatecli.d ]]"

check_yaml_syntax() {
    python3 -c "import yaml; yaml.safe_load(open('$1'))" 2>&1
}

run_test "containerd manifest YAML is valid" \
    "check_yaml_syntax .updatecli.d/gentoo-containerd.yaml"

run_test "runc manifest YAML is valid" \
    "check_yaml_syntax .updatecli.d/gentoo-runc.yaml"

run_test "docker-cli manifest YAML is valid" \
    "check_yaml_syntax .updatecli.d/gentoo-docker-cli.yaml"

run_test "docker-compose manifest YAML is valid" \
    "check_yaml_syntax .updatecli.d/gentoo-docker-compose.yaml"

run_test "tini manifest YAML is valid" \
    "check_yaml_syntax .updatecli.d/gentoo-tini.yaml"

run_test "UpdateCLI workflow exists" \
    "[[ -f .github/workflows/updatecli-gentoo.yml ]]"

run_test "UpdateCLI workflow YAML is valid" \
    "check_yaml_syntax .github/workflows/updatecli-gentoo.yml"

echo ""

#
# TEST SECTION 8: Documentation
#
echo_header "Section 8: Documentation Validation"


run_test "Phase 2 summary exists" \
    "[[ -f GENTOO-PHASE2-SUMMARY.md ]]"

run_test "Overlay README exists" \
    "[[ -f gentoo-overlay/README.md ]]"

run_test "Overlay README mentions modular approach" \
    "grep -q 'modular' gentoo-overlay/README.md"

echo ""

#
# TEST SECTION 9: Metadata Files
#
echo_header "Section 9: Metadata Validation"

run_test "Containerd has metadata.xml" \
    "[[ -f gentoo-overlay/app-containers/containerd/metadata.xml ]]"

run_test "Runc has metadata.xml" \
    "[[ -f gentoo-overlay/app-containers/runc/metadata.xml ]]"

run_test "Docker CLI has metadata.xml" \
    "[[ -f gentoo-overlay/app-containers/docker-cli/metadata.xml ]]"

run_test "Docker Compose has metadata.xml" \
    "[[ -f gentoo-overlay/app-containers/docker-compose/metadata.xml ]]"

run_test "Tini has metadata.xml" \
    "[[ -f gentoo-overlay/sys-process/tini/metadata.xml ]]"

run_test "Docker has metadata.xml" \
    "[[ -f gentoo-overlay/app-containers/docker/metadata.xml ]]"

echo ""

#
# FINAL SUMMARY
#
echo_header "Test Summary"
echo ""
echo_info "Total Tests: ${TESTS_TOTAL}"
echo_pass "Passed: ${TESTS_PASSED}"

if [[ $TESTS_FAILED -gt 0 ]]; then
    echo_fail "Failed: ${TESTS_FAILED}"
else
    echo_pass "Failed: ${TESTS_FAILED}"
fi

echo ""

PASS_RATE=$(awk "BEGIN {printf \"%.1f\", ($TESTS_PASSED / $TESTS_TOTAL) * 100}")
echo_info "Pass Rate: ${PASS_RATE}%"

echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo_pass "🎉 All tests passed! Phase 2 implementation is solid!"
    exit 0
else
    echo_fail "⚠️  Some tests failed. Review the output above."
    exit 1
fi
