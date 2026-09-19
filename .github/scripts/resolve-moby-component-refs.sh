#!/bin/bash
# Resolve the containerd and runc refs to build alongside a moby checkout
# Usage: resolve-moby-component-refs.sh <moby_dockerfile> <moby_label> [containerd_ref] [runc_ref]
#
# An empty containerd_ref or runc_ref means "use the version moby pins":
# the default of `ARG CONTAINERD_VERSION=` / `ARG RUNC_VERSION=` in moby's
# own Dockerfile, which is what moby builds its static binaries and runs its
# integration tests with. A non-empty value is an explicit override.
#
# <moby_label> only appears in the log, e.g. "docker-v29.8.1 (abc1234)".
#
# Output (stdout, and $GITHUB_OUTPUT when set):
#   containerd_ref=<ref>
#   containerd_source=<pinned by moby ...|explicit input>
#   runc_ref=<ref>
#   runc_source=<pinned by moby ...|explicit input>
#
# Exits 1 with an ::error:: annotation when a pin is needed and cannot be
# parsed. There is deliberately no hardcoded fallback: a silent fallback is
# how the engine kept shipping an old containerd and runc unnoticed.

set -euo pipefail

if [ $# -lt 2 ] || [ $# -gt 4 ]; then
  echo "Usage: $0 <moby_dockerfile> <moby_label> [containerd_ref] [runc_ref]" >&2
  exit 1
fi

DOCKERFILE="$1"
MOBY_LABEL="$2"
CONTAINERD_INPUT="${3:-}"
RUNC_INPUT="${4:-}"

# Set PIN to the default value of `ARG <name>=<value>` in moby's Dockerfile.
# Exactly one such line must exist, and the value must be a release tag
# (vX.Y.Z, optionally with a suffix) or a commit SHA.
# Errors go to stdout on purpose: not every runner implementation parses
# workflow commands such as ::error:: from stderr.
moby_pin() {
  local name="$1" matches count value
  PIN=
  if [ ! -f "$DOCKERFILE" ]; then
    echo "::error::moby Dockerfile not found at ${DOCKERFILE}, cannot read ${name}"
    return 1
  fi
  matches=$(grep -E "^[[:space:]]*ARG[[:space:]]+${name}=" "$DOCKERFILE" || true)
  count=$(printf '%s' "$matches" | grep -c . || true)
  if [ "$count" -ne 1 ]; then
    echo "::error::Expected exactly one 'ARG ${name}=' line in ${DOCKERFILE} (moby ${MOBY_LABEL}), found ${count}." \
      "Pass the ref explicitly or update this parser."
    return 1
  fi
  value="${matches#*=}"
  value="${value%%#*}"
  value="${value//[[:space:]\"\']/}"
  if ! [[ "$value" =~ ^v[0-9]+\.[0-9]+\.[0-9]+([-+.][0-9A-Za-z.-]+)?$ ||
    "$value" =~ ^[0-9a-f]{7,40}$ ]]; then
    echo "::error::Could not parse ${name} from ${DOCKERFILE} (moby ${MOBY_LABEL}): got '${value}'." \
      "Pass the ref explicitly or update this parser."
    return 1
  fi
  PIN="$value"
}

# resolve <component> <moby ARG name> <explicit input>
resolve() {
  local component="$1" arg="$2" input="$3" ref source
  if [ -n "$input" ]; then
    ref="$input"
    source="explicit input"
  else
    moby_pin "$arg"
    ref="$PIN"
    source="pinned by moby ${MOBY_LABEL}"
  fi
  echo "${component}: ${ref} (${source})"
  {
    echo "${component}_ref=${ref}"
    echo "${component}_source=${source}"
  } | tee -a "${GITHUB_OUTPUT:-/dev/null}"
}

resolve containerd CONTAINERD_VERSION "$CONTAINERD_INPUT"
resolve runc RUNC_VERSION "$RUNC_INPUT"
