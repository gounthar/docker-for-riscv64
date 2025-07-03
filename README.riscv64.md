# RISC-V 64 Support for Docker (moby) Integration

This repository provides out-of-tree integration, build, and patch management for running Docker Engine (moby) on riscv64.

## How It Works

- The `moby/` directory is a submodule pointing to the official Docker (moby) repository.
- All riscv64 build scripts, Dockerfiles, tests, and patches live **outside** the submodule.
- Patches are applied to the submodule as needed, allowing easy updates to upstream Docker.

## Building for riscv64

1. **Initialize submodules** (if not already):
   ```
   git submodule update --init --recursive
   ```

2. **Apply patches**:
   ```
   patch -d moby -p1 < patches/docker-bake.hcl.riscv64.patch
   patch -d moby -p1 < patches/.github-workflows-test.yml.riscv64.patch
   # ...apply other patches as needed
   ```

3. **Build**:
   ```
   make riscv64
   ```
   This runs `build-docker-riscv64.sh`, which orchestrates the build.

## Testing

- Run the bats test:
  ```
  ./build-docker-riscv64.bats
  ```

- E2E/integration and CI/CD support for riscv64 is provided via patch files in `patches/`.

## Known Issues

- riscv64 support is experimental and may require QEMU or cross-compilation.
- Not all upstream Docker features may work on riscv64.
- Patches may need to be reapplied after updating the submodule.

## Contributing

- Do **not** edit files inside `moby/` directly.
- All riscv64 logic, scripts, and patches should live outside the submodule.
- See `patches/README.md` for patch management.
