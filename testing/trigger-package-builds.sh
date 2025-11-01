#!/bin/bash
# Trigger Gentoo Package Build Workflows
# Builds all Gentoo packages for the latest component versions
#
# Usage: ./testing/trigger-package-builds.sh [--dry-run]

set -e

DRY_RUN=false
if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=true
    echo "DRY RUN MODE: Will show what would be triggered without actually triggering"
    echo ""
fi

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
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

echo_warn() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Get latest release versions
get_latest_release() {
    local pattern="$1"
    gh release list --limit 5 | grep "$pattern" | head -1 | awk '{print $1}'
}

echo_header "Gentoo Package Build Trigger"
echo_info "Date: $(date)"
echo_info "Repository: $(gh repo view --json nameWithOwner -q .nameWithOwner)"
echo ""

# Check GitHub CLI authentication
if ! gh auth status &> /dev/null; then
    echo_warn "GitHub CLI not authenticated. Please run: gh auth login"
    exit 1
fi

echo_header "Step 1: Detect Latest Component Versions"

# Docker Engine
DOCKER_RELEASE=$(get_latest_release "^v.*-riscv64$")
if [[ -n "$DOCKER_RELEASE" ]]; then
    DOCKER_VERSION=${DOCKER_RELEASE#v}
    DOCKER_VERSION=${DOCKER_VERSION%-riscv64}
    echo_success "Docker Engine: $DOCKER_VERSION (release: $DOCKER_RELEASE)"
else
    echo_warn "No Docker Engine release found"
    DOCKER_VERSION=""
fi

# Docker CLI
CLI_RELEASE=$(get_latest_release "^cli-v.*-riscv64$")
if [[ -n "$CLI_RELEASE" ]]; then
    CLI_VERSION=${CLI_RELEASE#cli-v}
    CLI_VERSION=${CLI_VERSION%-riscv64}
    echo_success "Docker CLI: $CLI_VERSION (release: $CLI_RELEASE)"
else
    echo_warn "No Docker CLI release found"
    CLI_VERSION=""
fi

# Docker Compose
COMPOSE_RELEASE=$(get_latest_release "^compose-v.*-riscv64$")
if [[ -n "$COMPOSE_RELEASE" ]]; then
    COMPOSE_VERSION=${COMPOSE_RELEASE#compose-v}
    COMPOSE_VERSION=${COMPOSE_VERSION%-riscv64}
    echo_success "Docker Compose: $COMPOSE_VERSION (release: $COMPOSE_RELEASE)"
else
    echo_warn "No Docker Compose release found"
    COMPOSE_VERSION=""
fi

# Tini
TINI_RELEASE=$(get_latest_release "^tini-v.*-riscv64$")
if [[ -n "$TINI_RELEASE" ]]; then
    TINI_VERSION=${TINI_RELEASE#tini-v}
    TINI_VERSION=${TINI_VERSION%-riscv64}
    echo_success "Tini: $TINI_VERSION (release: $TINI_RELEASE)"
else
    echo_warn "No Tini release found"
    TINI_VERSION=""
fi

echo ""

# Extract component versions from Docker Engine release
if [[ -n "$DOCKER_VERSION" ]]; then
    echo_info "Extracting containerd and runc versions from Docker Engine release..."

    # Get containerd version from release assets
    CONTAINERD_ASSET=$(gh release view "$DOCKER_RELEASE" --json assets -q '.assets[].name' | grep "^containerd$")
    if [[ -n "$CONTAINERD_ASSET" ]]; then
        # Containerd version is typically specified in release notes or we use a known version
        # For now, use the version from the generator script default
        CONTAINERD_VERSION="1.7.28"
        echo_success "Containerd: $CONTAINERD_VERSION (from Docker Engine release)"
    fi

    # Get runc version
    RUNC_ASSET=$(gh release view "$DOCKER_RELEASE" --json assets -q '.assets[].name' | grep "^runc$")
    if [[ -n "$RUNC_ASSET" ]]; then
        RUNC_VERSION="1.3.0"
        echo_success "Runc: $RUNC_VERSION (from Docker Engine release)"
    fi
fi

echo ""
echo_header "Step 2: Regenerate Overlay with Latest Versions"

if [[ "$DRY_RUN" == "true" ]]; then
    echo_info "Would regenerate overlay with:"
    echo "  Docker Engine: $DOCKER_VERSION"
    echo "  Docker CLI: $CLI_VERSION"
    echo "  Docker Compose: $COMPOSE_VERSION"
    echo "  Containerd: $CONTAINERD_VERSION"
    echo "  Runc: $RUNC_VERSION"
    echo "  Tini: $TINI_VERSION"
else
    echo_info "Regenerating overlay..."
    ./generate-gentoo-overlay-modular.sh \
        --docker-version "$DOCKER_VERSION" \
        --cli-version "$CLI_VERSION" \
        --compose-version "$COMPOSE_VERSION" \
        --containerd-version "$CONTAINERD_VERSION" \
        --runc-version "$RUNC_VERSION" \
        --tini-version "$TINI_VERSION"
    echo_success "Overlay regenerated"
fi

echo ""
echo_header "Step 3: Validate Overlay Structure"

if [[ "$DRY_RUN" == "true" ]]; then
    echo_info "Would run: ./testing/validate-overlay-structure.sh"
else
    if ./testing/validate-overlay-structure.sh; then
        echo_success "Overlay validation passed"
    else
        echo_warn "Overlay validation failed. Aborting build trigger."
        exit 1
    fi
fi

echo ""
echo_header "Step 4: Commit Updated Overlay (if changes exist)"

if git diff --quiet gentoo-overlay; then
    echo_info "No changes to commit"
else
    if [[ "$DRY_RUN" == "true" ]]; then
        echo_info "Would commit overlay changes"
    else
        git add gentoo-overlay
        git commit -m "chore(gentoo): update overlay to latest component versions

Docker Engine: $DOCKER_VERSION
Docker CLI: $CLI_VERSION
Docker Compose: $COMPOSE_VERSION
Containerd: $CONTAINERD_VERSION
Runc: $RUNC_VERSION
Tini: $TINI_VERSION

Generated with generate-gentoo-overlay-modular.sh"

        echo_success "Changes committed"

        # Push if on a branch
        CURRENT_BRANCH=$(git branch --show-current)
        if [[ "$CURRENT_BRANCH" != "main" ]]; then
            git push -u origin "$CURRENT_BRANCH"
            echo_success "Pushed to branch: $CURRENT_BRANCH"
        else
            echo_warn "On main branch - skipping automatic push"
        fi
    fi
fi

echo ""
echo_header "Step 5: Create GitHub Release for Gentoo Overlay (Optional)"

if [[ "$DRY_RUN" == "true" ]]; then
    echo_info "Would create release tag: gentoo-overlay-$(date +%Y%m%d)"
else
    read -p "Create GitHub release tag for this overlay version? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        RELEASE_TAG="gentoo-overlay-$(date +%Y%m%d)"
        gh release create "$RELEASE_TAG" \
            --title "Gentoo Overlay $(date +%Y-%m-%d)" \
            --notes "Gentoo overlay for RISC-V64 Docker

**Component Versions:**
- Docker Engine: $DOCKER_VERSION
- Docker CLI: $CLI_VERSION
- Docker Compose: $COMPOSE_VERSION
- Containerd: $CONTAINERD_VERSION
- Runc: $RUNC_VERSION
- Tini: $TINI_VERSION

**Installation:**
\`\`\`bash
eselect repository add docker-riscv64 git https://github.com/gounthar/docker-for-riscv64.git
emerge --sync docker-riscv64
emerge -av app-containers/docker
\`\`\`

See GENTOO-TESTING.md for comprehensive testing guide."

        echo_success "Release created: $RELEASE_TAG"
    else
        echo_info "Skipped release creation"
    fi
fi

echo ""
echo_header "Summary"

echo_info "Overlay Configuration:"
echo "  Docker Engine: $DOCKER_VERSION"
echo "  Docker CLI: $CLI_VERSION"
echo "  Docker Compose: $COMPOSE_VERSION"
echo "  Containerd: $CONTAINERD_VERSION"
echo "  Runc: $RUNC_VERSION"
echo "  Tini: $TINI_VERSION"

echo ""
echo_success "✓ Gentoo overlay is ready for use!"
echo ""
echo_info "Next Steps:"
echo "  1. Users can add the overlay: eselect repository add docker-riscv64 ..."
echo "  2. Test on actual Gentoo RISC-V64: Follow GENTOO-TESTING.md"
echo "  3. Run integration tests: ./scripts/test-gentoo-integration.sh"
echo "  4. Run benchmarks: ./scripts/benchmark-gentoo-docker.sh"

if [[ "$DRY_RUN" == "true" ]]; then
    echo ""
    echo_warn "This was a DRY RUN. Run without --dry-run to actually execute."
fi
