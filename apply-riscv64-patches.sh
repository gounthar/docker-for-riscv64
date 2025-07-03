#!/bin/bash
# Apply all riscv64 and trixie-related patches to the moby submodule.
# Usage: ./apply-riscv64-patches.sh

set -e

PATCH_DIR="patches"
RISCVDIR="riscv"
MOBYDIR="moby"

echo "Applying riscv64 and trixie patches to $MOBYDIR..."

# List of patches to apply (in order)
PATCHES=(
  "$PATCH_DIR/docker-bake.hcl.riscv64.patch"
  "$PATCH_DIR/.github-workflows-test.yml.riscv64.patch"
  "$PATCH_DIR/Dockerfile.riscv-trixie.patch"
  "$PATCH_DIR/Dockerfile.riscv-fixed-trixie.patch"
)

for patch in "${PATCHES[@]}"; do
  if [ -f "$patch" ]; then
    echo "Applying $patch..."
    patch -d "$MOBYDIR" -p0 < "$patch" || {
      echo "Warning: $patch may already be applied or failed to apply."
    }
  else
    echo "Patch file $patch not found, skipping."
  fi
done

echo "All patches applied (or attempted)."
