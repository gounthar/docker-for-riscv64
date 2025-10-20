Name:           docker-cli
Version:        28.5.1
Release:        1%{?dist}
Summary:        Docker CLI for RISC-V64 architecture
License:        Apache-2.0
URL:            https://github.com/docker/cli
Source0:        docker

BuildArch:      riscv64

Recommends:     moby-engine
Recommends:     docker-compose-plugin

%description
Docker CLI is the command-line interface for Docker. It provides the docker
command used to interact with the Docker daemon.

This package provides Docker CLI v%{version} built natively for RISC-V64
architecture.

%prep
# No preparation needed - pre-built binaries

%build
# No build needed - pre-built binaries

%install
# Create necessary directories
install -d %{buildroot}%{_bindir}

# Install binary
install -p -m 0755 %{SOURCE0} %{buildroot}%{_bindir}/docker

%files
%{_bindir}/docker

%changelog
* Mon Oct 20 2025 Bruno Verachten <gounthar@gmail.com> - 28.5.1-1
- Initial RPM packaging for RISC-V64
- Built from official Docker CLI v28.5.1 source
- Pre-built binaries for BananaPi F3
