#!/bin/bash
# Generate runc ebuild for RISC-V64 pre-built binaries
# Based on upstream Gentoo runc ebuild
#
# Usage: ./generate-runc-ebuild.sh <RUNC_VERSION> <DOCKER_ENGINE_VERSION>
# Example: ./generate-runc-ebuild.sh 1.3.0 28.5.1

set -e

RUNC_VERSION="${1:-1.3.0}"
DOCKER_VERSION="${2:-28.5.1}"
OUTPUT_DIR="${3:-gentoo-overlay/app-containers/runc}"

if [[ -z "${RUNC_VERSION}" || -z "${DOCKER_VERSION}" ]]; then
    echo "Error: Both runc and docker versions required." >&2
    echo "Usage: $0 <runc_version> <docker_version>" >&2
    exit 1
fi

echo "🔨 Generating runc ${RUNC_VERSION} ebuild (from Docker ${DOCKER_VERSION})..."

# Create package directory
mkdir -p "${OUTPUT_DIR}"

# Generate ebuild
cat > "${OUTPUT_DIR}/runc-${RUNC_VERSION}.ebuild" << 'EBUILD_EOF'
# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
#
# This ebuild is based on the official Gentoo runc package but modified
# to use pre-built binaries for RISC-V64 architecture.
# Upstream: https://gitweb.gentoo.org/repo/gentoo.git/tree/app-containers/runc

EAPI=8

DOCKER_VERSION="DOCKER_VERSION_PLACEHOLDER"

DESCRIPTION="runc container cli tools - Pre-built for RISC-V64"
HOMEPAGE="https://github.com/opencontainers/runc/ https://github.com/gounthar/docker-for-riscv64"
SRC_URI="https://github.com/gounthar/docker-for-riscv64/releases/download/v${DOCKER_VERSION}-riscv64/runc -> ${P}-runc"

LICENSE="Apache-2.0 BSD-2 BSD MIT"
SLOT="0"
KEYWORDS="~riscv"
IUSE=""
RESTRICT="strip"

# Runtime dependencies (simplified - no build deps needed)
RDEPEND="
	sys-libs/libseccomp
	!app-emulation/docker-runc
"

DEPEND="${RDEPEND}"

S="${WORKDIR}"

src_unpack() {
	# Binary is pre-built, nothing to unpack
	:
}

src_install() {
	# Install binary
	newbin "${DISTDIR}/${P}-runc" runc
}

pkg_postinst() {
	elog "runc ${PV} for RISC-V64 has been installed."
	elog ""
	elog "This is a pre-built binary from:"
	elog "  https://github.com/gounthar/docker-for-riscv64"
	elog ""
	elog "runc is typically used by container runtimes like containerd."
}
EBUILD_EOF

# Replace version placeholder
sed -i "s/DOCKER_VERSION_PLACEHOLDER/${DOCKER_VERSION}/" "${OUTPUT_DIR}/runc-${RUNC_VERSION}.ebuild"

# Copy or create metadata.xml
if [[ -f "upstream-gentoo-ebuilds/app-containers/runc/metadata.xml" ]]; then
    cp "upstream-gentoo-ebuilds/app-containers/runc/metadata.xml" "${OUTPUT_DIR}/" 2>/dev/null || true
else
    cat > "${OUTPUT_DIR}/metadata.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE pkgmetadata SYSTEM "https://www.gentoo.org/dtd/metadata.dtd">
<pkgmetadata>
	<maintainer type="project">
		<email>docker-riscv64@example.com</email>
		<name>Docker for RISC-V64 Project</name>
		<description>Pre-built runc binaries for RISC-V64</description>
	</maintainer>
	<upstream>
		<remote-id type="github">opencontainers/runc</remote-id>
	</upstream>
</pkgmetadata>
EOF
fi

echo "✅ runc ebuild generated: ${OUTPUT_DIR}/runc-${RUNC_VERSION}.ebuild"
