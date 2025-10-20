Name:           runc
Version:        1.3.0
Release:        1%{?dist}
Summary:        CLI tool for spawning and running containers on RISC-V64
License:        Apache-2.0
URL:            https://github.com/opencontainers/runc
Source0:        runc

BuildArch:      riscv64

Requires:       libseccomp

%description
runc is a CLI tool for spawning and running containers according to the OCI
(Open Container Initiative) specification. It is a formally specified
configuration format, governed by the Open Container Initiative under the
auspices of the Linux Foundation.

This package provides runc v%{version} built natively for RISC-V64
architecture.

%prep
# No preparation needed - pre-built binaries

%build
# No build needed - pre-built binaries

%install
# Create necessary directories
install -d %{buildroot}%{_bindir}

# Install binary
install -p -m 0755 %{SOURCE0} %{buildroot}%{_bindir}/runc

%files
%{_bindir}/runc

%changelog
* Mon Oct 20 2025 Bruno Verachten <gounthar@gmail.com> - 1.3.0-1
- Initial RPM packaging for RISC-V64
- Built from official runc v1.3.0 source
- Pre-built binaries for BananaPi F3
