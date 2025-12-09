#!/bin/bash
# Extract version from BuildKit release tag
# Usage: extract-buildkit-version.sh <release_tag>
# Output: Prints extracted version to stdout
#
# Supported formats:
#   buildkit-v20251209-dev     -> 0.0.20251209
#   buildkit-v0.17.3-riscv64   -> 0.17.3
#   buildkit-v0.17.3           -> 0.17.3

set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <release_tag>" >&2
  exit 1
fi

RELEASE_TAG="$1"

# Dev build: buildkit-v20251209-dev -> 0.0.20251209
if [[ "$RELEASE_TAG" =~ ^buildkit-v([0-9]{8})-dev$ ]]; then
  DATE_VER="${BASH_REMATCH[1]}"
  echo "0.0.${DATE_VER}"
# Official with suffix: buildkit-v0.17.3-riscv64 -> 0.17.3
elif [[ "$RELEASE_TAG" =~ ^buildkit-v([0-9]+\.[0-9]+\.[0-9]+)-riscv64$ ]]; then
  echo "${BASH_REMATCH[1]}"
# Official without suffix: buildkit-v0.17.3 -> 0.17.3
elif [[ "$RELEASE_TAG" =~ ^buildkit-v([0-9]+\.[0-9]+\.[0-9]+)$ ]]; then
  echo "${BASH_REMATCH[1]}"
else
  echo "Error: Unrecognized release tag format: $RELEASE_TAG" >&2
  echo "Expected formats: buildkit-vYYYYMMDD-dev, buildkit-vX.Y.Z-riscv64, or buildkit-vX.Y.Z" >&2
  exit 1
fi
