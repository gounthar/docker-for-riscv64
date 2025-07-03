#!/usr/bin/env bats

# Failing test for riscv64 build script (TDD step)
# This test will fail until moby/build-docker-riscv64.sh is implemented.

@test "riscv64 build script exists and is executable" {
  run test -x "moby/build-docker-riscv64.sh"
  [ "$status" -eq 0 ]
}

@test "riscv64 build script --help returns usage" {
  run "moby/build-docker-riscv64.sh" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ "usage" || "$output" =~ "Usage" ]]
}
