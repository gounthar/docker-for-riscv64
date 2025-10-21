# Docker RISC-V64 RPM Repository

This repository provides RPM packages for Docker Engine, containerd, and runc
built natively for RISC-V64 architecture.

## Installation

### Fedora/RHEL/Rocky Linux/AlmaLinux

1. Add the repository:

```bash
sudo curl -L https://gounthar.github.io/docker-for-riscv64/rpm/docker-riscv64.repo \
  -o /etc/yum.repos.d/docker-riscv64.repo
```

2. Install Docker:

```bash
sudo dnf install -y moby-engine docker-cli
```

3. Start Docker:

```bash
sudo systemctl enable --now docker
```

4. Verify installation:

```bash
docker --version
sudo docker run hello-world
```

## Packages Available

- **moby-engine** - Docker Engine daemon
- **containerd** - Container runtime
- **runc** - OCI runtime
- **docker-cli** - Docker command-line interface
- **docker-compose-plugin** - Docker Compose v2
- **tini** - Tiny but valid init for containers
- **tini-static** - Statically linked tini binary

## Manual Installation

If you prefer to install manually:

```bash
# Download packages
wget https://gounthar.github.io/docker-for-riscv64/rpm/fedora/riscv64/runc-*.riscv64.rpm
wget https://gounthar.github.io/docker-for-riscv64/rpm/fedora/riscv64/containerd-*.riscv64.rpm
wget https://gounthar.github.io/docker-for-riscv64/rpm/fedora/riscv64/moby-engine-*.riscv64.rpm

# Install in dependency order
sudo dnf install -y runc-*.riscv64.rpm
sudo dnf install -y containerd-*.riscv64.rpm
sudo dnf install -y moby-engine-*.riscv64.rpm
```

## Repository Structure

```
rpm/
├── docker-riscv64.repo       # Repository configuration
├── README.md                 # This file
└── fedora/
    └── riscv64/
        ├── *.rpm             # RPM packages
        └── repodata/         # Repository metadata
```

## Build Information

- Built on: BananaPi F3 running Fedora RISC-V64
- Source: https://github.com/gounthar/docker-for-riscv64
- Weekly builds every Sunday
- Automatic tracking of upstream Moby releases

## Support

For issues and questions:
- GitHub: https://github.com/gounthar/docker-for-riscv64/issues
