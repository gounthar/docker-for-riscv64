#!/bin/bash
# Decide what to do about the latest upstream release of one component.
# Usage: TRACK_* variables set as below, then: bash track-release.sh
#
# Called by the .github/workflows/track-*-releases.yml trackers once they have
# looked up the latest upstream tag V. For V it applies this state machine:
#
#   Done      our release for V exists: close any open tracking issue for V.
#   Building  a run of the build workflow is queued or in progress: wait.
#             Runs cannot be mapped reliably to their input ref, so any
#             active run of the build workflow counts.
#   Retry     a tracking issue for V exists but no release: reopen it if it
#             was closed, re-dispatch the build and record the attempt as a
#             "Retry N of M:" comment. Once M retries are recorded, label the
#             issue build-failed and stop dispatching for V.
#   New       no tracking issue for V: dispatch the build and create one.
#
# Whatever the state, open tracking issues for older versions are closed as
# superseded.
#
# Configuration, from the environment:
#   TRACK_COMPONENT         name used in logs and comments (cagent)
#   TRACK_LATEST            upstream tag V (v1.141.0, docker-v29.8.1)
#   TRACK_LABEL             tracking issue label (cagent-release)
#   TRACK_TITLE_PREFIX      issue title before V ("Building cagent ")
#   TRACK_TITLE_SUFFIX      issue title after V (" for RISC-V64")
#   TRACK_BUILD_WORKFLOW    build workflow file (cagent-weekly-build.yml)
#   TRACK_BUILD_INPUT       workflow_dispatch input that receives V (cagent_ref)
#   TRACK_ISSUE_BODY        file with the body of a new tracking issue
#   TRACK_EXPECTED_TAG      our release tag for V (cagent-v1.141.0-riscv64)
#   TRACK_ENGINE_COMPONENT  instead of TRACK_EXPECTED_TAG, for components that
#                           ship inside the engine release: containerd or runc.
#                           V counts as built when any recent engine release
#                           lists it in its VERSIONS.txt asset.
#   TRACK_MAX_RETRIES       default 3
#   DRY_RUN                 true: log every write, perform none
#   GH_REPO                 owner/repo, defaults to GITHUB_REPOSITORY
#
# Every gh failure is fatal. An API error must never read as "no release" or
# "no issue": that is how failed builds used to be skipped for good.

set -euo pipefail

RETRY_COMMENT_REGEX='^Retry [0-9]+ of [0-9]+:'
# Left in the comment that closes an issue as done, so a later run can tell
# an issue this tracker finished from one that was closed some other way.
DONE_MARKER='<!-- track-release: done -->'
# Counted as the same thing: the comments the build workflows themselves
# leave when they close a tracking issue on a published release. Without
# them, every issue closed before this tracker existed would be reopened
# the day its release is pruned.
DONE_MARKERS="${DONE_MARKER}
Automatically closing - release published.
Automatically closing - included in Docker Engine build.
Automatically closed: Release"
FAILED_LABEL='build-failed'

# Logs go to stderr: several helpers print their result on stdout and are
# read with $(...), where a stray log line would become part of the value.
log() {
  echo "[${TRACK_COMPONENT:-track}] $*" >&2
}

die() {
  echo "Error: $*" >&2
  exit 1
}

# Record the outcome in the job summary as well as the log.
decide() {
  log "Decision for ${TRACK_LATEST}: $*"
  if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
    echo "**${TRACK_COMPONENT} ${TRACK_LATEST}**: $*" >>"$GITHUB_STEP_SUMMARY"
  fi
}

# Run a command that changes something, or only describe it in dry run.
act() {
  local what=$1
  shift
  if [ "$DRY_RUN" = "true" ]; then
    log "DRY RUN, would ${what}"
  else
    log "${what}"
    "$@"
  fi
}

# True when upstream tag $1 is older than $2. Only the numeric part counts,
# so docker-v29.8.0 < docker-v29.8.1, and a pre-release sorts before its
# release: v1.5.0-rc.1 < v1.5.0.
version_lt() {
  local a="${1#"${1%%[0-9]*}"}" b="${2#"${2%%[0-9]*}"}"
  local a_base="${a%%-*}" b_base="${b%%-*}" a_pre="" b_pre=""
  if [[ $a == *-* ]]; then a_pre="${a#*-}"; fi
  if [[ $b == *-* ]]; then b_pre="${b#*-}"; fi

  if [ "$a_base" != "$b_base" ]; then
    printf '%s\n%s\n' "$a_base" "$b_base" | sort -V -C
    return
  fi
  if [ -z "$a_pre" ]; then
    return 1
  fi
  if [ -z "$b_pre" ]; then
    return 0
  fi
  [ "$a_pre" != "$b_pre" ] && printf '%s\n%s\n' "$a_pre" "$b_pre" | sort -V -C
}

# Count the retry comments in one or more JSON arrays of issue comments on
# stdin (gh api --paginate prints one array per page).
count_retry_comments() {
  jq --arg re "$RETRY_COMMENT_REGEX" \
    '[.[] | select(.body | test($re))] | length' |
    awk '{ n += $1 } END { print n + 0 }'
}

# Count the comments carrying the marker left by handle_done, in one or more
# JSON arrays of issue comments on stdin. A count, not an exit status, so a
# jq or awk failure aborts the run instead of reading as "no marker".
count_done_markers() {
  jq --arg markers "$DONE_MARKERS" \
    '($markers | split("\n")) as $m
     | [.[] | select(.body as $b | any($m[]; . as $marker | $b | contains($marker)))]
     | length' \
    | awk '{ n += $1 } END { print n + 0 }'
}

# Print the version of $1 (containerd or runc) listed in a VERSIONS.txt on
# stdin, with a leading v to match upstream tags.
engine_component_version() {
  case "$1" in
  containerd)
    # containerd github.com/containerd/containerd/v2 v2.2.1 <sha>
    awk '$1 == "containerd" { print $3; exit }'
    ;;
  runc)
    # runc version 1.4.0
    awk '$1 == "runc" && $2 == "version" { print "v" $3; exit }'
    ;;
  *)
    die "unsupported engine component: $1"
    ;;
  esac
}

# Print the URL of our release for V, or nothing if it does not exist.
release_url() {
  local tag=$1 out
  if out=$(gh api "repos/${GH_REPO}/releases/tags/${tag}" --jq '.html_url' 2>"$ERR_FILE"); then
    echo "$out"
    return 0
  fi
  if grep -q 'HTTP 404' "$ERR_FILE"; then
    return 0
  fi
  cat "$ERR_FILE" >&2
  die "could not look up release ${tag}"
}

# Print the URL of an engine release whose VERSIONS.txt lists V, or nothing.
engine_release_url() {
  local releases tag url asset listed
  releases=$(gh api "repos/${GH_REPO}/releases?per_page=100" --jq '
    [.[]
     | select(.draft | not)
     | select(.tag_name | test("^v[0-9]+\\.[0-9]+\\.[0-9]+-riscv64$|^v[0-9]{8}-dev$"))]
    | sort_by(.published_at) | reverse | .[]
    | [.tag_name, .html_url,
       ([.assets[] | select(.name == "VERSIONS.txt") | .url] | first // "")]
    | @tsv')
  [ -n "$releases" ] || die "no engine release found in ${GH_REPO}"

  while IFS=$'\t' read -r tag url asset; do
    if [ -z "$asset" ]; then
      log "Engine release ${tag} has no VERSIONS.txt, skipping it"
    else
      listed=$(gh api -H 'Accept: application/octet-stream' "$asset" |
        engine_component_version "$TRACK_ENGINE_COMPONENT")
      log "Engine release ${tag} lists ${TRACK_ENGINE_COMPONENT} ${listed:-nothing}"
      if [ "$listed" = "$TRACK_LATEST" ]; then
        echo "$url"
        return 0
      fi
    fi
  done <<<"$releases"
}

ensure_label() {
  local name=$1 description=$2 color=$3
  if ! grep -qxF "$name" <<<"$LABELS"; then
    act "create label ${name}" \
      gh label create "$name" --description "$description" --color "$color"
    LABELS+=$'\n'"$name"
  fi
}

load_labels() {
  LABELS=$(gh label list --limit 500 --json name --jq '.[].name')
}

dispatch_build() {
  act "dispatch ${TRACK_BUILD_WORKFLOW} with ${TRACK_BUILD_INPUT}=${TRACK_LATEST}" \
    gh workflow run "$TRACK_BUILD_WORKFLOW" -f "${TRACK_BUILD_INPUT}=${TRACK_LATEST}"
}

close_superseded() {
  local open num title ver
  open=$(jq -r '.[] | select(.state == "OPEN") | [.number, .title] | @tsv' <<<"$ISSUES")
  while IFS=$'\t' read -r num title; do
    [ -n "$num" ] || continue
    [[ $title == "$TRACK_TITLE_PREFIX"*"$TRACK_TITLE_SUFFIX" ]] || continue
    ver=${title#"$TRACK_TITLE_PREFIX"}
    ver=${ver%"$TRACK_TITLE_SUFFIX"}
    [[ $ver =~ [0-9] ]] || continue
    [ "$ver" != "$TRACK_LATEST" ] || continue
    if version_lt "$ver" "$TRACK_LATEST"; then
      act "close #${num} (${ver}) as superseded by ${TRACK_LATEST}" \
        gh issue close "$num" --reason "not planned" \
        --comment "Superseded by ${TRACK_LATEST}; only the latest upstream release is built."
    fi
  done <<<"$open"
}

handle_done() {
  local url=$1 num
  for num in $(jq -r --arg t "$TITLE" \
    '.[] | select(.title == $t and .state == "OPEN") | .number' <<<"$ISSUES"); do
    act "close #${num}, built as ${url}" \
      gh issue close "$num" --comment "Built and released: ${url}

${DONE_MARKER}"
  done
  decide "done (${url})"
}

handle_retry() {
  local num=$1 state=$2 labels=$3 comments retries done_markers failed_run note=""

  if grep -qxF "$FAILED_LABEL" <<<"$labels"; then
    decide "given up: #${num} is labelled ${FAILED_LABEL}, not dispatching"
    return 0
  fi

  comments=$(gh api "repos/${GH_REPO}/issues/${num}/comments?per_page=100" --paginate)

  # An issue this tracker closed as done is terminal. The release it was
  # closed on may since have been deleted, by cleanup-old-dev-releases.yml
  # or by hand, and rebuilding for a deletion is not wanted.
  done_markers=$(count_done_markers <<<"$comments")
  if [ "$state" != "OPEN" ] && [ "$done_markers" -gt 0 ]; then
    decide "already built: #${num} was closed as done, not reopening"
    return 0
  fi

  retries=$(count_retry_comments <<<"$comments")

  failed_run=$(jq -r '
    [.[] | select(.status == "completed")
         | select(.conclusion == "failure" or .conclusion == "cancelled"
                  or .conclusion == "timed_out" or .conclusion == "startup_failure")]
    | first | if . then "\(.url) (\(.conclusion))" else "" end' <<<"$RUNS")
  if [ -n "$failed_run" ]; then
    note=" Latest failed or cancelled run of ${TRACK_BUILD_WORKFLOW}: ${failed_run}"
  fi

  if [ "$retries" -ge "$MAX_RETRIES" ]; then
    load_labels
    ensure_label "$FAILED_LABEL" "Automatic build retries exhausted" "B60205"
    act "label #${num} ${FAILED_LABEL} after ${retries} retries" \
      gh issue edit "$num" --add-label "$FAILED_LABEL"
    act "comment on #${num} that retries are exhausted" \
      gh issue comment "$num" --body "Giving up after ${retries} retries: no build produced ${EXPECTED}. The tracker will not dispatch ${TRACK_LATEST} again; it needs a manual look.${note}"
    decide "given up after ${retries} retries on #${num}"
    return 0
  fi

  if [ "$state" != "OPEN" ]; then
    act "reopen #${num}, ${EXPECTED} still missing" gh issue reopen "$num"
  fi
  dispatch_build
  act "comment retry $((retries + 1)) of ${MAX_RETRIES} on #${num}" \
    gh issue comment "$num" --body "Retry $((retries + 1)) of ${MAX_RETRIES}: the previous build did not produce ${EXPECTED}.${note}"
  decide "retry $((retries + 1)) of ${MAX_RETRIES} on #${num} (was ${state})"
}

handle_new() {
  [ -f "$TRACK_ISSUE_BODY" ] || die "issue body file not found: ${TRACK_ISSUE_BODY}"
  load_labels
  ensure_label "build-in-progress" "Build is currently in progress" "FFA500"
  ensure_label "$TRACK_LABEL" "${TRACK_COMPONENT} release tracking" "1E90FF"
  dispatch_build
  act "create issue \"${TITLE}\"" \
    gh issue create --title "$TITLE" --body-file "$TRACK_ISSUE_BODY" \
    --label "build-in-progress,${TRACK_LABEL}"
  decide "new: dispatched and opened a tracking issue"
}

main() {
  local var url active issue num state labels
  for var in gh jq; do
    command -v "$var" >/dev/null 2>&1 ||
      die "$var is required (gh: https://cli.github.com, jq: sudo apt-get install jq)"
  done
  for var in TRACK_COMPONENT TRACK_LATEST TRACK_LABEL TRACK_TITLE_PREFIX \
    TRACK_TITLE_SUFFIX TRACK_BUILD_WORKFLOW TRACK_BUILD_INPUT TRACK_ISSUE_BODY; do
    [ -n "${!var:-}" ] || die "$var is not set"
  done
  if [ -n "${TRACK_EXPECTED_TAG:-}" ] && [ -n "${TRACK_ENGINE_COMPONENT:-}" ]; then
    die "set TRACK_EXPECTED_TAG or TRACK_ENGINE_COMPONENT, not both"
  fi
  if [ -z "${TRACK_EXPECTED_TAG:-}" ] && [ -z "${TRACK_ENGINE_COMPONENT:-}" ]; then
    die "set TRACK_EXPECTED_TAG or TRACK_ENGINE_COMPONENT"
  fi

  export GH_REPO="${GH_REPO:-${GITHUB_REPOSITORY:-}}"
  [ -n "$GH_REPO" ] || die "GH_REPO or GITHUB_REPOSITORY must be set"
  DRY_RUN="${DRY_RUN:-false}"
  MAX_RETRIES="${TRACK_MAX_RETRIES:-3}"
  TITLE="${TRACK_TITLE_PREFIX}${TRACK_LATEST}${TRACK_TITLE_SUFFIX}"
  ERR_FILE=$(mktemp)
  trap 'rm -f "$ERR_FILE"' EXIT

  if [ -n "${TRACK_EXPECTED_TAG:-}" ]; then
    EXPECTED="release ${TRACK_EXPECTED_TAG}"
  else
    EXPECTED="an engine release listing ${TRACK_ENGINE_COMPONENT} ${TRACK_LATEST} in VERSIONS.txt"
  fi
  log "Upstream latest: ${TRACK_LATEST}; expecting ${EXPECTED}; dry run: ${DRY_RUN}"

  ISSUES=$(gh issue list --label "$TRACK_LABEL" --state all --limit 1000 \
    --json number,title,state,labels)

  if [ -n "${TRACK_EXPECTED_TAG:-}" ]; then
    url=$(release_url "$TRACK_EXPECTED_TAG")
  else
    url=$(engine_release_url)
  fi

  if [ -n "$url" ]; then
    handle_done "$url"
  else
    RUNS=$(gh run list --workflow "$TRACK_BUILD_WORKFLOW" --limit 30 \
      --json databaseId,status,conclusion,url,event,createdAt)
    active=$(jq -r '[.[] | select(.status != "completed")]
      | map("\(.url) (\(.status), \(.event))") | join(", ")' <<<"$RUNS")
    issue=$(jq -r --arg t "$TITLE" '
      [.[] | select(.title == $t)]
      | (map(select(.state == "OPEN")) | sort_by(.number))
        + (map(select(.state != "OPEN")) | sort_by(.number) | reverse)
      | first // empty
      | [.number, .state, ([.labels[].name] | join(","))] | @tsv' <<<"$ISSUES")

    if [ -n "$active" ]; then
      decide "building: ${TRACK_BUILD_WORKFLOW} has an active run, waiting (any active run counts, since a run cannot be mapped to its ref): ${active}"
    elif [ -n "$issue" ]; then
      IFS=$'\t' read -r num state labels <<<"$issue"
      handle_retry "$num" "$state" "${labels//,/$'\n'}"
    else
      handle_new
    fi
  fi

  close_superseded
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
