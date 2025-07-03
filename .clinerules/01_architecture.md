# Repository Architecture Overview

This document provides a comprehensive architectural overview of the repository, focusing on its structure, the role of each part, and guidance on how to add support for a new architecture (such as RISC-V 64).

---

## 1. Top-Level Structure

```
.
├── docker-aliases.sh
├── repod.md
├── setup-report.txt
├── logs/
├── moby/
├── scripts/
```

- **docker-aliases.sh, repod.md, setup-report.txt**: Utility scripts and documentation for local setup and usage.
- **logs/**: Presumably contains build or runtime logs.
- **moby/**: The main Docker Engine source code and build system (upstream "moby" project).
- **scripts/**: Supplementary shell scripts, many related to RISC-V builds and automation.

---

## 2. The `moby/` Directory

This is the core of the repository, containing the Docker Engine source code, build scripts, configuration, and documentation.

### Key Files and Directories

- **.dockerignore, .gitignore, .gitattributes**: Standard ignore/config files.
- **AUTHORS, LICENSE, NOTICE, MAINTAINERS**: Project metadata and legal files.
- **README.md, ROADMAP.md, CONTRIBUTING.md, SECURITY.md, VENDORING.md, TESTING.md**: Documentation for users and contributors.
- **Makefile**: The main build orchestration file, likely used for compiling Docker, running tests, and managing builds for different architectures.
- **docker-bake.hcl**: Buildx Bake configuration for multi-platform builds.
- **Dockerfile, Dockerfile.* (e.g., Dockerfile.riscv, Dockerfile.debian-bookworm, Dockerfile.windows, etc.)**: Docker build instructions for various platforms and purposes.
- **Shell scripts (e.g., build-docker-riscv.sh, docker-riscv-native-build.sh, etc.)**: Scripts to automate building Docker for specific architectures, especially RISC-V.
- **go.mod, vendor.mod, vendor.sum**: Go module and vendoring configuration.

#### Source Code Subdirectories

- **api/**: API definitions, documentation, and server code.
- **builder/**: Code for Docker's build subsystem (Dockerfile parsing, build context, etc.).
- **cli/**: Command-line interface code.
- **client/**: Go client for interacting with the Docker Engine API.
- **container/**: Container runtime logic.
- **daemon/**: The main Docker daemon implementation.
- **distribution/**: Image distribution and registry logic.
- **dockerversion/**: Versioning information.
- **docs/**: Project documentation.
- **errdefs/**: Error definitions.
- **image/**: Image management logic.
- **integration/**, **integration-cli/**: Integration tests.
- **internal/**: Internal packages.
- **layer/**: Filesystem layer management.
- **libcontainerd/**, **libnetwork/**: Container runtime and networking libraries.
- **man/**: Man pages.
- **oci/**: OCI (Open Container Initiative) support.
- **opts/**: Option parsing utilities.
- **plugin/**: Plugin system.
- **project/**: Project-level utilities.
- **registry/**: Registry client/server code.
- **runconfig/**: Container run configuration.
- **testutil/**: Test utilities.
- **volume/**: Volume management.

---

## 3. The `scripts/` Directory

Contains shell scripts for:
- Building Docker for RISC-V (`quick-build.sh`, `quick-golang-fix.sh`, `master-docker-riscv-fix.sh`, etc.)
- Environment setup (`setup-env.sh`)
- Monitoring and testing (`monitor.sh`, `test-docker.sh`)
- Dockerfile patching/fixing for RISC-V (`dockerfile-riscv-fix-v2.sh`, `simple-dockerfile-fix.sh`)

These scripts are used to automate and patch the build process, especially for architectures not natively supported upstream.

---

## 4. How Each Part Works

### Build System

- **Makefile**: Central entry point for building, testing, and packaging Docker. It likely contains targets for different architectures and platforms.
- **docker-bake.hcl**: Used with Docker Buildx to orchestrate multi-platform builds, specifying how to build images for different architectures.
- **Dockerfiles**: Each Dockerfile is tailored for a specific platform or use case. For example, `Dockerfile.riscv` and `Dockerfile.riscv-fixed` are for RISC-V builds, while `Dockerfile.windows` is for Windows.
- **Shell Scripts**: Automate complex build steps, apply patches, or work around upstream limitations (especially for RISC-V).

### Source Code

- **api/**: Defines the REST API and its documentation.
- **builder/**: Handles Dockerfile parsing and build logic.
- **client/**: Provides a Go client for the Docker API.
- **daemon/**: The core Docker daemon logic.
- **Other subdirectories**: Implement various Docker subsystems (networking, storage, plugins, etc.).

### CI/CD

- **Not directly visible in the file list**, but typically, CI/CD configuration would be in `.github/workflows/`, `.gitlab-ci.yml`, or similar. The presence of `Makefile` and `docker-bake.hcl` suggests that CI/CD pipelines invoke these for building and testing across architectures.

---

## 5. Adding a New Architecture (e.g., RISC-V 64)

### General Steps

1. **Add/Update Dockerfiles**
   - Create a new Dockerfile for the target architecture (e.g., `Dockerfile.riscv64`).
   - Apply any necessary patches or workarounds (as seen with `Dockerfile.riscv-fixed`).

2. **Update Build Scripts**
   - Add or modify shell scripts to automate the build for the new architecture.
   - Ensure scripts handle cross-compilation, QEMU emulation, or native builds as needed.

3. **Modify Build Orchestration**
   - Update the `Makefile` to include targets for the new architecture.
   - Update `docker-bake.hcl` to define build groups and platforms for the new architecture.

4. **Update CI/CD Pipeline**
   - Ensure the CI/CD configuration builds, tests, and (optionally) publishes images for the new architecture.
   - Add jobs or steps for RISC-V 64, using QEMU or native runners as appropriate.

5. **Testing**
   - Add or update test scripts to run on the new architecture.
   - Use emulation or real hardware for integration tests.

6. **Documentation**
   - Update `README.md`, `TESTING.md`, and any other relevant docs to describe support for the new architecture.
   - Document any known issues, limitations, or special instructions.

### Example: RISC-V 64 in This Repository

- **Dockerfiles**: `Dockerfile.riscv`, `Dockerfile.riscv-fixed` are present.
- **Build Scripts**: `build-docker-riscv.sh`, `docker-riscv-native-build.sh`, and others automate the RISC-V build.
- **Patching Scripts**: Scripts like `dockerfile-riscv-fix-v2.sh` apply necessary fixes to upstream Dockerfiles for RISC-V compatibility.
- **Makefile/docker-bake.hcl**: Should be updated to include RISC-V as a build target.
- **Testing**: `test-docker.sh` and related scripts can be extended for RISC-V.
- **Documentation**: Should be updated to reflect RISC-V support and any caveats.

---

## 6. Summary Table

| Component                | Purpose                                                      | RISC-V Integration Example                |
|--------------------------|--------------------------------------------------------------|-------------------------------------------|
| `Dockerfile.*`           | Build instructions for each platform                         | `Dockerfile.riscv`, `Dockerfile.riscv-fixed` |
| Shell scripts            | Automate and patch build steps                               | `build-docker-riscv.sh`, `dockerfile-riscv-fix-v2.sh` |
| `Makefile`               | Build orchestration                                          | Add RISC-V targets                        |
| `docker-bake.hcl`        | Multi-platform build config                                  | Add RISC-V platform group                 |
| Source code subdirs      | Docker Engine implementation                                 | Usually architecture-agnostic, but may need tweaks |
| CI/CD config             | Automated build/test/deploy                                  | Add RISC-V jobs/steps                     |
| Documentation            | User and developer guidance                                  | Add RISC-V instructions                   |

---

## 7. How to Add a New Architecture: High-Level Steps

1. **Create/patch Dockerfiles for the new architecture.**
2. **Write or adapt build scripts for cross-compilation or native builds.**
3. **Update Makefile and build configs to include the new architecture.**
4. **Extend CI/CD to build, test, and publish for the new architecture.**
5. **Test thoroughly on the new architecture (emulated or real).**
6. **Document the process, requirements, and any limitations.**

---

## 8. References

- [Docker Buildx Bake documentation](https://docs.docker.com/build/bake/)
- [Docker multi-platform builds](https://docs.docker.com/build/building/multi-platform/)
- [Docker Moby upstream](https://github.com/moby/moby)

---

This architecture and process will allow you to systematically add support for new architectures, such as RISC-V 64, to the Docker Engine and its build pipeline.
