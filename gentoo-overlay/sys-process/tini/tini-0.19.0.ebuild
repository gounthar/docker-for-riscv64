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
