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
