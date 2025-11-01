#!/bin/bash
# Docker RISC-V64 Performance Benchmarking Suite
# Measures Docker performance on Gentoo RISC-V64 systems
#
# Usage: ./benchmark-gentoo-docker.sh [--output=<file>]
#
# Requirements:
# - Gentoo Linux RISC-V64
# - Docker installed and running
# - bc calculator (emerge -a bc)
# - time command

set -e

# Configuration
OUTPUT_FILE=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --output=*)
            OUTPUT_FILE="${1#--output=}"
            shift
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

if [[ -z "$OUTPUT_FILE" ]]; then
    OUTPUT_FILE="benchmark-results-$(date +%Y%m%d-%H%M%S).txt"
fi

ITERATIONS=10
TEST_IMAGE="busybox:latest"

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

echo_result() {
    echo -e "${GREEN}[✓]${NC} $1"
}

# Check dependencies
check_dependencies() {
    if ! command -v bc &> /dev/null; then
        echo -e "${RED}Error: bc calculator not found. Install with: emerge -a bc${NC}"
        exit 1
    fi

    if ! docker info &> /dev/null; then
        echo -e "${RED}Error: Docker daemon not running${NC}"
        exit 1
    fi
}

# Calculate statistics
calculate_stats() {
    local values=("$@")
    local sum=0
    local count=${#values[@]}

    # Calculate mean
    for val in "${values[@]}"; do
        sum=$(echo "$sum + $val" | bc -l)
    done
    local mean=$(echo "scale=3; $sum / $count" | bc -l)

    # Calculate min and max
    local min=${values[0]}
    local max=${values[0]}
    for val in "${values[@]}"; do
        if (( $(echo "$val < $min" | bc -l) )); then
            min=$val
        fi
        if (( $(echo "$val > $max" | bc -l) )); then
            max=$val
        fi
    done

    echo "$mean $min $max"
}

# Benchmark function
benchmark() {
    local test_name="$1"
    local test_command="$2"
    local iterations="$3"

    echo_info "Running: $test_name ($iterations iterations)"

    local times=()
    for i in $(seq 1 $iterations); do
        local start=$(date +%s.%N)
        eval "$test_command" > /dev/null 2>&1
        local end=$(date +%s.%N)
        local duration=$(echo "$end - $start" | bc -l)
        times+=($duration)
    done

    local stats=$(calculate_stats "${times[@]}")
    local mean=$(echo "$stats" | awk '{print $1}')
    local min=$(echo "$stats" | awk '{print $2}')
    local max=$(echo "$stats" | awk '{print $3}')

    echo_result "$test_name: mean=${mean}s, min=${min}s, max=${max}s"
    echo "$test_name,$mean,$min,$max" >> "$OUTPUT_FILE"
}

# Start benchmarking
check_dependencies

echo_header "Docker RISC-V64 Performance Benchmark"
echo_info "Date: $(date)"
echo_info "Hostname: $(hostname)"
echo_info "Architecture: $(uname -m)"
echo_info "Kernel: $(uname -r)"
echo_info "Docker Version: $(docker --version)"
echo_info "Iterations per test: $ITERATIONS"
echo_info "Output file: $OUTPUT_FILE"
echo ""

# Initialize output file
cat > "$OUTPUT_FILE" <<EOF
Docker RISC-V64 Benchmark Results
==================================
Date: $(date)
Hostname: $(hostname)
Architecture: $(uname -m)
Kernel: $(uname -r)
Docker Version: $(docker --version)
Containerd Version: $(containerd --version 2>/dev/null || echo "N/A")
Runc Version: $(runc --version 2>/dev/null | head -1 || echo "N/A")

System Information:
$(cat /proc/cpuinfo | grep -E "processor|model name|BogoMIPS" | head -20)

Memory:
$(free -h)

Results (all times in seconds):
Test Name,Mean,Min,Max
EOF

echo_header "Benchmark 1: Container Lifecycle"

# Ensure test image is available
docker pull $TEST_IMAGE > /dev/null 2>&1

benchmark "Container run (simple echo)" \
    "docker run --rm $TEST_IMAGE echo test" \
    $ITERATIONS

benchmark "Container create" \
    "docker create --name bench-test $TEST_IMAGE sleep 1; docker rm bench-test" \
    $ITERATIONS

benchmark "Container start (pre-created)" \
    "docker create --name bench-test $TEST_IMAGE sleep 0.1 > /dev/null; docker start bench-test > /dev/null; docker wait bench-test > /dev/null; docker rm bench-test > /dev/null" \
    $ITERATIONS

benchmark "Container stop (running)" \
    "docker run -d --name bench-test $TEST_IMAGE sleep 300 > /dev/null; docker stop bench-test > /dev/null; docker rm bench-test > /dev/null" \
    $ITERATIONS

echo ""
echo_header "Benchmark 2: Image Operations"

# Remove image first
docker rmi $TEST_IMAGE 2>/dev/null || true

benchmark "Image pull" \
    "docker rmi $TEST_IMAGE 2>/dev/null || true; docker pull $TEST_IMAGE" \
    3  # Fewer iterations for pull (network-dependent)

# Restore image
docker pull $TEST_IMAGE > /dev/null 2>&1

# Build test
BUILD_DIR=$(mktemp -d)
cat > "$BUILD_DIR/Dockerfile" <<'DOCKERFILE'
FROM busybox:latest
RUN echo "test" > /test.txt
RUN echo "test2" > /test2.txt
RUN echo "test3" > /test3.txt
DOCKERFILE

benchmark "Image build (3 layers)" \
    "docker build -q -t bench-build:test $BUILD_DIR; docker rmi bench-build:test" \
    5  # Fewer iterations for builds

rm -rf "$BUILD_DIR"

echo ""
echo_header "Benchmark 3: Network Operations"

benchmark "Network create/delete" \
    "docker network create bench-net > /dev/null; docker network rm bench-net > /dev/null" \
    $ITERATIONS

benchmark "Container with custom network" \
    "docker network create bench-net > /dev/null; docker run --rm --network=bench-net $TEST_IMAGE echo test > /dev/null; docker network rm bench-net > /dev/null" \
    $ITERATIONS

echo ""
echo_header "Benchmark 4: Volume Operations"

benchmark "Volume create/delete" \
    "docker volume create bench-vol > /dev/null; docker volume rm bench-vol > /dev/null" \
    $ITERATIONS

benchmark "Container with volume (write)" \
    "docker volume create bench-vol > /dev/null; docker run --rm -v bench-vol:/data $TEST_IMAGE sh -c 'echo testdata > /data/test.txt' > /dev/null; docker volume rm bench-vol > /dev/null" \
    $ITERATIONS

benchmark "Container with volume (read)" \
    "docker volume create bench-vol > /dev/null; docker run --rm -v bench-vol:/data $TEST_IMAGE sh -c 'echo testdata > /data/test.txt' > /dev/null; docker run --rm -v bench-vol:/data $TEST_IMAGE cat /data/test.txt > /dev/null; docker volume rm bench-vol > /dev/null" \
    $ITERATIONS

echo ""
echo_header "Benchmark 5: Concurrent Operations"

benchmark "3 parallel containers" \
    "docker run -d --name bench-1 $TEST_IMAGE sleep 5 > /dev/null; docker run -d --name bench-2 $TEST_IMAGE sleep 5 > /dev/null; docker run -d --name bench-3 $TEST_IMAGE sleep 5 > /dev/null; docker wait bench-1 bench-2 bench-3 > /dev/null; docker rm bench-1 bench-2 bench-3 > /dev/null" \
    5

benchmark "5 parallel containers" \
    "for i in 1 2 3 4 5; do docker run -d --name bench-\$i $TEST_IMAGE sleep 5 > /dev/null; done; for i in 1 2 3 4 5; do docker wait bench-\$i > /dev/null; done; for i in 1 2 3 4 5; do docker rm bench-\$i > /dev/null; done" \
    3

echo ""
echo_header "Benchmark 6: Resource Monitoring"

echo_info "CPU usage during idle:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null || echo "No containers running"

echo_info "Starting load test container..."
docker run -d --name bench-load $TEST_IMAGE sh -c 'while true; do echo test; done' > /dev/null
sleep 5
echo_info "CPU usage during busy loop:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" bench-load
docker rm -f bench-load > /dev/null

echo ""
echo_header "Benchmark Complete"

echo_info "Results saved to: $OUTPUT_FILE"
echo ""

# Display summary
echo "Summary Statistics:"
echo "==================="
awk 'BEGIN {p=0; FS=","}
/^Test Name,Mean,Min,Max$/ {p=1; print "Test                                      | Mean (s) | Min (s)  | Max (s)"; print "------------------------------------------|----------|----------|----------"; next}
p {printf "%-42s| %8.3f | %8.3f | %8.3f\n", $1, $2, $3, $4}' "$OUTPUT_FILE"

echo ""
echo_result "Benchmark complete! Review full results in: $OUTPUT_FILE"
