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
	>=app-containers/docker-cli-20.10.0
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
