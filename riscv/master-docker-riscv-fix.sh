#!/bin/bash
# Master Docker RISC-V Fix Script
# One-stop solution for all Docker build issues on RISC-V

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              Docker RISC-V Master Fix Script                  ║${NC}"
    echo -e "${CYAN}║            Solve all Docker build issues on RISC-V            ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

show_menu() {
    echo -e "${CYAN}Available Solutions:${NC}"
    echo "1. Quick Fix - Build local golang:1.24.4-bookworm image"
    echo "2. Dockerfile Fix - Replace base images with RISC-V alternatives"
    echo "3. Community Image - Use ghcr.io/go-riscv/go:latest"
    echo "4. Complete Setup - All of the above + verification"
    echo "5. Test Current Setup - Verify what's working"
    echo "6. Fallback Options - Pre-built packages or Podman"
    echo "7. Show Build Command Examples"
    echo "8. Exit"
    echo ""
}

quick_golang_fix() {
    print_info "Building local golang:1.24.4-bookworm image..."
    
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    cat > Dockerfile << 'EOF'
FROM riscv64/debian:sid
RUN apt-get update && apt-get install -y \
    wget tar gcc libc6-dev ca-certificates git make pkg-config \
    && rm -rf /var/lib/apt/lists/*
ENV GO_VERSION=1.24.4
RUN wget -O go.tar.gz "https://go.dev/dl/go${GO_VERSION}.linux-riscv64.tar.gz" \
    && tar -C /usr/local -xzf go.tar.gz \
    && rm go.tar.gz
ENV GOPATH=/go
ENV PATH=$GOPATH/bin:/usr/local/go/bin:$PATH
RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 755 "$GOPATH"
WORKDIR $GOPATH
CMD ["go", "version"]
EOF

    if docker build -t golang:1.24.4-bookworm .; then
        print_success "Local golang image built successfully!"
        docker run --rm golang:1.24.4-bookworm go version
        print_success "You can now run: make binary"
    else
        print_error "Failed to build golang image"
        return 1
    fi
    
    cd - > /dev/null
    rm -rf "$TEMP_DIR"
}

dockerfile_fix() {
    print_info "Creating RISC-V-compatible Dockerfile..."
    
    DOCKERFILE=${1:-Dockerfile}
    if [[ ! -f "$DOCKERFILE" ]]; then
        print_error "Dockerfile not found: $DOCKERFILE"
        return 1
    fi
    
    cp "$DOCKERFILE" "${DOCKERFILE}.backup"
    cp "$DOCKERFILE" "Dockerfile.riscv-fixed"
    
    # Apply fixes
    sed -i 's|FROM --platform=\$BUILDPLATFORM \${GOLANG_IMAGE}|FROM --platform=\$BUILDPLATFORM ghcr.io/go-riscv/go:latest|g' "Dockerfile.riscv-fixed"
    sed -i 's|COPY --from=xx / /|# COPY --from=xx / / # Disabled for RISC-V|g' "Dockerfile.riscv-fixed"
    sed -i 's|FROM.*tonistiigi/xx.*|# & # Disabled for RISC-V|g' "Dockerfile.riscv-fixed"
    
    print_success "Created Dockerfile.riscv-fixed"
    
    # Create local golang version too
    cp "Dockerfile.riscv-fixed" "Dockerfile.local-golang"
    sed -i 's|ghcr.io/go-riscv/go:latest|golang:1.24.4-bookworm|g' "Dockerfile.local-golang"
    
    print_success "Created Dockerfile.local-golang (uses local image)"
}

test_setup() {
    print_info "Testing current Docker setup..."
    
    # Test Docker installation
    if command -v docker &>/dev/null; then
        print_success "Docker is installed"
        docker version --format '{{.Client.Version}}' | sed 's/^/  Client: /'
        docker version --format '{{.Server.Version}}' | sed 's/^/  Server: /'
    else
        print_error "Docker not found"
        return 1
    fi
    
    # Test architecture
    if docker run --rm --platform linux/riscv64 riscv64/alpine:latest uname -m 2>/dev/null | grep -q riscv64; then
        print_success "RISC-V container support working"
    else
        print_warning "RISC-V container support may have issues"
    fi
    
    # Test if golang image exists locally
    if docker image inspect golang:1.24.4-bookworm &>/dev/null; then
        print_success "Local golang:1.24.4-bookworm image exists"
    else
        print_warning "No local golang:1.24.4-bookworm image"
    fi
    
    # Test community image
    if docker pull ghcr.io/go-riscv/go:latest &>/dev/null; then
        print_success "Community go-riscv image available"
    else
        print_warning "Community go-riscv image unavailable"
    fi
}

show_build_examples() {
    print_info "Build Command Examples:"
    echo ""
    echo -e "${YELLOW}Using Fixed Dockerfile:${NC}"
    echo "  docker buildx bake binary"
    echo "  # or"
    echo "  docker build -f Dockerfile.riscv-fixed -t moby-riscv ."
    echo ""
    echo -e "${YELLOW}Using Local Golang Image:${NC}"
    echo "  # First run option 1 to build local image, then:"
    echo "  docker build -f Dockerfile.local-golang -t moby-riscv ."
    echo ""
    echo -e "${YELLOW}Direct Make Command:${NC}"
    echo "  make binary"
    echo ""
    echo -e "${YELLOW}With Platform Specification:${NC}"
    echo "  docker buildx build --platform linux/riscv64 -t moby-riscv ."
}

fallback_options() {
    print_info "Fallback options if Docker build still fails:"
    echo ""
    echo -e "${YELLOW}1. Use Pre-built Packages:${NC}"
    echo "  sudo apt update"
    echo "  sudo apt install docker.io docker-cli docker-compose"
    echo ""
    echo -e "${YELLOW}2. Try Podman (often more reliable on RISC-V):${NC}"
    echo "  sudo apt install podman"
    echo "  alias docker=podman"
    echo ""
    echo -e "${YELLOW}3. Cross-compile on x86_64 system:${NC}"
    echo "  env GOOS=linux GOARCH=riscv64 make binary"
}

complete_setup() {
    print_info "Running complete setup..."
    
    # Test current setup first
    test_setup
    echo ""
    
    # Build local golang image
    print_info "Step 1: Building local golang image..."
    quick_golang_fix
    echo ""
    
    # Fix Dockerfile
    print_info "Step 2: Creating RISC-V Dockerfiles..."
    dockerfile_fix
    echo ""
    
    # Create build script
    print_info "Step 3: Creating build script..."
    cat > run-build.sh << 'EOF'
#!/bin/bash
set -e

echo "Attempting Docker build with multiple strategies..."

# Strategy 1: Use local golang image
echo "Strategy 1: Local golang image"
if docker build -f Dockerfile.local-golang -t moby-riscv .; then
    echo "SUCCESS: Build completed with local golang image!"
    exit 0
fi

# Strategy 2: Use community image  
echo "Strategy 2: Community go-riscv image"
if docker build -f Dockerfile.riscv-fixed -t moby-riscv .; then
    echo "SUCCESS: Build completed with community image!"
    exit 0
fi

# Strategy 3: Buildx
echo "Strategy 3: Docker buildx"
if docker buildx bake binary; then
    echo "SUCCESS: Build completed with buildx!"
    exit 0
fi

echo "ERROR: All build strategies failed"
echo "Consider using fallback options (see menu option 6)"
exit 1
EOF
    chmod +x run-build.sh
    
    print_success "Complete setup finished!"
    print_info "You can now run: ./run-build.sh"
}

# Main script
print_header

while true; do
    show_menu
    read -p "Choose an option (1-8): " choice
    echo ""
    
    case $choice in
        1)
            quick_golang_fix
            ;;
        2)
            dockerfile_fix
            ;;
        3)
            print_info "Using community image approach..."
            dockerfile_fix
            print_success "Use Dockerfile.riscv-fixed for builds"
            ;;
        4)
            complete_setup
            ;;
        5)
            test_setup
            ;;
        6)
            fallback_options
            ;;
        7)
            show_build_examples
            ;;
        8)
            print_info "Goodbye!"
            exit 0
            ;;
        *)
            print_error "Invalid option. Please choose 1-8."
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
    echo ""
done