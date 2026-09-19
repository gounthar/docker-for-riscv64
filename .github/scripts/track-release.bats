#!/usr/bin/env bats
# Unit tests for the pure helpers in track-release.sh.
# Run with: bats .github/scripts/track-release.bats

setup() {
  # shellcheck source=.github/scripts/track-release.sh
  source "${BATS_TEST_DIRNAME}/track-release.sh"
}

@test "retry count ignores comments that are not retry markers" {
  run count_retry_comments <<'EOF'
[
  {"body": "Retry 1 of 3: the previous build did not produce release cagent-v1.141.0-riscv64."},
  {"body": "Looks like a 502 on upload, see Retry 1 of 3: above"},
  {"body": "Retry 2 of 3: the previous build did not produce release cagent-v1.141.0-riscv64."},
  {"body": "retry 3 of 3: lower case is not ours"}
]
EOF
  [ "$status" -eq 0 ]
  [ "$output" = "2" ]
}

@test "retry count sums across paginated arrays" {
  run count_retry_comments <<'EOF'
[{"body": "Retry 1 of 3: x"}, {"body": "hello"}]
[{"body": "Retry 2 of 3: y"}, {"body": "Retry 3 of 3: z"}]
EOF
  [ "$status" -eq 0 ]
  [ "$output" = "3" ]
}

@test "retry count is zero for an issue without comments" {
  run count_retry_comments <<<'[]'
  [ "$status" -eq 0 ]
  [ "$output" = "0" ]
}

# expect_order A B: version_lt must hold for A,B and fail for B,A.
expect_order() {
  version_lt "$1" "$2" || { echo "expected $1 < $2"; return 1; }
  if version_lt "$2" "$1"; then
    echo "expected not $2 < $1"
    return 1
  fi
}

@test "version_lt orders numeric parts, not strings" {
  expect_order v1.9.0 v1.10.0
  expect_order v1.138.1 v1.141.0
  expect_order docker-v29.8.0 docker-v29.8.1
  expect_order docker-v29.8.1 docker-v29.10.0
}

@test "version_lt is false for equal versions" {
  run version_lt v1.141.0 v1.141.0
  [ "$status" -ne 0 ]
}

@test "version_lt puts a pre-release before its release" {
  expect_order v1.5.0-rc.1 v1.5.0
  expect_order v1.5.0-rc.1 v1.5.0-rc.2
  expect_order v1.4.9 v1.5.0-rc.1
}

@test "engine VERSIONS.txt parsing" {
  local versions='Docker version 29.8.0, build HEAD
docker-proxy (commit HEAD) version 29.8.0
containerd github.com/containerd/containerd/v2 v2.2.1 dea7da592f5d1d2b7755e3a161be07f43fad8f75
runc version 1.4.0
commit: v1.4.0-0-g8bd78a99'
  [ "$(engine_component_version containerd <<<"$versions")" = "v2.2.1" ]
  [ "$(engine_component_version runc <<<"$versions")" = "v1.4.0" ]
}
