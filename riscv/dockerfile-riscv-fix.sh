#!/bin/bash

# Dockerfile RISC-V Base Image Fix Script
# Version: 1.0
# Description: Automatically fixes base image issues in Docker builds for RISC-V

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Available RISC-V base images
declare -A RISCV_ALTERNATIVES=(
    ["golang:1.24.4-bookworm"]="ghcr.io/go-riscv/go:latest"
    ["golang:1.23-bookworm"]="ghcr.io/go-riscv/go:latest"
    ["golang:bookworm"]="ghcr.io/go-riscv/go:latest"
    ["golang:latest"]="ghcr.io/go-riscv/go:latest"
    ["ubuntu:20.04"]="riscv64/ubuntu:focal"
    ["ubuntu:22.04"]="riscv64/ubuntu:jammy"
    ["ubuntu:latest"]="riscv64/ubuntu:latest"
    ["debian:bookworm"]="riscv64/debian:bookworm"
    ["debian:bullseye"]="riscv64/debian:bullseye"
    ["debian:latest"]="riscv64/debian:sid"
    ["alpine:latest"]="riscv64/alpine:latest"
    ["alpine:3.18"]="riscv64/alpine:3.18"
    ["buildpack-deps:bookworm"]="riscv64/buildpack-deps:sid"
    ["node:18"]="riscv64/node:18"
    ["python:3.11"]="riscv64/python:3.11"
)

# Check if file exists and create backup
prepare_dockerfile() {
    local dockerfile="$1"

    if [[ ! -f "$dockerfile" ]]; then
        log_error "Dockerfile not found: $dockerfile"
        exit 1
    fi

    # Create backup if it doesn't exist
    if [[ ! -f "${dockerfile}.backup" ]]; then
        cp "$dockerfile" "${dockerfile}.backup"
        log_info "Created backup: ${dockerfile}.backup"
    fi
}

# Analyze Dockerfile for RISC-V compatibility issues
analyze_dockerfile() {
    local dockerfile="$1"

    log_info "Analyzing $dockerfile for RISC-V compatibility issues..."

    local issues_found=0
    local line_num=1

    while IFS= read -r line; do
        # Check for FROM statements with problematic base images
        if [[ $line =~ ^[[:space:]]*FROM[[:space:]]+([^[:space:]]+) ]]; then
            local base_image="${BASH_REMATCH[1]}"

            # Remove platform specification if present
            base_image="${base_image#*--platform=*[[:space:]]}"

            # Check if this base image has a RISC-V alternative
            for problematic_image in "${!RISCV_ALTERNATIVES[@]}"; do
                if [[ "$base_image" == *"$problematic_image"* ]]; then
                    log_warning "Line $line_num: Found problematic base image: $base_image"
                    log_info "  Suggested alternative: ${RISCV_ALTERNATIVES[$problematic_image]}"
                    ((issues_found++))
                fi
            done
        fi

        # Check for COPY --from=xx statements (cross-compilation tool)
        if [[ $line =~ COPY[[:space:]]+--from=xx ]]; then
            log_warning "Line $line_num: Found xx cross-compilation tool usage"
            log_info "  This may not work on RISC-V and should be commented out"
            ((issues_found++))
        fi

        ((line_num++))
    done < "$dockerfile"

    if [[ $issues_found -eq 0 ]]; then
        log_success "No obvious RISC-V compatibility issues found"
    else
        log_warning "Found $issues_found potential compatibility issues"
    fi

    return $issues_found
}

# Fix base images in Dockerfile
fix_base_images() {
    local dockerfile="$1"
    local output_file="${dockerfile}.riscv"

    log_info "Creating RISC-V compatible Dockerfile: $output_file"

    # Process the Dockerfile line by line
    while IFS= read -r line; do
        local modified_line="$line"
        local was_modified=false

        # Handle FROM statements
        if [[ $line =~ ^([[:space:]]*FROM[[:space:]]+)(.*) ]]; then
            local from_prefix="${BASH_REMATCH[1]}"
            local from_args="${BASH_REMATCH[2]}"

            # Extract platform and image parts
            if [[ $from_args =~ --platform=\$BUILDPLATFORM[[:space:]]+(.*) ]]; then
                # Keep BUILDPLATFORM for cross-compilation
                local image_part="${BASH_REMATCH[1]}"
                modified_line="${from_prefix}--platform=\$BUILDPLATFORM ${image_part}"
            else
                # Look for base image replacements
                for problematic_image in "${!RISCV_ALTERNATIVES[@]}"; do
                    if [[ $from_args == *"$problematic_image"* ]]; then
                        local alternative="${RISCV_ALTERNATIVES[$problematic_image]}"
                        modified_line="${from_prefix}${alternative}${from_args#*$problematic_image}"
                        was_modified=true
                        log_info "Replaced $problematic_image with $alternative"
                        break
                    fi
                done
            fi
        fi

        # Handle xx cross-compilation tool
        if [[ $line =~ COPY[[:space:]]+--from=xx ]]; then
            modified_line="# $line  # Disabled for RISC-V native build"
            was_modified=true
            log_info "Commented out xx cross-compilation tool usage"
        fi

        # Handle tonistiigi/xx image references
        if [[ $line =~ tonistiigi/xx ]]; then
            modified_line="# $line  # Disabled for RISC-V native build"
            was_modified=true
            log_info "Commented out tonistiigi/xx reference"
        fi

        echo "$modified_line"

    done < "$dockerfile" > "$output_file"

    log_success "Created RISC-V compatible Dockerfile: $output_file"
}

# Test if images are available
test_image_availability() {
    log_info "Testing availability of RISC-V base images..."

    local available_images=()
    local unavailable_images=()

    for image in "${RISCV_ALTERNATIVES[@]}"; do
        log_info "Testing $image..."
        if docker pull "$image" >/dev/null 2>&1; then
            available_images+=("$image")
            log_success "  ✓ Available"
        else
            unavailable_images+=("$image")
            log_warning "  ✗ Not available"
        fi
    done

    log_info "Summary:"
    log_success "Available images (${#available_images[@]}):"
    printf '  %s\n' "${available_images[@]}"

    if [[ ${#unavailable_images[@]} -gt 0 ]]; then
        log_warning "Unavailable images (${#unavailable_images[@]}):"
        printf '  %s\n' "${unavailable_images[@]}"
    fi
}

# Create a custom minimal Go base image
create_go_base_image() {
    log_info "Creating custom minimal Go base image for RISC-V..."

    local dockerfile_content='# Custom Go base image for RISC-V
FROM riscv64/debian:sid

# Install Go dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    git \
    wget \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Go manually
ENV GOLANG_VERSION=1.21.5
ENV GOPATH=/go
ENV PATH=$GOPATH/bin:/usr/local/go/bin:$PATH

# Note: We build Go from source since no official RISC-V binaries exist
RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"

# For now, install Go via package manager (may be older version)
RUN apt-get update && apt-get install -y golang-go && rm -rf /var/lib/apt/lists/*

WORKDIR $GOPATH'

    echo "$dockerfile_content" > Dockerfile.go-riscv

    log_info "Building custom Go base image..."
    if docker build -f Dockerfile.go-riscv -t go-riscv-custom:latest .; then
        log_success "Custom Go base image created: go-riscv-custom:latest"
    else
        log_error "Failed to create custom Go base image"
        return 1
    fi
}

# Generate build environment script
generate_build_script() {
    local build_script='#!/bin/bash

# Generated build script for RISC-V Docker build

set -e

log_info() { echo -e "\033[0;34m[INFO]\033[0m $1"; }
log_error() { echo -e "\033[0;31m[ERROR]\033[0m $1"; }

# Use the RISC-V compatible Dockerfile
if [[ -f "Dockerfile.riscv" ]]; then
    log_info "Using RISC-V compatible Dockerfile"
    export DOCKERFILE=Dockerfile.riscv
else
    log_error "RISC-V Dockerfile not found. Run dockerfile fix script first."
    exit 1
fi

# Set RISC-V specific build variables
export DOCKER_BUILDKIT=1
export BUILDPLATFORM=linux/riscv64
export TARGETPLATFORM=linux/riscv64

# Try different build approaches
log_info "Attempting Docker build with buildx..."
if docker buildx bake --file docker-bake.hcl binary; then
    log_info "Build successful with buildx"
    exit 0
fi

log_info "Buildx failed, trying direct docker build..."
if docker build -f ${DOCKERFILE:-Dockerfile.riscv} -t docker-riscv:latest .; then
    log_info "Build successful with docker build"
    exit 0
fi

log_error "All build methods failed"
exit 1
'

    echo "$build_script" > build-docker-riscv.sh
    chmod +x build-docker-riscv.sh
    log_success "Generated build script: build-docker-riscv.sh"
}

# Main function
main() {
    local dockerfile="${1:-Dockerfile}"

    log_info "Dockerfile RISC-V Base Image Fix Script"
    log_info "======================================"

    prepare_dockerfile "$dockerfile"

    if analyze_dockerfile "$dockerfile"; then
        log_info "Dockerfile appears to be RISC-V compatible already"
    else
        log_info "Fixing RISC-V compatibility issues..."
        fix_base_images "$dockerfile"
    fi

    # Test image availability
    test_image_availability

    # Generate build script
    generate_build_script

    log_success "RISC-V Dockerfile fixes completed!"
    log_info "Next steps:"
    log_info "  1. Review the generated Dockerfile.riscv"
    log_info "  2. Run: ./build-docker-riscv.sh"
    log_info "  3. If build fails, consider creating custom base image"
}

# Help function
show_help() {
    echo "Dockerfile RISC-V Base Image Fix Script"
    echo ""
    echo "Usage: $0 [OPTIONS] [DOCKERFILE]"
    echo ""
    echo "Arguments:"
    echo "  DOCKERFILE     Path to Dockerfile (default: ./Dockerfile)"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -t, --test     Test RISC-V image availability only"
    echo "  -c, --create   Create custom Go base image"
    echo "  -a, --analyze  Analyze Dockerfile only (no fixes)"
    echo ""
}

# Command line parsing
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    -t|--test)
        test_image_availability
        exit 0
        ;;
    -c|--create)
        create_go_base_image
        exit 0
        ;;
    -a|--analyze)
        analyze_dockerfile "${2:-Dockerfile}"
        exit 0
        ;;
    -*)
        echo "Unknown option: $1"
        show_help
        exit 1
        ;;
    *)
        main "$@"
        ;;
esac
