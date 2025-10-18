#!/bin/bash

# Transform Debian's upstream version into the "real"
# upstream version. That is, remove the typical Debian
# extension '+dfsgX', and turns '~' back into '-'.

set -e
set -u

if [ $# -ne 1 ]; then
    echo >&2 "Usage: $0 UPSTREAM_VERSION"
    exit 1
fi

echo "$1" | sed -E \
    -e 's/\+(dfsg|ds)[0-9]+$//' \
    -e 's/~/-/g'
