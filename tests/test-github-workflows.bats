#!/usr/bin/env bats

# Test suite for GitHub Actions workflow files

setup() {
    WORKFLOWS_DIR=".github/workflows"
    DOCKER_WEEKLY_BUILD="${WORKFLOWS_DIR}/docker-weekly-build.yml"
    TRACK_MOBY="${WORKFLOWS_DIR}/track-moby-releases.yml"
    TRACK_RUNNER="${WORKFLOWS_DIR}/track-runner-releases.yml"
}

# docker-weekly-build.yml Tests
@test "docker-weekly-build.yml exists and is readable" {
    [ -f "$DOCKER_WEEKLY_BUILD" ]
    [ -r "$DOCKER_WEEKLY_BUILD" ]
}

@test "docker-weekly-build.yml contains required workflow structure" {
    grep -q "^name:" "$DOCKER_WEEKLY_BUILD"
    grep -q "^on:" "$DOCKER_WEEKLY_BUILD"
    grep -q "^jobs:" "$DOCKER_WEEKLY_BUILD"
}

@test "docker-weekly-build.yml uses heredoc for release notes" {
    grep -q "cat > release-notes.md << EOF" "$DOCKER_WEEKLY_BUILD"
    grep -q "EOF" "$DOCKER_WEEKLY_BUILD"
}

@test "docker-weekly-build.yml uses --notes-file instead of inline notes" {
    grep -q "\-\-notes-file release-notes.md" "$DOCKER_WEEKLY_BUILD"
    ! grep -q "\-\-notes \"" "$DOCKER_WEEKLY_BUILD"
}

@test "docker-weekly-build.yml contains moby version in release notes" {
    grep -q "Moby Version:" "$DOCKER_WEEKLY_BUILD"
}

@test "docker-weekly-build.yml contains architecture info" {
    grep -q "Architecture: riscv64" "$DOCKER_WEEKLY_BUILD"
}

@test "docker-weekly-build.yml uses riscv64 runner" {
    grep -A 5 "runs-on:" "$DOCKER_WEEKLY_BUILD" | grep -q "riscv64"
}

@test "docker-weekly-build.yml has release step" {
    grep -q "gh release create" "$DOCKER_WEEKLY_BUILD"
}

@test "docker-weekly-build.yml uses GH_TOKEN for gh CLI" {
    grep -q "GH_TOKEN:" "$DOCKER_WEEKLY_BUILD"
}

# track-moby-releases.yml Tests
@test "track-moby-releases.yml exists and is readable" {
    [ -f "$TRACK_MOBY" ]
    [ -r "$TRACK_MOBY" ]
}

@test "track-moby-releases.yml uses heredoc for issue body" {
    grep -q "cat > issue-body.md << EOF" "$TRACK_MOBY"
    grep -q "EOF" "$TRACK_MOBY"
}

@test "track-moby-releases.yml uses --body-file instead of inline body" {
    grep -q "\-\-body-file issue-body.md" "$TRACK_MOBY"
    ! grep -q "\-\-body \"" "$TRACK_MOBY"
}

@test "track-moby-releases.yml creates GitHub issue" {
    grep -q "gh issue create" "$TRACK_MOBY"
}

@test "track-moby-releases.yml has build-request label" {
    grep -q "build-request" "$TRACK_MOBY"
}

@test "track-moby-releases.yml checks moby releases" {
    grep -q "moby/moby" "$TRACK_MOBY"
}

# track-runner-releases.yml Tests
@test "track-runner-releases.yml exists and is readable" {
    [ -f "$TRACK_RUNNER" ]
    [ -r "$TRACK_RUNNER" ]
}

@test "track-runner-releases.yml uses heredoc for issue body" {
    grep -q "cat > issue-body.md << EOF" "$TRACK_RUNNER"
    grep -q "EOF" "$TRACK_RUNNER"
}

@test "track-runner-releases.yml uses --body-file instead of inline body" {
    grep -q "\-\-body-file issue-body.md" "$TRACK_RUNNER"
    ! grep -q "\-\-body \"" "$TRACK_RUNNER"
}

@test "track-runner-releases.yml creates GitHub issue" {
    grep -q "gh issue create" "$TRACK_RUNNER"
}

@test "track-runner-releases.yml has maintenance label" {
    grep -q "maintenance" "$TRACK_RUNNER"
}

@test "track-runner-releases.yml checks runner releases" {
    grep -q "ChristopherHX/github-act-runner" "$TRACK_RUNNER"
}

# Cross-workflow validation tests
@test "all workflows use GH_TOKEN correctly" {
    for workflow in "$DOCKER_WEEKLY_BUILD" "$TRACK_MOBY" "$TRACK_RUNNER"; do
        if grep -q "gh " "$workflow"; then
            grep -q "GH_TOKEN:" "$workflow" || {
                echo "$workflow uses gh CLI but doesn't set GH_TOKEN"
                return 1
            }
        fi
    done
}

@test "heredoc EOF markers are properly closed" {
    for workflow in "$DOCKER_WEEKLY_BUILD" "$TRACK_MOBY" "$TRACK_RUNNER"; do
        local start_count=$(grep -c "<< EOF" "$workflow" || true)
        local end_count=$(grep -c "^          EOF$" "$workflow" || true)
        [ "$start_count" -eq "$end_count" ] || {
            echo "$workflow has mismatched heredoc markers: $start_count start, $end_count end"
            return 1
        }
    done
}

@test "release notes contain all required sections" {
    grep -A 30 "cat > release-notes.md" "$DOCKER_WEEKLY_BUILD" | grep -q "Moby Version:"
    grep -A 30 "cat > release-notes.md" "$DOCKER_WEEKLY_BUILD" | grep -q "Build Date:"
    grep -A 30 "cat > release-notes.md" "$DOCKER_WEEKLY_BUILD" | grep -q "Architecture:"
    grep -A 30 "cat > release-notes.md" "$DOCKER_WEEKLY_BUILD" | grep -q "Installation:"
}