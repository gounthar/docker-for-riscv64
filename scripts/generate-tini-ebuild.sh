#!/bin/bash
# Generate tini ebuild for RISC-V64 pre-built binaries
# Based on upstream Gentoo tini ebuild
#
# Usage: ./generate-tini-ebuild.sh <TINI_VERSION>
# Example: ./generate-tini-ebuild.sh 0.19.0

set -e

TINI_VERSION="${1:-0.19.0}"
OUTPUT_DIR="${2:-gentoo-overlay/sys-process/tini}"

if [[ -z "${TINI_VERSION}" ]]; then
    echo "Error: Tini version required." >&2
    echo "Usage: $0 <tini_version>" >&2
    exit 1
fi

echo "🔨 Generating tini ${TINI_VERSION} ebuild..."

# Create package directory
mkdir -p "${OUTPUT_DIR}"

# Generate ebuild
cat > "${OUTPUT_DIR}/tini-${TINI_VERSION}.ebuild" << 'EBUILD_EOF'
# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
#
# This ebuild is based on the official Gentoo tini package but modified
# to use pre-built binaries for RISC-V64 architecture.
# Upstream: https://gitweb.gentoo.org/repo/gentoo.git/tree/sys-process/tini

EAPI=8

DESCRIPTION="A tiny but valid init for containers - Pre-built for RISC-V64"
HOMEPAGE="https://github.com/krallin/tini https://github.com/gounthar/docker-for-riscv64"
SRC_URI="
	https://github.com/gounthar/docker-for-riscv64/releases/download/tini-v${PV}-riscv64/tini -> ${P}-tini
	static? ( https://github.com/gounthar/docker-for-riscv64/releases/download/tini-v${PV}-riscv64/tini-static -> ${P}-tini-static )
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~riscv"
IUSE="+static"
RESTRICT="strip"

S="${WORKDIR}"

src_unpack() {
	# Binaries are pre-built, nothing to unpack
	:
}

src_install() {
	if use static; then
		# Install static binary as the main tini
		newbin "${DISTDIR}/${P}-tini-static" tini
	else
		# Install dynamic binary
		newbin "${DISTDIR}/${P}-tini" tini
	fi
}

pkg_postinst() {
	elog "tini ${PV} for RISC-V64 has been installed."
	elog ""
	elog "This is a pre-built binary from:"
	elog "  https://github.com/gounthar/docker-for-riscv64"
	elog ""
	if use static; then
		elog "Installed as: statically linked binary"
	else
		elog "Installed as: dynamically linked binary"
	fi
	elog ""
	elog "tini is used by Docker with the --init flag to act as"
	elog "PID 1 in containers and properly reap zombie processes."
}
EBUILD_EOF

# Copy or create metadata.xml
if [[ -f "upstream-gentoo-ebuilds/sys-process/tini/metadata.xml" ]]; then
    cp "upstream-gentoo-ebuilds/sys-process/tini/metadata.xml" "${OUTPUT_DIR}/"
else
    cat > "${OUTPUT_DIR}/metadata.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE pkgmetadata SYSTEM "https://www.gentoo.org/dtd/metadata.dtd">
<pkgmetadata>
	<maintainer type="project">
		<email>docker-riscv64@example.com</email>
		<name>Docker for RISC-V64 Project</name>
		<description>Pre-built tini binaries for RISC-V64</description>
	</maintainer>
	<upstream>
		<remote-id type="github">krallin/tini</remote-id>
	</upstream>
	<use>
		<flag name="static">Install statically linked binary</flag>
	</use>
</pkgmetadata>
EOF
fi

echo "✅ tini ebuild generated: ${OUTPUT_DIR}/tini-${TINI_VERSION}.ebuild"
