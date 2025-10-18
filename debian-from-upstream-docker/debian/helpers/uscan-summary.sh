#!/bin/bash

# Read the logs from uscan + get-orig-source, and display
# the list of Files-Excluded patterns that were not matched
# in any of the MUT components.
#
# Typical use-case: after bumping the package to a new version,
# run it to see which Files-Excluded patterns are now useless.
# You might want to remove those from the Files-Excluded list,
# and possibly remove their equivalent packages from the
# Build-Depends field.
#
# Usage:
#
#     uscan --verbose --download-current-version 2>&1 | tee uscan-logs
#     ./debian/helpers/uscan-summary.sh < uscan-logs
#
# Copyright: Arnaud Rebillout <elboulangero@gmail.com>
# License: GPL-3+

set -e
set -u

export LC_ALL=C

## key: component
## value: newline-separated list of unmatched patterns
declare -A COMPONENTS

assert_empty() {
    [ -z "$1" ] || exit 1
}

assert_nonempty() {
    [ -n "$1" ] || exit 1
}

comp=

## read uscan logs, get unmatched patterns for each component
while IFS= read -r line
do
    case "$line" in
        ('uscan info: Process watch file'*)
            assert_empty "$comp"
            comp=engine
            continue
            ;;
        ('get-orig-source info: Process'*)
            assert_nonempty "$comp"
            comp=
            continue
            ;;
        ('    component = '*)
            assert_empty "$comp"
            comp=$(echo "$line" | sed 's/.* = //')
            continue
            ;;
        (*'No files matched excluded pattern'*)
            pattern=$(echo "$line" | sed 's/.* excluded pattern .*: //')
            [ -n "${COMPONENTS[$comp]:-}" ] && COMPONENTS[$comp]+=$'\n'
            COMPONENTS[$comp]+="$pattern"
            continue
            ;;
    esac
done < /dev/stdin

#for comp in "${!COMPONENTS[@]}"; do
#    echo "==== ${comp^^} ===="
#    echo "${COMPONENTS[$comp]}"
#    echo ""
#done

## get unmatched patterns altogether, while removing the
## patterns with '~', as we expect those to be unmatched.
ALL_UNMATCHED_PATTERNS=$(printf '%s\n' ${COMPONENTS[@]} | grep -v '^~' | sort -u)

## useless patterns are those unmatched for all components
USELESS_PATTERNS=
for p in $ALL_UNMATCHED_PATTERNS; do
    useless=1
    for c in "${!COMPONENTS[@]}"; do
        if echo "${COMPONENTS[$c]}" | grep -qFx "$p"; then
            continue
        else
            useless=0
            break
        fi
    done
    if [ $useless -eq 1 ]; then
        [ -n "${USELESS_PATTERNS}" ] && USELESS_PATTERNS+=$'\n'
        USELESS_PATTERNS+="$p"
    fi
done

if [ -z "$USELESS_PATTERNS" ]; then
    echo "No useless patterns found in Files-Excluded. All good here."
else
    echo "The following patterns were not found in any of the MUT components."
    echo "They can probably be removed from Files-Excluded in d/copyright."
    echo
    echo "$USELESS_PATTERNS"
fi

# vim: et sts=4 sw=4
