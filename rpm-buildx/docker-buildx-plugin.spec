Name:           docker-buildx-plugin
Version:        0.19.2
Release:        1%{?dist}
Summary:        Docker Buildx plugin for extended build capabilities on RISC-V64
License:        Apache-2.0
URL:            https://github.com/docker/buildx
Source0:        docker-buildx

BuildArch:      riscv64

Recommends:     docker-cli
Recommends:     docker-ce-cli

%description
Docker Buildx is a Docker CLI plugin that extends the docker build command
with the full BuildKit features.

Features include:
- Multi-platform builds (--platform flag)
- Advanced caching strategies
- Build-time secrets and SSH forwarding
- Remote builder support
- OCI exporter support
- Custom builder creation and management

This package provides Docker Buildx built natively for RISC-V64 architecture.

%prep
# No preparation needed - pre-built binaries

%build
# No build needed - pre-built binaries

%install
# Create necessary directories
install -d %{buildroot}%{_libexecdir}/docker/cli-plugins

# Install binary to plugin directory
install -p -m 0755 %{SOURCE0} %{buildroot}%{_libexecdir}/docker/cli-plugins/docker-buildx

%files
%{_libexecdir}/docker/cli-plugins/docker-buildx

%changelog
* Thu Nov 07 2024 Bruno Verachten <bruno@verachten.fr> - 0.19.2-1
- Initial RPM packaging for RISC-V64
- Built from official Docker Buildx v0.19.2 source
- Native compilation on RISC-V64 hardware
