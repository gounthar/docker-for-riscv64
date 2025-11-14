Name:           cagent
Version:        1.9.13
Release:        1%{?dist}
Summary:        Multi-agent AI runtime by Docker Engineering for RISC-V64
License:        ASL 2.0
URL:            https://github.com/docker/cagent
Source0:        cagent-linux-riscv64
Group:          Development/Tools
Packager:       Bruno Verachten <gounthar@gmail.com>

BuildArch:      riscv64

# rpmlint filters for Go binary expectations
%global __brp_strip %{nil}
%global __brp_strip_static_archive %{nil}
%global __brp_strip_comment_note %{nil}
%global _enable_debug_packages 0
%global debug_package %{nil}

%description
cagent is a powerful, easy to use, customizable multi-agent runtime that
orchestrates AI agents with specialized capabilities and tools.

Key features:
- Multi-agent architecture for domain-specific specialists
- MCP (Model Context Protocol) integration for external tools
- Smart task delegation between agents
- YAML-based declarative configuration
- Support for multiple AI providers (OpenAI, Anthropic, Gemini, xAI, Mistral)

This package provides cagent v%{version} built natively for RISC-V64
architecture. This is the first Linux distribution package for cagent.

%prep
# No preparation needed - pre-built binaries

%build
# No build needed - pre-built binaries

%install
# Create necessary directories
install -d %{buildroot}%{_bindir}

# Install binary
install -p -m 0755 %{SOURCE0} %{buildroot}%{_bindir}/cagent

%files
%{_bindir}/cagent

%changelog
* Thu Nov 14 2024 Bruno Verachten <gounthar@gmail.com> - 1.9.13-1
- Initial RPM packaging for RISC-V64
- Built from official cagent v1.9.13 source
- First Linux distribution package for cagent
- Multi-agent AI runtime by Docker Engineering
