Name:           moby-engine
Version:        28.5.1
Release:        1%{?dist}
Summary:        Docker Engine for RISC-V64 architecture
License:        Apache-2.0
URL:            https://github.com/moby/moby
Source0:        dockerd
Source1:        docker-proxy
Source2:        docker.service
Source3:        docker.socket

BuildArch:      riscv64
BuildRequires:  systemd-rpm-macros

Requires:       containerd >= 1.7.28
Requires:       runc >= 1.3.0
Requires:       iptables
Requires:       systemd
Requires:       libseccomp
Requires(post): systemd
Requires(preun): systemd
Requires(postun): systemd

Recommends:     ca-certificates
Recommends:     git
Recommends:     xz
Recommends:     docker-cli
Recommends:     tini

Conflicts:      docker-ce
Conflicts:      docker-engine
Provides:       docker-engine = %{version}-%{release}

%description
Docker is an open-source project to easily create lightweight, portable,
self-sufficient containers from any application. The same container that a
developer builds and tests on a laptop can run at scale, in production, on
VMs, bare metal, OpenStack clusters, public clouds and more.

This package contains Docker Engine v%{version} daemon (dockerd) and
docker-proxy, built natively for RISC-V64 architecture from the official
Moby project source code.

Built on BananaPi F3 running Fedora RISC-V64.

%prep
# No preparation needed - pre-built binaries

%build
# No build needed - pre-built binaries

%install
# Create necessary directories
install -d %{buildroot}%{_bindir}
install -d %{buildroot}/usr/lib/systemd/system

# Install binaries
install -p -m 0755 %{SOURCE0} %{buildroot}%{_bindir}/dockerd
install -p -m 0755 %{SOURCE1} %{buildroot}%{_bindir}/docker-proxy

# Install systemd unit files
install -p -m 0644 %{SOURCE2} %{buildroot}/usr/lib/systemd/system/docker.service
install -p -m 0644 %{SOURCE3} %{buildroot}/usr/lib/systemd/system/docker.socket

%pre
# Create docker group
getent group docker >/dev/null || groupadd -r docker

%post
%systemd_post docker.service docker.socket

%preun
%systemd_preun docker.service docker.socket

%postun
%systemd_postun_with_restart docker.service docker.socket

%files
%{_bindir}/dockerd
%{_bindir}/docker-proxy
/usr/lib/systemd/system/docker.service
/usr/lib/systemd/system/docker.socket

%changelog
* Mon Oct 20 2025 Bruno Verachten <gounthar@gmail.com> - 28.5.1-1
- Initial RPM packaging for RISC-V64
- Built from official Moby v28.5.1 source
- Pre-built binaries for BananaPi F3
