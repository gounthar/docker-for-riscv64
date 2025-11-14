#!/usr/bin/env bash
set -euo pipefail

# Check for required dependencies
check_dependencies() {
    local missing_deps=()

    if ! command -v go &> /dev/null; then
        missing_deps+=("golang-go")
    fi

    if ! command -v git &> /dev/null; then
        missing_deps+=("git")
    fi

    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo "Error: Missing required dependencies: ${missing_deps[*]}"
        echo ""
        echo "Install on Debian-like systems with:"
        echo "  sudo apt-get update"
        echo "  sudo apt-get install -y ${missing_deps[*]}"
        exit 1
    fi
}

# Build cagent for RISC-V64
build_cagent() {
    echo "Building cagent for RISC-V64..."

    cd cagent

    # Get version info
    GIT_TAG=$(git describe --tags --exact-match 2>/dev/null || echo "dev")
    GIT_COMMIT=$(git rev-parse HEAD)

    echo "Version: ${GIT_TAG}"
    echo "Commit: ${GIT_COMMIT}"

    # Build with ldflags for version info
    GOOS=linux GOARCH=riscv64 go build \
        -ldflags "-X 'github.com/docker/cagent/pkg/version.Version=${GIT_TAG}' -X 'github.com/docker/cagent/pkg/version.Commit=${GIT_COMMIT}'" \
        -o ../bin/cagent-linux-riscv64 \
        ./main.go

    cd ..

    echo "Build complete: bin/cagent-linux-riscv64"
    echo ""

    # Show binary info
    file bin/cagent-linux-riscv64
    ls -lh bin/cagent-linux-riscv64
}

# Main execution
main() {
    echo "=== cagent RISC-V64 Build Script ==="
    echo ""

    check_dependencies

    # Create output directory
    mkdir -p bin

    build_cagent

    echo ""
    echo "=== Build Successful! ==="
}

# Show help
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    echo "Usage: $0"
    echo ""
    echo "Builds cagent for RISC-V64 architecture"
    echo ""
    echo "Requirements:"
    echo "  - Go 1.21 or higher"
    echo "  - git"
    echo ""
    echo "Output:"
    echo "  bin/cagent-linux-riscv64 - Static binary for RISC-V64"
    exit 0
fi

main "$@"
