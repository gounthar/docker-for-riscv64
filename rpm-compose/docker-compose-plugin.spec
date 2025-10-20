Name:           docker-compose-plugin
Version:        2.40.1
Release:        1%{?dist}
Summary:        Docker Compose v2 plugin for RISC-V64
License:        Apache-2.0
URL:            https://github.com/docker/compose
Source0:        docker-compose

BuildArch:      riscv64

Recommends:     docker-cli

Conflicts:      docker-compose
Provides:       docker-compose = %{version}-%{release}
Obsoletes:      docker-compose < 2.0.0

%description
Docker Compose is a tool for running multi-container applications on
Docker defined using the Compose file format. A Compose file is used
to define how one or more containers that make up your application
are configured.

This package provides Docker Compose v2 as a CLI plugin, built natively
for RISC-V64 architecture.

%prep
# No preparation needed - pre-built binaries

%build
# No build needed - pre-built binaries

%install
# Create necessary directories
install -d %{buildroot}%{_libexecdir}/docker/cli-plugins
install -d %{buildroot}%{_bindir}

# Install binary to plugin directory
install -p -m 0755 %{SOURCE0} %{buildroot}%{_libexecdir}/docker/cli-plugins/docker-compose

# Create backward compatibility symlink
ln -s %{_libexecdir}/docker/cli-plugins/docker-compose %{buildroot}%{_bindir}/docker-compose

%files
%{_libexecdir}/docker/cli-plugins/docker-compose
%{_bindir}/docker-compose

%changelog
* Mon Oct 20 2025 Bruno Verachten <gounthar@gmail.com> - 2.40.1-1
- Initial RPM packaging for RISC-V64
- Built from official Docker Compose v2.40.1 source
- Pre-built binaries for BananaPi F3
