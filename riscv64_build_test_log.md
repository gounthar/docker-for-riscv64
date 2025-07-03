# RISC-V 64 Manual Build and Test Log

_This file documents the results of manual build and test runs for riscv64 support._

## Date

YYYY-MM-DD

## Environment

- Host OS:
- QEMU version (if used):
- Cross-compiler version (if used):
- Native hardware (if used):

## Build Steps

1. Initialize submodules:
   ```
   git submodule update --init --recursive
   ```
2. Apply patches:
   ```
   patch -d moby -p1 < patches/docker-bake.hcl.riscv64.patch
   patch -d moby -p1 < patches/.github-workflows-test.yml.riscv64.patch
   ```
3. Build:
   ```
   make riscv64
   ```

## Test Steps

- Run bats test:
  ```
  ./build-docker-riscv64.bats
  ```
- Run E2E/integration tests (see TESTING.riscv64.md).

## Results

- Build output:
  ```
  [Paste relevant build output here]
  ```
- Test output:
  ```
  [Paste relevant test output here]
  ```

## Issues/Notes

- [Document any issues, workarounds, or observations here]
