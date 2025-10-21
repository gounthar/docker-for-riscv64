Name:           tini
Version:        0.19.0
Release:        1%{?dist}
Summary:        A tiny but valid init for containers
License:        MIT
URL:            https://github.com/krallin/tini
Source0:        tini
Source1:        tini-static

BuildArch:      riscv64

%description
Tini is the simplest init you could think of.

All Tini does is spawn a single child (Tini is meant to be run in a container),
and wait for it to exit all the while reaping zombies and performing signal
forwarding.

This package provides tini v%{version} built natively for RISC-V64
architecture.

%package static
Summary:        Standalone static build of tini
Provides:       tini-static = %{version}-%{release}

%description static
This package contains a standalone static build of tini, statically linked with
glibc. It is meant to be used in environments where dynamic libraries are not
available or where you need a fully self-contained init process.

%prep
# No preparation needed - pre-built binaries

%build
# No build needed - pre-built binaries

%install
# Create necessary directories
install -d %{buildroot}%{_bindir}

# Install binaries
install -p -m 0755 %{SOURCE0} %{buildroot}%{_bindir}/tini
install -p -m 0755 %{SOURCE1} %{buildroot}%{_bindir}/tini-static

%files
%{_bindir}/tini

%files static
%{_bindir}/tini-static

%changelog
* Tue Oct 21 2025 Bruno Verachten <gounthar@gmail.com> - 0.19.0-1
- Initial RPM packaging for RISC-V64
- Built from official tini v0.19.0 source
- Split into main and static subpackages
