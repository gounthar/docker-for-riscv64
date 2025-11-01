# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
#
# This ebuild is based on the official Gentoo Docker package but modified
# to use pre-built binaries for RISC-V64 architecture.
# Upstream: https://github.com/gentoo/gentoo/tree/master/app-containers/docker

EAPI=8

inherit linux-info systemd

DESCRIPTION="Docker Engine - Pre-built binaries for RISC-V64"
HOMEPAGE="https://github.com/gounthar/docker-for-riscv64"
SRC_URI="
	https://github.com/gounthar/docker-for-riscv64/releases/download/v${PV}-riscv64/dockerd -> ${P}-dockerd
	https://github.com/gounthar/docker-for-riscv64/releases/download/v${PV}-riscv64/docker-proxy -> ${P}-docker-proxy
	https://github.com/gounthar/docker-for-riscv64/releases/download/v${PV}-riscv64/containerd -> ${P}-containerd
	https://github.com/gounthar/docker-for-riscv64/releases/download/v${PV}-riscv64/containerd-shim-runc-v2 -> ${P}-containerd-shim-runc-v2
	https://github.com/gounthar/docker-for-riscv64/releases/download/v${PV}-riscv64/runc -> ${P}-runc
"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~riscv"
IUSE="+container-init +overlay2 systemd"
RESTRICT="strip"

# Runtime dependencies (simplified - no build deps needed)
RDEPEND="
	acct-group/docker
	>=net-firewall/iptables-1.4
	sys-process/procps
	>=dev-vcs/git-1.7
	>=app-arch/xz-utils-4.9
	sys-libs/libseccomp
	systemd? ( sys-apps/systemd )
	container-init? ( >=sys-process/tini-0.19.0[static] )
"

DEPEND="${RDEPEND}"

S="${WORKDIR}"

# Kernel configuration checks (from upstream Gentoo ebuild)
pkg_setup() {
	CONFIG_CHECK="
		~NAMESPACES ~NET_NS ~PID_NS ~IPC_NS ~UTS_NS
		~CGROUPS ~CGROUP_CPUACCT ~CGROUP_DEVICE ~CGROUP_FREEZER ~CGROUP_SCHED ~CPUSETS ~MEMCG
		~KEYS
		~VETH ~BRIDGE ~BRIDGE_NETFILTER
		~IP_NF_FILTER ~IP_NF_TARGET_MASQUERADE
		~NETFILTER_XT_MATCH_ADDRTYPE
		~NETFILTER_XT_MATCH_CONNTRACK
		~NETFILTER_XT_MATCH_IPVS
		~IP_NF_NAT ~NF_NAT
		~POSIX_MQUEUE
	"

	WARNING_POSIX_MQUEUE="CONFIG_POSIX_MQUEUE: required for bind-mounting /dev/mqueue"

	use overlay2 && CONFIG_CHECK+=" ~OVERLAY_FS"

	linux-info_pkg_setup
}

src_unpack() {
	# Binaries are pre-built, nothing to unpack
	:
}

src_install() {
	# Install binaries
	newbin "${DISTDIR}/${P}-dockerd" dockerd
	newbin "${DISTDIR}/${P}-docker-proxy" docker-proxy
	newbin "${DISTDIR}/${P}-containerd" containerd
	newbin "${DISTDIR}/${P}-containerd-shim-runc-v2" containerd-shim-runc-v2
	newbin "${DISTDIR}/${P}-runc" runc

	# Install systemd unit or OpenRC init
	if use systemd; then
		systemd_dounit "${FILESDIR}/docker.service"
	else
		newinitd "${FILESDIR}/docker.initd" docker
		newconfd "${FILESDIR}/docker.confd" docker
	fi

	# Install default configuration
	insinto /etc/docker
	doins "${FILESDIR}/daemon.json"

	# Create necessary directories
	keepdir /var/lib/docker
	keepdir /var/log/docker
}

pkg_postinst() {
	elog "Docker Engine ${PV} for RISC-V64 has been installed."
	elog ""
	elog "These are pre-built binaries from:"
	elog "  https://github.com/gounthar/docker-for-riscv64"
	elog ""
	elog "To use Docker, add yourself to the docker group:"
	elog "  usermod -aG docker <username>"
	elog ""
	elog "Start the Docker daemon:"
	if use systemd; then
		elog "  systemctl enable docker"
		elog "  systemctl start docker"
	else
		elog "  rc-update add docker default"
		elog "  rc-service docker start"
	fi
	elog ""
	elog "Note: containerd and runc are bundled with this package."
}
