#!/bin/bash
: <<=cut

=head1 DESCRIPTION

Unpack MUT components. Since devscripts 2.19.7, 'origtargz --unpack'
unpacks MUT components automatically, and this script is not needed
anymore. Also see #929786.

=head1 SYNOPSIS

 ./debian/helpers/unpack-components.sh

=cut

set -e
set -u

DEB_SOURCE="$( dpkg-parsechangelog -SSource )"
DEB_VERSION_UPSTREAM="$( dpkg-parsechangelog -SVersion | sed -e 's/-[^-]*$//' )"

if ls ../${DEB_SOURCE}_${DEB_VERSION_UPSTREAM}.orig-*.tar.* 2>>/dev/null; then
    for T in ../${DEB_SOURCE}_${DEB_VERSION_UPSTREAM}.orig-*.tar.*; do
        C="${T##*.orig-}"
        C="${C%%.tar*}"
        mkdir -p "${C}"
        tar xf ${T} -C "${C}" --strip-components=1
        if [ "$(ls -m ${C})" == "${C}" ]; then
            ## --strip-components=1 did not work.
            mv "${C}" "${C}.tmp"
            mv "${C}.tmp/${C}" .
            rmdir "${C}.tmp"
        fi
    done
else
    printf "W: no components to extract.\n"
    exit 0
fi
