#!/bin/bash

# Print the git commit associated with a version, for a given component.

set -e
set -u

if [ $# -ne 2 ]; then
    echo >&2 "Usage: $0 COMPONENT UPSTREAM_VERSION"
    exit 1
fi

comp=$1
version=$2

# Get the "real" upstream version
version=$( debian/helpers/real-upstream-version.sh "$version" )

# Get corresponding git commit
awk -F ': ' '$1 == "'"$version"'" {print $2}' debian/helpers/${comp}-gitcommits
