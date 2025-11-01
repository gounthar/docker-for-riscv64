#!/bin/bash
# Generate docker-cli ebuild for RISC-V64 pre-built binaries
# Based on upstream Gentoo docker-cli ebuild
#
# Usage: ./generate-docker-cli-ebuild.sh <CLI_VERSION>
# Example: ./generate-docker-cli-ebuild.sh 28.5.1

set -e

CLI_VERSION="${1:-28.5.1}"
OUTPUT_DIR="${2:-gentoo-overlay/app-containers/docker-cli}"

if [[ -z "${CLI_VERSION}" ]]; then
    echo "Error: CLI version required." >&2
    echo "Usage: $0 <cli_version>" >&2
    exit 1
fi

echo "🔨 Generating docker-cli ${CLI_VERSION} ebuild..."

# Create package directory
mkdir -p "${OUTPUT_DIR}"

# Generate ebuild
cat > "${OUTPUT_DIR}/docker-cli-${CLI_VERSION}.ebuild" << 'EBUILD_EOF'
# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
#
# This ebuild is based on the official Gentoo docker-cli package but modified
# to use pre-built binaries for RISC-V64 architecture.
# Upstream: https://gitweb.gentoo.org/repo/gentoo.git/tree/app-containers/docker-cli

EAPI=8

DESCRIPTION="the command line binary for docker - Pre-built for RISC-V64"
HOMEPAGE="https://www.docker.com/ https://github.com/gounthar/docker-for-riscv64"
SRC_URI="https://github.com/gounthar/docker-for-riscv64/releases/download/cli-v${PV}-riscv64/docker -> ${P}-docker"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~riscv"
IUSE="selinux"
RESTRICT="strip"

RDEPEND="
	selinux? ( sec-policy/selinux-docker )
"

DEPEND="${RDEPEND}"

S="${WORKDIR}"

src_unpack() {
	# Binary is pre-built, nothing to unpack
	:
}

src_install() {
	# Install binary
	newbin "${DISTDIR}/${P}-docker" docker
}

pkg_postinst() {
	elog "Docker CLI ${PV} for RISC-V64 has been installed."
	elog ""
	elog "This is a pre-built binary from:"
	elog "  https://github.com/gounthar/docker-for-riscv64"
	elog ""
	elog "To use Docker, you also need:"
	elog "  - app-containers/docker (Docker Engine daemon)"
	elog ""
	has_version "app-containers/docker-buildx" && return
	ewarn "the 'docker build' command is deprecated and will be removed in a"
	ewarn "future release. If you need this functionality, install"
	ewarn "app-containers/docker-buildx."
}
EBUILD_EOF

# Copy or create metadata.xml
if [[ -f "upstream-gentoo-ebuilds/app-containers/docker-cli/metadata.xml" ]]; then
    cp "upstream-gentoo-ebuilds/app-containers/docker-cli/metadata.xml" "${OUTPUT_DIR}/"
else
    cat > "${OUTPUT_DIR}/metadata.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE pkgmetadata SYSTEM "https://www.gentoo.org/dtd/metadata.dtd">
<pkgmetadata>
	<maintainer type="project">
		<email>gounthar@gmail.com</email>
		<name>Docker for RISC-V64 Project</name>
		<description>Pre-built Docker CLI binaries for RISC-V64</description>
	</maintainer>
	<upstream>
		<remote-id type="github">docker/cli</remote-id>
	</upstream>
	<use>
		<flag name="selinux">Enable SELinux policy support</flag>
	</use>
</pkgmetadata>
EOF
fi

echo "✅ docker-cli ebuild generated: ${OUTPUT_DIR}/docker-cli-${CLI_VERSION}.ebuild"
