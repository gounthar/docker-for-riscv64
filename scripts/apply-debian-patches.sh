#!/bin/bash
#
# Apply RISC-V64 patches to upstream Debian docker.io packaging
#
# This script:
# 1. Copies debian/ from submodule to working directory
# 2. Applies our RISC-V64 specific patches
# 3. Prepares for dpkg-buildpackage
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEBIAN_SOURCE="$PROJECT_ROOT/upstream-debian-docker"
PATCHES_DIR="$PROJECT_ROOT/debian-patches"
WORK_DIR="$PROJECT_ROOT/debian-build-work"

echo "=== Applying Debian patches for RISC-V64 ==="
echo ""

# Check submodule exists
if [ ! -d "$DEBIAN_SOURCE/debian" ]; then
    echo "Error: Debian source not found. Run 'git submodule update --init'" >&2
    exit 1
fi

# Create working directory
echo "1. Creating working directory..."
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"

# Copy debian/ directory from submodule
echo "2. Copying upstream Debian packaging..."
cp -r "$DEBIAN_SOURCE/debian" "$WORK_DIR/"

# Apply patches
echo "3. Applying RISC-V64 patches..."
cd "$WORK_DIR"

if [ -f "$PATCHES_DIR/series" ]; then
    while IFS= read -r patch || [ -n "$patch" ]; do
        # Skip comments and empty lines
        [[ "$patch" =~ ^#.*$ ]] && continue
        [[ -z "$patch" ]] && continue

        echo "   Applying: $patch"
        if [ -f "$PATCHES_DIR/$patch" ]; then
            patch -p1 < "$PATCHES_DIR/$patch" || {
                echo "Error: Failed to apply $patch" >&2
                exit 1
            }
        else
            echo "Warning: Patch file not found: $PATCHES_DIR/$patch" >&2
        fi
    done < "$PATCHES_DIR/series"
else
    echo "Warning: No series file found at $PATCHES_DIR/series" >&2
fi

echo ""
echo "✓ Patches applied successfully!"
echo ""
echo "Working directory ready at: $WORK_DIR"
echo ""
echo "Next steps:"
echo "  1. Download pre-built binaries to $WORK_DIR"
echo "  2. cd $WORK_DIR && dpkg-buildpackage -us -uc -b"
echo ""
