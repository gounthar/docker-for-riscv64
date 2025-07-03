# Dockerfile RISC-V Base Image Fix Script v2.0
# This script fixes common RISC-V compatibility issues in Dockerfiles
# and provides local image building capabilities

#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Image mapping for RISC-V compatibility
declare -A IMAGE_MAP=(
    ["golang:1.24.4-bookworm"]="ghcr.io/go-riscv/go:latest"
    ["golang:1.24-bookworm"]="ghcr.io/go-riscv/go:latest"
    ["golang:latest"]="ghcr.io/go-riscv/go:latest"
    ["node:18"]="riscv64/node:latest"
    ["node:16"]="riscv64/node:latest"
    ["python:3.11"]="riscv64/python:latest"
    ["debian:bullseye"]="riscv64/debian:sid"
    ["debian:bookworm"]="riscv64/debian:sid"
    ["ubuntu:20.04"]="riscv64/ubuntu:focal"
    ["ubuntu:22.04"]="riscv64/ubuntu:jammy"
    ["alpine:3.18"]="riscv64/alpine:latest"
)

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}[$(date +'%Y-%m-%d %H:%M:%S')] $message${NC}"
}

print_info() { print_status "$BLUE" "INFO: $1"; }
print_success() { print_status "$GREEN" "SUCCESS: $1"; }
print_warning() { print_status "$YELLOW" "WARNING: $1"; }
print_error() { print_status "$RED" "ERROR: $1"; }

# Function to check if image exists for RISC-V
check_image_availability() {
    local image=$1
    print_info "Testing $image..."
    
    if docker manifest inspect "$image" &>/dev/null; then
        local manifests=$(docker manifest inspect "$image" | jq -r '.manifests[]?.platform.architecture // empty' 2>/dev/null)
        if echo "$manifests" | grep -q "riscv64"; then
            print_success "  ✓ Available with RISC-V support"
            return 0
        else
            print_warning "  ⚠ Available but no RISC-V architecture"
            return 1
        fi
    else
        # Try to pull to check availability
        if docker pull "$image" &>/dev/null; then
            print_success "  ✓ Available"
            return 0
        else
            print_warning "  ✗ Not available"
            return 1
        fi
    fi
}

# Function to build missing golang image locally
build_golang_image_locally() {
    local target_tag=$1
    local go_version=${target_tag#golang:}
    go_version=${go_version%-*}  # Remove -bookworm suffix
    
    print_info "Building custom golang image: $target_tag"
    
    # Create temporary directory
    local temp_dir=$(mktemp -d)
    
    cat > "$temp_dir/Dockerfile" << EOF
# Custom Golang image for RISC-V based on $target_tag
FROM riscv64/debian:sid

# Install basic dependencies
RUN apt-get update && apt-get install -y \\
    wget \\
    tar \\
    gcc \\
    libc6-dev \\
    ca-certificates \\
    && rm -rf /var/lib/apt/lists/*

# Download and install Go for RISC-V
ENV GO_VERSION=$go_version
RUN wget -O go.tar.gz "https://go.dev/dl/go\${GO_VERSION}.linux-riscv64.tar.gz" \\
    && tar -C /usr/local -xzf go.tar.gz \\
    && rm go.tar.gz

# Set Go environment
ENV GOPATH=/go
ENV PATH=\$GOPATH/bin:/usr/local/go/bin:\$PATH

# Create workspace
RUN mkdir -p "\$GOPATH/src" "\$GOPATH/bin" && chmod -R 777 "\$GOPATH"
WORKDIR \$GOPATH

CMD ["go", "version"]
EOF

    print_info "Building $target_tag from custom Dockerfile..."
    if docker build -t "$target_tag" "$temp_dir"; then
        print_success "Successfully built $target_tag"
        rm -rf "$temp_dir"
        return 0
    else
        print_error "Failed to build $target_tag"
        rm -rf "$temp_dir"
        return 1
    fi
}

# Function to create RISC-V compatible Dockerfile
create_riscv_dockerfile() {
    local input_file=${1:-Dockerfile}
    local output_file="Dockerfile.riscv"
    
    print_info "Creating RISC-V compatible Dockerfile: $output_file"
    
    # Create backup
    if [[ -f "$input_file" ]]; then
        cp "$input_file" "${input_file}.backup"
        print_info "Created backup: ${input_file}.backup"
    fi
    
    # Start with the original file
    cp "$input_file" "$output_file"
    
    # Replace problematic base images
    for original_image in "${!IMAGE_MAP[@]}"; do
        local replacement_image="${IMAGE_MAP[$original_image]}"
        
        # Replace FROM statements
        sed -i "s|FROM.*$original_image|FROM $replacement_image  # Replaced for RISC-V|g" "$output_file"
        sed -i "s|FROM --platform=\$BUILDPLATFORM.*$original_image|FROM --platform=\$BUILDPLATFORM $replacement_image  # Replaced for RISC-V|g" "$output_file"
    done
    
    # Handle variable-based FROM statements (like ${GOLANG_IMAGE})
    sed -i 's|FROM --platform=\$BUILDPLATFORM \${GOLANG_IMAGE}|FROM --platform=\$BUILDPLATFORM ghcr.io/go-riscv/go:latest  # Replaced \${GOLANG_IMAGE} for RISC-V|g' "$output_file"
    
    # Comment out or fix cross-compilation tools
    sed -i 's|COPY --from=xx / /|# COPY --from=xx / /  # Disabled xx cross-compilation for RISC-V native build|g' "$output_file"
    sed -i 's|FROM.*tonistiigi/xx.*|# & # Disabled xx cross-compilation for RISC-V native build|g' "$output_file"
    
    # Remove invalid syntax that might have been introduced
    sed -i '/^\[INFO\]/d' "$output_file"
    sed -i '/^\[WARNING\]/d' "$output_file"
    sed -i '/^\[SUCCESS\]/d' "$output_file"
    sed -i '/^\[ERROR\]/d' "$output_file"
    
    print_success "Created RISC-V compatible Dockerfile: $output_file"
}

# Function to create build script
create_build_script() {
    local script_name="build-docker-riscv-v2.sh"
    
    cat > "$script_name" << 'EOF'
#!/bin/bash
# RISC-V Docker Build Script v2.0

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

dockerfile="Dockerfile.riscv"
if [[ ! -f "$dockerfile" ]]; then
    dockerfile="Dockerfile"
fi

print_info "Using Dockerfile: $dockerfile"

# Method 1: Docker Buildx with platform specification
print_info "Attempting Docker build with buildx and platform specification..."
if docker buildx build --platform linux/riscv64 -f "$dockerfile" -t moby-riscv:latest .; then
    print_success "Buildx with platform succeeded!"
    exit 0
fi

print_warning "Buildx with platform failed, trying direct build..."

# Method 2: Direct build
print_info "Attempting direct Docker build..."
if docker build -f "$dockerfile" -t moby-riscv:latest .; then
    print_success "Direct build succeeded!"
    exit 0
fi

print_warning "Direct build failed, trying without cache..."

# Method 3: Build without cache
print_info "Attempting build without cache..."
if docker build --no-cache -f "$dockerfile" -t moby-riscv:latest .; then
    print_success "Build without cache succeeded!"
    exit 0
fi

# Method 4: Use buildx bake if available
if command -v docker &>/dev/null && docker buildx version &>/dev/null; then
    print_info "Attempting buildx bake..."
    if docker buildx bake binary; then
        print_success "Buildx bake succeeded!"
        exit 0
    fi
fi

print_error "All build methods failed"
print_info "Consider building missing base images locally with:"
print_info "  ./dockerfile-riscv-fix-v2.sh --build-missing"
exit 1
EOF

    chmod +x "$script_name"
    print_success "Created build script: $script_name"
}

# Function to create missing image builder
create_missing_image_builder() {
    local script_name="build-missing-images.sh"
    
    cat > "$script_name" << 'EOF'
#!/bin/bash
# Build Missing RISC-V Base Images Script

set -e

print_info() { echo -e "\033[0;34m[INFO]\033[0m $1"; }
print_success() { echo -e "\033[0;32m[SUCCESS]\033[0m $1"; }
print_error() { echo -e "\033[0;31m[ERROR]\033[0m $1"; }

# Function to build golang image with specific version
build_golang_image() {
    local version=$1
    local tag="golang:${version}-bookworm"
    
    print_info "Building $tag for RISC-V..."
    
    local temp_dir=$(mktemp -d)
    
    cat > "$temp_dir/Dockerfile" << EOF
FROM riscv64/debian:sid

RUN apt-get update && apt-get install -y \\
    wget tar gcc libc6-dev ca-certificates git \\
    && rm -rf /var/lib/apt/lists/*

ENV GO_VERSION=$version
RUN wget -O go.tar.gz "https://go.dev/dl/go\${GO_VERSION}.linux-riscv64.tar.gz" \\
    && tar -C /usr/local -xzf go.tar.gz \\
    && rm go.tar.gz

ENV GOPATH=/go
ENV PATH=\$GOPATH/bin:/usr/local/go/bin:\$PATH

RUN mkdir -p "\$GOPATH/src" "\$GOPATH/bin" && chmod -R 777 "\$GOPATH"
WORKDIR \$GOPATH

CMD ["go", "version"]
EOF

    if docker build -t "$tag" "$temp_dir"; then
        print_success "Built $tag successfully"
        rm -rf "$temp_dir"
        return 0
    else
        print_error "Failed to build $tag"
        rm -rf "$temp_dir"
        return 1
    fi
}

# Build commonly needed golang versions
build_golang_image "1.24.4"
build_golang_image "1.24"
build_golang_image "1.23"

print_success "Missing image building completed!"
EOF

    chmod +x "$script_name"
    print_success "Created missing image builder: $script_name"
}

# Main script logic
main() {
    print_info "Dockerfile RISC-V Base Image Fix Script v2.0"
    print_info "============================================="
    
    case "${1:-}" in
        --build-missing)
            create_missing_image_builder
            print_info "Run ./build-missing-images.sh to build missing base images"
            ;;
        --build-golang)
            shift
            local version=${1:-1.24.4}
            build_golang_image_locally "golang:${version}-bookworm"
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --build-missing    Create script to build missing base images"
            echo "  --build-golang VER Build specific golang version locally"
            echo "  --help            Show this help"
            echo ""
            echo "Default: Fix Dockerfile and create build scripts"
            ;;
        *)
            # Default behavior
            create_riscv_dockerfile
            create_build_script
            create_missing_image_builder
            
            print_info "Testing availability of RISC-V base images..."
            local missing_images=()
            
            for image in "${!IMAGE_MAP[@]}"; do
                if ! check_image_availability "${IMAGE_MAP[$image]}"; then
                    missing_images+=("$image")
                fi
            done
            
            if [[ ${#missing_images[@]} -gt 0 ]]; then
                print_warning "Some replacement images are not available:"
                for img in "${missing_images[@]}"; do
                    print_warning "  - ${IMAGE_MAP[$img]}"
                done
                print_info "Consider running: ./build-missing-images.sh"
            fi
            
            print_success "RISC-V Dockerfile fixes completed!"
            print_info ""
            print_info "Next steps:"
            print_info "  1. Review the generated Dockerfile.riscv"
            print_info "  2. Build missing images: ./build-missing-images.sh"
            print_info "  3. Run the build: ./build-docker-riscv-v2.sh"
            ;;
    esac
}

# Check dependencies
if ! command -v docker &>/dev/null; then
    print_error "Docker is not installed or not in PATH"
    exit 1
fi

if ! command -v jq &>/dev/null; then
    print_warning "jq not found, some features may not work optimally"
    print_info "Install with: sudo apt install jq"
fi

main "$@"