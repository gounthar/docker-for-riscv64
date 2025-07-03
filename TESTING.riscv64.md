# Testing riscv64 Support for Docker (moby)

This document describes how to test the riscv64 integration for Docker Engine (moby) in this repository.

## Unit Testing

- Run the bats test for the riscv64 build script:
  ```
  ./build-docker-riscv64.bats
  ```

## Integration & E2E Testing

- Apply the riscv64 patch to the bake file:
  ```
  patch -d moby -p1 < patches/docker-bake.hcl.riscv64.patch
  ```

- Run the E2E/integration tests for riscv64 via the patched bake/CI pipeline.
  - See the CI patch: `patches/.github-workflows-test.yml.riscv64.patch`
  - You can run the smoke/integration tests locally using:
    ```
    cd moby
    docker buildx bake binary-smoketest --set *.platform=linux/riscv64
    # Or use the patched workflow in your own GitHub Actions runner
    ```

## Requirements

- QEMU or native riscv64 hardware/emulation may be required for full testing.
- Cross-compilation may be used for building, but some tests require emulation.

## Notes

- All riscv64 test logic is out-of-tree; do not edit moby/TESTING.md directly.
- Update this file as new test scenarios or requirements are added.
