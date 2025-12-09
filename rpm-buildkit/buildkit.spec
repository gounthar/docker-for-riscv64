Name:           buildkit
Version:        0.17.3
Release:        1%{?dist}
Summary:        Concurrent, cache-efficient, and Dockerfile-agnostic builder toolkit for RISC-V64
License:        Apache-2.0
URL:            https://github.com/moby/buildkit
Source0:        buildkitd
Source1:        buildctl

BuildArch:      riscv64

# BuildKit requires a container runtime (containerd) as its execution backend
Recommends:     containerd
# Docker is optional - only needed for docker buildx integration
Suggests:       docker-ce
Suggests:       moby-engine

%description
BuildKit is a toolkit for converting source code to build artifacts in an
efficient, expressive, and repeatable manner. It is the next-generation
container image builder, designed to be the backend for Docker Buildx and
multi-platform builds.

Features include:
- Automatic garbage collection
- Extendable frontend formats
- Concurrent dependency resolution
- Efficient instruction caching
- Build cache import/export
- Nested build job invocations
- Distributable workers
- Multiple output formats
- Pluggable architecture
- Execution without root privileges

This package contains:
- buildkitd: BuildKit daemon (server)
- buildctl: BuildKit CLI client

This package provides BuildKit built natively for RISC-V64 architecture.

%prep
# No preparation needed - pre-built binaries

%build
# No build needed - pre-built binaries

%install
# Create necessary directories
install -d %{buildroot}%{_bindir}

# Install binaries
install -p -m 0755 %{SOURCE0} %{buildroot}%{_bindir}/buildkitd
install -p -m 0755 %{SOURCE1} %{buildroot}%{_bindir}/buildctl

%files
%{_bindir}/buildkitd
%{_bindir}/buildctl

%changelog
* Mon Dec 09 2024 Bruno Verachten <bruno@verachten.fr> - 0.17.3-1
- Initial RPM packaging for RISC-V64
- Built from official moby/buildkit source
- Native compilation on RISC-V64 hardware
- Includes buildkitd daemon and buildctl CLI
