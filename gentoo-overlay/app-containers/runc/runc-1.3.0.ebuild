# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
#
# This ebuild is based on the official Gentoo runc package but modified
# to use pre-built binaries for RISC-V64 architecture.
# Upstream: https://gitweb.gentoo.org/repo/gentoo.git/tree/app-containers/runc

EAPI=8

DOCKER_VERSION="28.5.1"

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
