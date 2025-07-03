#!/bin/bash
# Simple Dockerfile RISC-V Fix Script
# Fixes the specific issues in Docker's Dockerfile for RISC-V builds

set -e

print_info() { echo -e "\033[0;34m[INFO]\033[0m $1"; }
print_success() { echo -e "\033[0;32m[SUCCESS]\033[0m $1"; }
print_warning() { echo -e "\033[1;33m[WARNING]\033[0m $1"; }

DOCKERFILE=${1:-Dockerfile}
FIXED_DOCKERFILE="Dockerfile.riscv-fixed"

if [[ ! -f "$DOCKERFILE" ]]; then
    print_error "Dockerfile not found: $DOCKERFILE"
    exit 1
fi

print_info "Creating RISC-V-compatible Dockerfile: $FIXED_DOCKERFILE"

# Create backup
cp "$DOCKERFILE" "${DOCKERFILE}.backup"
print_info "Created backup: ${DOCKERFILE}.backup"

# Start with original file
cp "$DOCKERFILE" "$FIXED_DOCKERFILE"

# Fix the main issues:

# 1. Replace the problematic GOLANG_IMAGE variable with a working RISC-V image
print_info "Fixing GOLANG_IMAGE variable..."
sed -i 's|FROM --platform=\$BUILDPLATFORM \${GOLANG_IMAGE}|FROM --platform=\$BUILDPLATFORM ghcr.io/go-riscv/go:latest|g' "$FIXED_DOCKERFILE"

# 2. Comment out the xx cross-compilation tool
print_info "Disabling xx cross-compilation tool..."
sed -i 's|COPY --from=xx / /|# COPY --from=xx / / # Disabled for RISC-V native build|g' "$FIXED_DOCKERFILE"

# 3. Comment out any tonistiigi/xx references
sed -i 's|FROM.*tonistiigi/xx.*|# & # Disabled for RISC-V native build|g' "$FIXED_DOCKERFILE"

# 4. Remove any invalid syntax that might have been introduced by previous scripts
sed -i '/^\[INFO\]/d' "$FIXED_DOCKERFILE"
sed -i '/^\[WARNING\]/d' "$FIXED_DOCKERFILE"
sed -i '/^\[SUCCESS\]/d' "$FIXED_DOCKERFILE"
sed -i '/^\[ERROR\]/d' "$FIXED_DOCKERFILE"

# 5. Alternative: If you want to use the local golang image instead
print_info "Creating alternative with local golang image..."
cp "$FIXED_DOCKERFILE" "Dockerfile.local-golang"
sed -i 's|FROM --platform=\$BUILDPLATFORM ghcr.io/go-riscv/go:latest|FROM --platform=\$BUILDPLATFORM golang:1.24.4-bookworm|g' "Dockerfile.local-golang"

print_success "Created fixed Dockerfiles:"
print_info "  - $FIXED_DOCKERFILE (uses ghcr.io/go-riscv/go:latest)"
print_info "  - Dockerfile.local-golang (uses local golang:1.24.4-bookworm)"

print_info ""
print_info "Next steps:"
print_info "1. For community image: docker buildx bake binary -f docker-bake.hcl --file $FIXED_DOCKERFILE"
print_info "2. For local image: First run ./quick-golang-fix.sh, then use Dockerfile.local-golang"

# Create a simple build script
cat > build-with-fixed-dockerfile.sh << 'EOF'
#!/bin/bash
# Build script for fixed Dockerfile

set -e

print_info() { echo -e "\033[0;34m[INFO]\033[0m $1"; }
print_success() { echo -e "\033[0;32m[SUCCESS]\033[0m $1"; }
print_error() { echo -e "\033[0;31m[ERROR]\033[0m $1"; }

# Try building with the fixed Dockerfile
DOCKERFILE="Dockerfile.riscv-fixed"

if [[ ! -f "$DOCKERFILE" ]]; then
    print_error "Fixed Dockerfile not found. Run ./simple-dockerfile-fix.sh first"
    exit 1
fi

print_info "Attempting to build with $DOCKERFILE..."

# Method 1: Use buildx bake with the fixed Dockerfile
if docker buildx bake binary; then
    print_success "Build succeeded with buildx bake!"
    exit 0
fi

print_info "Buildx bake failed, trying direct docker build..."

# Method 2: Direct docker build
if docker build -f "$DOCKERFILE" -t moby-riscv .; then
    print_success "Direct docker build succeeded!"
    exit 0
fi

print_error "All build methods failed. Consider:"
print_error "1. Running ./quick-golang-fix.sh to build local golang image"
print_error "2. Using Dockerfile.local-golang instead"
EOF

chmod +x build-with-fixed-dockerfile.sh
print_success "Created build script: build-with-fixed-dockerfile.sh"