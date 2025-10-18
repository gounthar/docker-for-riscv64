#!/bin/bash

# List all vendored go packages in all of the MUT components,
# removing duplicates. It makes it easy to see what vendor
# directories are kept, and to spot anything that shouldn't
# be here.
#
# Typical use-case: after bumping the package to a new version,
# run it to see if new vendor directories were added by upstream.
# You might want to add those to the Files-Excluded list.
#
# Copyright: Arnaud Rebillout <elboulangero@gmail.com>
# License: GPL-3+

set -e
set -u

export LC_ALL=C

get_vendor_tree() {
    # Get the list of vendor directories. We distinguish two cases:
    # 1. github.com: we need granularity down to the package level,
    #    ie. 'github.com/containerd/aufs'
    # 2. others: we only need granularity to the project level,
    #    ie. 'code.cloudfoundry.org'

    local vendor_dir=$1/vendor
    local dirs=()
    local dir=

    if ! [ -d "$vendor_dir" ]; then
        return
    fi

    for dir in "$vendor_dir"/*; do
        if ! [ -d "$dir" ]; then
            continue
        fi
        case "$dir" in
            (*/github.com) ;&
            (*/golang.org)
                dirs+=($( find "$dir" -mindepth 2 -maxdepth 2 -type d ))
                ;;
            (*)
                dirs+=("$dir")
                ;;
        esac
    done

    if [ ${#dirs[@]} -eq 0 ]; then
        return
    fi

    printf "%s\n" "${dirs[@]}" \
        | sed 's;^.*/vendor/;vendor/;' \
        | sort -u
}

VD=     # vendor directories
ALLVD=  # all vendor directories

for d in *; do
    [ -d "$d" ] || continue
    [ "$d" = debian ] && continue
    VD=$( get_vendor_tree "$d" )
    #echo "==== ${d^^} ===="
    #echo "$VD"
    #echo
    ALLVD=$( printf '%s\n' $ALLVD $VD | sort -u )
done

if [ -z "$ALLVD" ]; then
    echo "Nothing in the vendor directories!"
else
    echo "List of vendor directories in all MUT components."
    echo "Anything that shouldn't be here must be added to Files-Excluded."
    echo ""
    echo "$ALLVD"
fi

# vim: et sts=4 sw=4
