#!/bin/bash
# Generate docker-compose-plugin ebuild for RISC-V64 pre-built binaries
# Based on Debian docker-compose-plugin packaging
#
# Usage: ./generate-docker-compose-ebuild.sh <COMPOSE_VERSION> [OUTPUT_DIR] [CLI_VERSION]
# Example: ./generate-docker-compose-ebuild.sh 2.40.1 gentoo-overlay/app-containers/docker-compose 28.5.1

set -e

COMPOSE_VERSION="${1:-2.40.1}"
OUTPUT_DIR="${2:-gentoo-overlay/app-containers/docker-compose}"
CLI_VERSION="${3:-28.5.1}"

if [[ -z "${COMPOSE_VERSION}" ]]; then
    echo "Error: Compose version required." >&2
    echo "Usage: $0 <compose_version>" >&2
    exit 1
fi

echo "🔨 Generating docker-compose ${COMPOSE_VERSION} ebuild..."

# Create package directory
mkdir -p "${OUTPUT_DIR}"

# Generate ebuild
cat > "${OUTPUT_DIR}/docker-compose-${COMPOSE_VERSION}.ebuild" << 'EBUILD_EOF'
# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
#
# This ebuild provides Docker Compose v2 as a Docker CLI plugin
# using pre-built binaries for RISC-V64 architecture.

EAPI=8

DESCRIPTION="Docker Compose v2 - Pre-built plugin for RISC-V64"
HOMEPAGE="https://github.com/docker/compose https://github.com/gounthar/docker-for-riscv64"
SRC_URI="https://github.com/gounthar/docker-for-riscv64/releases/download/compose-v${PV}-riscv64/docker-compose -> ${P}-docker-compose"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~riscv"
IUSE=""
RESTRICT="strip"

# Requires Docker CLI to function as a plugin
RDEPEND="
	>=app-containers/docker-cli-CLI_VERSION_PLACEHOLDER
"

DEPEND="${RDEPEND}"

S="${WORKDIR}"

src_unpack() {
	# Binary is pre-built, nothing to unpack
	:
}

src_install() {
	# Install as Docker CLI plugin
	exeinto /usr/libexec/docker/cli-plugins
	newexe "${DISTDIR}/${P}-docker-compose" docker-compose

	# Backward compatibility: symlink to traditional location
	dosym ../libexec/docker/cli-plugins/docker-compose /usr/bin/docker-compose
}

pkg_postinst() {
	elog "Docker Compose ${PV} for RISC-V64 has been installed."
	elog ""
	elog "This is a pre-built binary from:"
	elog "  https://github.com/gounthar/docker-for-riscv64"
	elog ""
	elog "Docker Compose v2 is installed as a Docker CLI plugin:"
	elog "  /usr/libexec/docker/cli-plugins/docker-compose"
	elog ""
	elog "Usage:"
	elog "  docker compose up    (recommended)"
	elog "  docker-compose up    (legacy compatibility)"
	elog ""
	elog "Note: This requires app-containers/docker-cli to be installed."
}
EBUILD_EOF
# Replace version placeholder
sed -i "s/CLI_VERSION_PLACEHOLDER/${CLI_VERSION}/" "${OUTPUT_DIR}/docker-compose-${COMPOSE_VERSION}.ebuild"

# Create metadata.xml
cat > "${OUTPUT_DIR}/metadata.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE pkgmetadata SYSTEM "https://www.gentoo.org/dtd/metadata.dtd">
<pkgmetadata>
	<maintainer type="project">
		<email>docker-riscv64@example.com</email>
		<name>Docker for RISC-V64 Project</name>
		<description>Pre-built Docker Compose v2 binaries for RISC-V64</description>
	</maintainer>
	<upstream>
		<remote-id type="github">docker/compose</remote-id>
	</upstream>
</pkgmetadata>
EOF

echo "✅ docker-compose ebuild generated: ${OUTPUT_DIR}/docker-compose-${COMPOSE_VERSION}.ebuild"
