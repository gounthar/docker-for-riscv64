#!/bin/bash
# Generate containerd ebuild for RISC-V64 pre-built binaries
# Based on upstream Gentoo containerd ebuild
#
# Usage: ./generate-containerd-ebuild.sh <CONTAINERD_VERSION> <DOCKER_ENGINE_VERSION> [OUTPUT_DIR] [RUNC_VERSION]
# Example: ./generate-containerd-ebuild.sh 1.7.28 28.5.1 gentoo-overlay/app-containers/containerd 1.3.0
set -e

CONTAINERD_VERSION="${1:-1.7.28}"
DOCKER_VERSION="${2:-28.5.1}"
OUTPUT_DIR="${3:-gentoo-overlay/app-containers/containerd}"
RUNC_VERSION="${4:-1.3.0}"

if [[ -z "${CONTAINERD_VERSION}" || -z "${DOCKER_VERSION}" ]]; then
    echo "Error: Both containerd and docker versions required." >&2
    echo "Usage: $0 <containerd_version> <docker_version>" >&2
    exit 1
fi

echo "🔨 Generating containerd ${CONTAINERD_VERSION} ebuild (from Docker ${DOCKER_VERSION})..."

# Create package directory
mkdir -p "${OUTPUT_DIR}/files"

# Copy service files from upstream if they exist
if [[ -d "upstream-gentoo-ebuilds/app-containers/containerd/files" ]]; then
    cp -r upstream-gentoo-ebuilds/app-containers/containerd/files/* "${OUTPUT_DIR}/files/" 2>/dev/null || true
fi

# Generate ebuild
cat > "${OUTPUT_DIR}/containerd-${CONTAINERD_VERSION}.ebuild" << 'EBUILD_EOF'
# Copyright 2022-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
#
# This ebuild is based on the official Gentoo containerd package but modified
# to use pre-built binaries for RISC-V64 architecture.
# Upstream: https://gitweb.gentoo.org/repo/gentoo.git/tree/app-containers/containerd

EAPI=8

inherit systemd

DOCKER_VERSION="DOCKER_VERSION_PLACEHOLDER"

DESCRIPTION="A daemon to control runC - Pre-built for RISC-V64"
HOMEPAGE="https://containerd.io/ https://github.com/gounthar/docker-for-riscv64"
SRC_URI="
	https://github.com/gounthar/docker-for-riscv64/releases/download/v${DOCKER_VERSION}-riscv64/containerd -> ${P}-containerd
	https://github.com/gounthar/docker-for-riscv64/releases/download/v${DOCKER_VERSION}-riscv64/containerd-shim-runc-v2 -> ${P}-containerd-shim-runc-v2
"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~riscv"
IUSE="systemd"
RESTRICT="strip"

# Runtime dependencies - simplified for pre-built binaries
RDEPEND="
	>=app-containers/runc-RUNC_VERSION_PLACEHOLDER
	systemd? ( sys-apps/systemd )
"

DEPEND="${RDEPEND}"

S="${WORKDIR}"

src_unpack() {
	# Binaries are pre-built, nothing to unpack
	:
}

src_install() {
	# Install binaries
	newbin "${DISTDIR}/${P}-containerd" containerd
	newbin "${DISTDIR}/${P}-containerd-shim-runc-v2" containerd-shim-runc-v2

	# Also install other containerd tools as links if needed
	# (ctr, containerd-stress are typically in upstream builds)

	# Install systemd unit or OpenRC init
	if use systemd; then
		if [[ -f "${FILESDIR}/containerd.service" ]]; then
			systemd_dounit "${FILESDIR}/containerd.service"
		else
			# Fallback: create minimal systemd unit
			cat > "${T}/containerd.service" << 'EOF'
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target local-fs.target

[Service]
ExecStartPre=-/sbin/modprobe overlay
ExecStart=/usr/bin/containerd

Type=notify
Delegate=yes
KillMode=process
Restart=always
RestartSec=5
LimitNPROC=infinity
LimitCORE=infinity
LimitNOFILE=infinity
TasksMax=infinity
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF
			systemd_dounit "${T}/containerd.service"
		fi
	else
		if [[ -f "${FILESDIR}/containerd.initd" ]]; then
			newinitd "${FILESDIR}/containerd.initd" containerd
		fi
		if [[ -f "${FILESDIR}/containerd.confd" ]]; then
			newconfd "${FILESDIR}/containerd.confd" containerd
		fi
	fi

	# Create necessary directories
	keepdir /var/lib/containerd
}

pkg_postinst() {
	elog "containerd ${PV} for RISC-V64 has been installed."
	elog ""
	elog "This is a pre-built binary from:"
	elog "  https://github.com/gounthar/docker-for-riscv64"
	elog ""
	elog "To use containerd, start the service:"
	if use systemd; then
		elog "  systemctl enable containerd"
		elog "  systemctl start containerd"
	else
		elog "  rc-update add containerd default"
		elog "  rc-service containerd start"
	fi
	elog ""
	elog "Note: This package requires app-containers/runc to be installed."
}
EBUILD_EOF

# Replace version placeholder
sed -i "s/DOCKER_VERSION_PLACEHOLDER/${DOCKER_VERSION}/" "${OUTPUT_DIR}/containerd-${CONTAINERD_VERSION}.ebuild"
sed -i "s/RUNC_VERSION_PLACEHOLDER/${RUNC_VERSION}/" "${OUTPUT_DIR}/containerd-${CONTAINERD_VERSION}.ebuild"

# Copy metadata.xml from upstream or create it
if [[ -f "upstream-gentoo-ebuilds/app-containers/containerd/metadata.xml" ]]; then
    cp "upstream-gentoo-ebuilds/app-containers/containerd/metadata.xml" "${OUTPUT_DIR}/"
else
    cat > "${OUTPUT_DIR}/metadata.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE pkgmetadata SYSTEM "https://www.gentoo.org/dtd/metadata.dtd">
<pkgmetadata>
	<maintainer type="project">
		<email>docker-riscv64@example.com</email>
		<name>Docker for RISC-V64 Project</name>
		<description>Pre-built containerd binaries for RISC-V64</description>
	</maintainer>
	<upstream>
		<remote-id type="github">containerd/containerd</remote-id>
	</upstream>
	<use>
		<flag name="systemd">Install systemd service unit</flag>
	</use>
</pkgmetadata>
EOF
fi

echo "✅ containerd ebuild generated: ${OUTPUT_DIR}/containerd-${CONTAINERD_VERSION}.ebuild"
