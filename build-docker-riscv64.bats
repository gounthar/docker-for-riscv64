#!/usr/bin/env bats

# Unit test for riscv64 build script (root-level integration)
# This test checks the root-level build-docker-riscv64.sh script.

@test "riscv64 build script exists and is executable" {
  run test -x "./build-docker-riscv64.sh"
  [ "$status" -eq 0 ]
}

@test "riscv64 build script --help returns usage" {
  run "./build-docker-riscv64.sh" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ "usage" || "$output" =~ "Usage" ]]
}
