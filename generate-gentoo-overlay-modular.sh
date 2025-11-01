#!/bin/bash
# Generate modular Gentoo overlay for RISC-V64 Docker packages
# This script generates separate packages following Gentoo's standard approach
#
# Usage: ./generate-gentoo-overlay-modular.sh [OPTIONS]
# Options:
#   --docker-version VERSION    Docker Engine version (default: 28.5.1)
#   --cli-version VERSION       Docker CLI version (default: 28.5.1)
#   --compose-version VERSION   Docker Compose version (default: 2.40.1)
#   --containerd-version VERSION Containerd version (default: 1.7.28)
#   --runc-version VERSION      Runc version (default: 1.3.0)
#   --tini-version VERSION      Tini version (default: 0.19.0)

set -e

# Default versions
DOCKER_VERSION="28.5.1"
CLI_VERSION="28.5.1"
COMPOSE_VERSION="2.40.1"
CONTAINERD_VERSION="1.7.28"
RUNC_VERSION="1.3.0"
TINI_VERSION="0.19.0"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --docker-version)
            DOCKER_VERSION="$2"
            shift 2
            ;;
        --cli-version)
            CLI_VERSION="$2"
            shift 2
            ;;
        --compose-version)
            COMPOSE_VERSION="$2"
            shift 2
            ;;
        --containerd-version)
            CONTAINERD_VERSION="$2"
            shift 2
            ;;
        --runc-version)
            RUNC_VERSION="$2"
            shift 2
            ;;
        --tini-version)
            TINI_VERSION="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

OVERLAY_DIR="gentoo-overlay"

echo "🔨 Generating modular Gentoo overlay for RISC-V64 Docker packages"
echo ""
echo "Versions:"
echo "  Docker Engine:  ${DOCKER_VERSION}"
echo "  Docker CLI:     ${CLI_VERSION}"
echo "  Docker Compose: ${COMPOSE_VERSION}"
echo "  containerd:     ${CONTAINERD_VERSION}"
echo "  runc:           ${RUNC_VERSION}"
echo "  tini:           ${TINI_VERSION}"
echo ""

# Clean and create overlay structure
rm -rf "${OVERLAY_DIR}"
mkdir -p "${OVERLAY_DIR}"/{metadata,profiles}

# Create repository metadata
cat > "${OVERLAY_DIR}/profiles/repo_name" << 'EOF'
docker-riscv64
EOF

cat > "${OVERLAY_DIR}/metadata/layout.conf" << 'EOF'
masters = gentoo
repo-name = docker-riscv64
thin-manifests = true
sign-manifests = false
EOF

echo "📦 Generating individual package ebuilds..."

# Generate containerd package
echo "  - containerd ${CONTAINERD_VERSION}..."
./scripts/generate-containerd-ebuild.sh "${CONTAINERD_VERSION}" "${DOCKER_VERSION}" "${OVERLAY_DIR}/app-containers/containerd" "${RUNC_VERSION}"

# Generate runc package
echo "  - runc ${RUNC_VERSION}..."
./scripts/generate-runc-ebuild.sh "${RUNC_VERSION}" "${DOCKER_VERSION}" "${OVERLAY_DIR}/app-containers/runc"

# Generate docker-cli package
echo "  - docker-cli ${CLI_VERSION}..."
./scripts/generate-docker-cli-ebuild.sh "${CLI_VERSION}" "${OVERLAY_DIR}/app-containers/docker-cli"

# Generate docker-compose package
echo "  - docker-compose ${COMPOSE_VERSION}..."
./scripts/generate-docker-compose-ebuild.sh "${COMPOSE_VERSION}" "${OVERLAY_DIR}/app-containers/docker-compose" "${CLI_VERSION}"

# Generate tini package
echo "  - tini ${TINI_VERSION}..."
./scripts/generate-tini-ebuild.sh "${TINI_VERSION}" "${OVERLAY_DIR}/sys-process/tini"

# Generate main Docker package (now with dependencies instead of bundled binaries)
echo "  - docker (engine) ${DOCKER_VERSION}..."
mkdir -p "${OVERLAY_DIR}/app-containers/docker/files"

# Copy service files from upstream
if [[ -d "upstream-gentoo-ebuilds/app-containers/docker/files" ]]; then
    cp -r upstream-gentoo-ebuilds/app-containers/docker/files/* "${OVERLAY_DIR}/app-containers/docker/files/"
fi

# Add daemon.json configuration
cat > "${OVERLAY_DIR}/app-containers/docker/files/daemon.json" << 'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF

# Generate modular Docker ebuild that depends on separate packages
cat > "${OVERLAY_DIR}/app-containers/docker/docker-${DOCKER_VERSION}.ebuild" << 'EBUILD_EOF'
# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
#
# This ebuild is based on the official Gentoo Docker package but modified
# to use pre-built binaries for RISC-V64 architecture.
# This is a modular package that depends on separate component packages.
# Upstream: https://github.com/gentoo/gentoo/tree/master/app-containers/docker

EAPI=8

inherit linux-info systemd

DESCRIPTION="Docker Engine - Pre-built binaries for RISC-V64 (modular package)"
HOMEPAGE="https://github.com/gounthar/docker-for-riscv64"
SRC_URI="
	https://github.com/gounthar/docker-for-riscv64/releases/download/v${PV}-riscv64/dockerd -> ${P}-dockerd
	https://github.com/gounthar/docker-for-riscv64/releases/download/v${PV}-riscv64/docker-proxy -> ${P}-docker-proxy
"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~riscv"
IUSE="+container-init +overlay2 systemd"
RESTRICT="strip"

# Runtime dependencies - now uses separate packages
RDEPEND="
	acct-group/docker
	>=net-firewall/iptables-1.4
	sys-process/procps
	>=dev-vcs/git-1.7
	>=app-arch/xz-utils-4.9
	sys-libs/libseccomp
	~app-containers/containerd-CONTAINERD_VERSION_PLACEHOLDER
	~app-containers/runc-RUNC_VERSION_PLACEHOLDER
	>=app-containers/docker-cli-CLI_VERSION_PLACEHOLDER
	systemd? ( sys-apps/systemd )
	container-init? ( >=sys-process/tini-TINI_VERSION_PLACEHOLDER[static] )
"

DEPEND="${RDEPEND}"

S="${WORKDIR}"

# Kernel configuration checks (from upstream Gentoo ebuild)
pkg_setup() {
	CONFIG_CHECK="
		~NAMESPACES ~NET_NS ~PID_NS ~IPC_NS ~UTS_NS
		~CGROUPS ~CGROUP_CPUACCT ~CGROUP_DEVICE ~CGROUP_FREEZER ~CGROUP_SCHED ~CPUSETS ~MEMCG
		~KEYS
		~VETH ~BRIDGE ~BRIDGE_NETFILTER
		~IP_NF_FILTER ~IP_NF_TARGET_MASQUERADE
		~NETFILTER_XT_MATCH_ADDRTYPE
		~NETFILTER_XT_MATCH_CONNTRACK
		~NETFILTER_XT_MATCH_IPVS
		~IP_NF_NAT ~NF_NAT
		~POSIX_MQUEUE
	"

	WARNING_POSIX_MQUEUE="CONFIG_POSIX_MQUEUE: required for bind-mounting /dev/mqueue"

	use overlay2 && CONFIG_CHECK+=" ~OVERLAY_FS"

	linux-info_pkg_setup
}

src_unpack() {
	# Binaries are pre-built, nothing to unpack
	:
}

src_install() {
	# Install Docker Engine binaries
	newbin "${DISTDIR}/${P}-dockerd" dockerd
	newbin "${DISTDIR}/${P}-docker-proxy" docker-proxy

	# Note: containerd, runc, and containerd-shim are provided by separate packages

	# Install systemd unit or OpenRC init
	if use systemd; then
		systemd_dounit "${FILESDIR}/docker.service"
	else
		newinitd "${FILESDIR}/docker.initd" docker
		newconfd "${FILESDIR}/docker.confd" docker
	fi

	# Install default configuration
	insinto /etc/docker
	doins "${FILESDIR}/daemon.json"

	# Create necessary directories
	keepdir /var/lib/docker
	keepdir /var/log/docker
}

pkg_postinst() {
	elog "Docker Engine ${PV} for RISC-V64 has been installed."
	elog ""
	elog "This is a modular package using pre-built binaries from:"
	elog "  https://github.com/gounthar/docker-for-riscv64"
	elog ""
	elog "Component packages installed:"
	elog "  - app-containers/containerd (container runtime)"
	elog "  - app-containers/runc (OCI runtime)"
	elog "  - app-containers/docker-cli (Docker CLI)"
	if use container-init; then
		elog "  - sys-process/tini (init process for --init flag)"
	fi
	elog ""
	elog "To use Docker, add yourself to the docker group:"
	elog "  usermod -aG docker <username>"
	elog ""
	elog "Start the Docker daemon:"
	if use systemd; then
		elog "  systemctl enable docker"
		elog "  systemctl start docker"
	else
		elog "  rc-update add docker default"
		elog "  rc-service docker start"
	fi
}
EBUILD_EOF

# Replace version placeholders
sed -i "s/CONTAINERD_VERSION_PLACEHOLDER/${CONTAINERD_VERSION}/" "${OVERLAY_DIR}/app-containers/docker/docker-${DOCKER_VERSION}.ebuild"
sed -i "s/RUNC_VERSION_PLACEHOLDER/${RUNC_VERSION}/" "${OVERLAY_DIR}/app-containers/docker/docker-${DOCKER_VERSION}.ebuild"
sed -i "s/CLI_VERSION_PLACEHOLDER/${CLI_VERSION}/" "${OVERLAY_DIR}/app-containers/docker/docker-${DOCKER_VERSION}.ebuild"
sed -i "s/TINI_VERSION_PLACEHOLDER/${TINI_VERSION}/" "${OVERLAY_DIR}/app-containers/docker/docker-${DOCKER_VERSION}.ebuild"

# Copy or create metadata.xml for Docker
if [[ -f "upstream-gentoo-ebuilds/app-containers/docker/metadata.xml" ]]; then
    cp "upstream-gentoo-ebuilds/app-containers/docker/metadata.xml" "${OVERLAY_DIR}/app-containers/docker/"
    # Add overlay maintainer info
    sed -i '/<\/maintainer>/a\	<maintainer type="project">\n\t\t<email>docker-riscv64@example.com</email>\n\t\t<name>Docker for RISC-V64 Project</name>\n\t\t<description>Maintainer of the docker-riscv64 overlay providing pre-built binaries.</description>\n\t</maintainer>' "${OVERLAY_DIR}/app-containers/docker/metadata.xml"
else
    cat > "${OVERLAY_DIR}/app-containers/docker/metadata.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE pkgmetadata SYSTEM "https://www.gentoo.org/dtd/metadata.dtd">
<pkgmetadata>
	<maintainer type="project">
		<email>docker-riscv64@example.com</email>
		<name>Docker for RISC-V64 Project</name>
		<description>Pre-built Docker Engine binaries for RISC-V64</description>
	</maintainer>
	<upstream>
		<remote-id type="github">moby/moby</remote-id>
	</upstream>
	<use>
		<flag name="container-init">Install sys-process/tini for --init support</flag>
		<flag name="overlay2">Enable overlay2 storage driver (requires kernel CONFIG_OVERLAY_FS)</flag>
	</use>
</pkgmetadata>
EOF
fi

# Generate README
cat > "${OVERLAY_DIR}/README.md" << 'README_EOF'
# Docker RISC-V64 Gentoo Overlay (Modular)

Pre-built Docker binaries for RISC-V64 architecture, packaged for Gentoo Linux using a modular approach.

## Architecture

This overlay follows Gentoo's standard packaging philosophy by providing separate packages for each Docker component:

- **app-containers/containerd** - Container runtime
- **app-containers/runc** - OCI runtime
- **app-containers/docker-cli** - Docker command-line interface
- **app-containers/docker-compose** - Docker Compose v2 plugin
- **app-containers/docker** - Docker Engine daemon (depends on above packages)
- **sys-process/tini** - Tiny init process for containers

## Installation

See the main project README for installation instructions:
https://github.com/gounthar/docker-for-riscv64#gentoo-installation

## Quick Start

```bash
# Add the overlay
eselect repository add docker-riscv64 git https://github.com/gounthar/docker-for-riscv64.git

# Sync the overlay
emerge --sync docker-riscv64

# Install Docker (will pull in all dependencies)
emerge -av app-containers/docker

# Optional: Install Docker Compose
emerge -av app-containers/docker-compose
```

## Package Management

Individual components can be updated independently:

```bash
# Update only containerd
emerge -av =app-containers/containerd-1.7.28

# Update only Docker CLI
emerge -av =app-containers/docker-cli-28.5.1

# Update Docker Engine (will check dependencies)
emerge -av =app-containers/docker-28.5.1
```

## Generation

This overlay is generated by `generate-gentoo-overlay-modular.sh` which:
1. Generates separate ebuilds for each component
2. Creates proper dependency relationships
3. Maintains compatibility with Gentoo's package structure

To regenerate:
```bash
./generate-gentoo-overlay-modular.sh \
  --docker-version 28.5.1 \
  --cli-version 28.5.1 \
  --compose-version 2.40.1 \
  --containerd-version 1.7.28 \
  --runc-version 1.3.0 \
  --tini-version 0.19.0
```

## Source

- Upstream Gentoo ebuilds: `upstream-gentoo-ebuilds/`
- Generation script: `generate-gentoo-overlay-modular.sh`
- Individual generators: `scripts/generate-*-ebuild.sh`
- Pre-built binaries: https://github.com/gounthar/docker-for-riscv64/releases

## Migration from Monolithic Package

If you previously used the monolithic docker package:

```bash
# Uninstall old monolithic package
emerge -C =app-containers/docker-28.5.1-r1

# Install new modular packages
emerge -av app-containers/docker
```

The new Docker package will automatically pull in all required component packages.
README_EOF

echo ""
echo "✅ Modular Gentoo overlay generated in ${OVERLAY_DIR}/"
echo ""
echo "Package structure:"
echo "  📦 app-containers/docker (${DOCKER_VERSION}) - Docker Engine daemon"
echo "  📦 app-containers/containerd (${CONTAINERD_VERSION}) - Container runtime"
echo "  📦 app-containers/runc (${RUNC_VERSION}) - OCI runtime"
echo "  📦 app-containers/docker-cli (${CLI_VERSION}) - Docker CLI"
echo "  📦 app-containers/docker-compose (${COMPOSE_VERSION}) - Compose v2 plugin"
echo "  📦 sys-process/tini (${TINI_VERSION}) - Init process"
echo ""
echo "Test installation:"
echo "  sudo mkdir -p /var/db/repos/docker-riscv64"
echo "  sudo cp -r ${OVERLAY_DIR}/* /var/db/repos/docker-riscv64/"
echo "  sudo emerge --sync"
echo "  emerge -av app-containers/docker"
