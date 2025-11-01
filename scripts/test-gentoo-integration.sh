#!/bin/bash
# Gentoo RISC-V64 Docker Integration Test Suite
# Automated testing script for Docker functionality on Gentoo
#
# Usage: ./test-gentoo-integration.sh [--quick|--full]
#
# Requirements:
# - Gentoo Linux RISC-V64
# - Docker installed from docker-riscv64 overlay
# - Root or docker group membership

set -e

# Configuration
TEST_MODE="${1:---full}"
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

# Cleanup function
cleanup() {
    echo_info "Cleaning up test resources..."
    docker rm -f test-container 2>/dev/null || true
    docker network rm test-net 2>/dev/null || true
    docker volume rm test-vol 2>/dev/null || true
    docker rmi test-build:latest 2>/dev/null || true
}

trap cleanup EXIT

echo_header "Gentoo RISC-V64 Docker Integration Tests"
echo_info "Test Mode: $TEST_MODE"
echo_info "Date: $(date)"
echo_info "Hostname: $(hostname)"
echo_info "Architecture: $(uname -m)"
echo ""

#
# SECTION 1: Prerequisites Check
#
echo_header "Section 1: Prerequisites"

run_test "Architecture is RISC-V64" \
    "[[ \"$(uname -m)\" == \"riscv64\" ]]"

run_test "Docker command available" \
    "command -v docker &> /dev/null"

run_test "Docker daemon running" \
    "docker info > /dev/null 2>&1"

run_test "Docker reports RISC-V64 architecture" \
    "docker info 2>/dev/null | grep -qi 'riscv64'"

run_test "Containerd binary available" \
    "command -v containerd &> /dev/null"

run_test "Runc binary available" \
    "command -v runc &> /dev/null"

run_test "Docker CLI version" \
    "docker --version | grep -q 'Docker version'"

echo ""

#
# SECTION 2: Basic Container Operations
#
echo_header "Section 2: Basic Container Operations"

# Use busybox as test image (most likely to have riscv64 support)
TEST_IMAGE="busybox:latest"

run_test "Pull test image" \
    "docker pull $TEST_IMAGE 2>&1 | grep -qE '(Downloaded|Already exists|Image is up to date)'"

run_test "Run simple container" \
    "docker run --rm $TEST_IMAGE echo 'test' | grep -q 'test'"

run_test "Create container" \
    "docker create --name test-container $TEST_IMAGE sleep 300 &> /dev/null"

run_test "Start container" \
    "docker start test-container &> /dev/null"

run_test "Container is running" \
    "docker ps | grep -q test-container"

run_test "Execute command in container" \
    "docker exec test-container echo 'exec-test' | grep -q 'exec-test'"

run_test "Stop container" \
    "docker stop test-container &> /dev/null"

run_test "Remove container" \
    "docker rm test-container &> /dev/null"

echo ""

#
# SECTION 3: Network Operations
#
echo_header "Section 3: Network Operations"

run_test "Create custom network" \
    "docker network create test-net &> /dev/null"

run_test "List networks shows test network" \
    "docker network ls | grep -q test-net"

run_test "Inspect network" \
    "docker network inspect test-net | grep -q '\"Name\": \"test-net\"'"

run_test "Run container on custom network" \
    "docker run --rm --network=test-net $TEST_IMAGE ip addr | grep -q 'inet'"

run_test "Remove custom network" \
    "docker network rm test-net &> /dev/null"

echo ""

#
# SECTION 4: Volume Operations
#
echo_header "Section 4: Volume Operations"

run_test "Create volume" \
    "docker volume create test-vol &> /dev/null"

run_test "List volumes shows test volume" \
    "docker volume ls | grep -q test-vol"

run_test "Inspect volume" \
    "docker volume inspect test-vol | grep -q '\"Name\": \"test-vol\"'"

run_test "Write data to volume" \
    "docker run --rm -v test-vol:/data $TEST_IMAGE sh -c 'echo testdata > /data/test.txt' &> /dev/null"

run_test "Read data from volume" \
    "docker run --rm -v test-vol:/data $TEST_IMAGE cat /data/test.txt | grep -q 'testdata'"

run_test "Remove volume" \
    "docker volume rm test-vol &> /dev/null"

echo ""

#
# SECTION 5: Build Operations
#
echo_header "Section 5: Build Operations"

# Create temporary directory for build test
BUILD_DIR=$(mktemp -d)
cat > "$BUILD_DIR/Dockerfile" <<'EOF'
FROM busybox:latest
RUN echo "Built on RISC-V64!" > /test.txt
CMD cat /test.txt
EOF

run_test "Build image from Dockerfile" \
    "docker build -q -t test-build:latest $BUILD_DIR &> /dev/null"

run_test "Run built image" \
    "docker run --rm test-build:latest | grep -q 'Built on RISC-V64!'"

run_test "Remove built image" \
    "docker rmi test-build:latest &> /dev/null"

rm -rf "$BUILD_DIR"

echo ""

#
# SECTION 6: Docker Compose Tests (if installed)
#
if command -v docker-compose &> /dev/null || docker compose version &> /dev/null 2>&1; then
    echo_header "Section 6: Docker Compose"

    COMPOSE_DIR=$(mktemp -d)
    cat > "$COMPOSE_DIR/compose.yml" <<'EOF'
services:
  test:
    image: busybox:latest
    command: sh -c "echo 'Compose test' && sleep 5"
EOF

    cd "$COMPOSE_DIR"

    run_test "Docker Compose version" \
        "docker compose version &> /dev/null"

    run_test "Compose up" \
        "docker compose up -d &> /dev/null"

    run_test "Compose ps shows service" \
        "docker compose ps | grep -q test"

    run_test "Compose logs" \
        "docker compose logs 2>&1 | grep -q 'Compose test'"

    run_test "Compose down" \
        "docker compose down &> /dev/null"

    cd - > /dev/null
    rm -rf "$COMPOSE_DIR"

    echo ""
else
    echo_warn "Docker Compose not installed, skipping Compose tests"
    echo ""
fi

#
# SECTION 7: Tini Tests (if installed)
#
if command -v tini &> /dev/null; then
    echo_header "Section 7: Tini (Init Process)"

    run_test "Tini binary available" \
        "command -v tini &> /dev/null"

    run_test "Tini version" \
        "tini --version &> /dev/null"

    run_test "Container with --init flag" \
        "docker run --rm --init $TEST_IMAGE ps aux | grep -q 'tini'"

    echo ""
else
    echo_warn "Tini not installed, skipping init tests"
    echo ""
fi

#
# SECTION 8: Stress Tests (full mode only)
#
if [[ "$TEST_MODE" == "--full" ]]; then
    echo_header "Section 8: Stress Tests"

    run_test "Multiple containers simultaneously" \
        "for i in {1..5}; do docker run -d --name stress-\$i $TEST_IMAGE sleep 30; done && sleep 2 && docker ps | grep -c stress- | grep -q 5 && for i in {1..5}; do docker rm -f stress-\$i; done &> /dev/null"

    run_test "Rapid container creation/deletion" \
        "for i in {1..10}; do docker run --rm $TEST_IMAGE echo test-\$i; done | grep -q test-10"

    echo ""
fi

#
# SECTION 9: Package Verification
#
echo_header "Section 9: Gentoo Package Verification"

run_test "Containerd package installed" \
    "equery list app-containers/containerd | grep -q containerd"

run_test "Runc package installed" \
    "equery list app-containers/runc | grep -q runc"

run_test "Docker CLI package installed" \
    "equery list app-containers/docker-cli | grep -q docker-cli"

run_test "Docker package installed" \
    "equery list app-containers/docker | grep -q docker"

if docker compose version &> /dev/null 2>&1; then
    run_test "Docker Compose package installed" \
        "equery list app-containers/docker-compose | grep -q docker-compose"
fi

if command -v tini &> /dev/null; then
    run_test "Tini package installed" \
        "equery list sys-process/tini | grep -q tini"
fi

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
    echo_pass "🎉 All tests passed! Gentoo Docker installation is functional!"
    exit 0
else
    echo_fail "⚠️  Some tests failed. Review the output above."
    exit 1
fi
