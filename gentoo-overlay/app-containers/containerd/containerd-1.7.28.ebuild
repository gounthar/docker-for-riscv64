# Copyright 2022-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
#
# This ebuild is based on the official Gentoo containerd package but modified
# to use pre-built binaries for RISC-V64 architecture.
# Upstream: https://gitweb.gentoo.org/repo/gentoo.git/tree/app-containers/containerd

EAPI=8

inherit systemd

DOCKER_VERSION="28.5.1"

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
	>=app-containers/runc-1.3.0
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
