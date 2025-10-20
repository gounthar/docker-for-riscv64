Name:           containerd
Version:        1.7.28
Release:        1%{?dist}
Summary:        Industry-standard container runtime for RISC-V64
License:        Apache-2.0
URL:            https://github.com/containerd/containerd
Source0:        containerd
Source1:        containerd-shim-runc-v2
Source2:        containerd.service

BuildArch:      riscv64
BuildRequires:  systemd-rpm-macros

Requires:       runc >= 1.3.0
Requires:       systemd
Requires(post): systemd
Requires(preun): systemd
Requires(postun): systemd

%description
Containerd is an industry-standard container runtime with an emphasis on
simplicity, robustness and portability. It is available as a daemon for Linux
and Windows, which can manage the complete container lifecycle of its host
system: image transfer and storage, container execution and supervision,
low-level storage and network attachments, etc.

This package provides containerd v%{version} built natively for RISC-V64
architecture.

%prep
# No preparation needed - pre-built binaries

%build
# No build needed - pre-built binaries

%install
# Create necessary directories
install -d %{buildroot}%{_bindir}
install -d %{buildroot}/usr/lib/systemd/system

# Install binaries
install -p -m 0755 %{SOURCE0} %{buildroot}%{_bindir}/containerd
install -p -m 0755 %{SOURCE1} %{buildroot}%{_bindir}/containerd-shim-runc-v2

# Install systemd unit file
install -p -m 0644 %{SOURCE2} %{buildroot}/usr/lib/systemd/system/containerd.service

%post
%systemd_post containerd.service

%preun
%systemd_preun containerd.service

%postun
%systemd_postun_with_restart containerd.service

%files
%{_bindir}/containerd
%{_bindir}/containerd-shim-runc-v2
/usr/lib/systemd/system/containerd.service

%changelog
* Mon Oct 20 2025 Bruno Verachten <gounthar@gmail.com> - 1.7.28-1
- Initial RPM packaging for RISC-V64
- Built from official containerd v1.7.28 source
- Pre-built binaries for BananaPi F3
