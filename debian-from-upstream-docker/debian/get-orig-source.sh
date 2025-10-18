#!/bin/bash
: <<=cut

=head1 DESCRIPTION

This script is called by uscan(1) as per "debian/watch" to download Multi
Upstream Tarball (MUT) components.

=head1 COPYRIGHT

Copyright: 2018-2019 Dmitry Smirnov <onlyjob@member.fsf.org>

=head1 LICENSE

License: GPL-3+
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 .
 This package is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 .
 You should have received a copy of the GNU General Public License
 along with this program. If not, see <http://www.gnu.org/licenses/>.

=cut

set -e
set -u

if [ "$1" = '--upstream-version' ]; then
    VERSION="$2"
else
    printf "E: missing argument '--upstream-version'.\n" 1>&2
    exit 1
fi

# components, with optional '=VERSION'
COMPONENTS=(
"docker/cli=v$( debian/helpers/real-upstream-version.sh "$VERSION" )"
"moby/buildkit"
)

DEB_SOURCE="$( dpkg-parsechangelog -SSource )"
#DEB_VERSION="$( dpkg-parsechangelog -SVersion )"
filename="$( readlink -f ../${DEB_SOURCE}_${VERSION}.orig.tar.xz )"
[ -s "${filename}" ] || exit 1

## _log() tries to mimic the style of uscan logs.
## However it does NOT separate between stdout (info)
## and stderr (warn, error), because uscan makes a mess
## of that (it seems like it displays the two streams
## one after another).
_log() {
    local prefix=$1; shift
    local first_line=1

    while [ $# -gt 0 ]; do
        if [ $first_line -eq 1 ]; then
            printf "get-orig-source ${prefix}: "
            first_line=0
        else
            printf "    "
        fi
        
        printf "%s\n" "$1"
        shift
    done 1>&2
}

info()  { _log 'info'  "$@"; }
warn()  { _log 'warn'  "$@"; }
error() { _log 'error' "$@"; }

drop_files_excluded() {
    local work_dir
    local files_excluded
    local file

    # remove files excluded:
    for work_dir in "$@"; do
        files_excluded=$( perl -0nE 'say $1 if m{^Files\-Excluded:\s*(.*?)(?:\n\n|^Files|^Comment)}sm;' debian/copyright )
        pushd "${work_dir}" >/dev/null
        for file in ${files_excluded}; do
            if [ -e "${file}" ]; then
                rm -fr "${file}"
            else
                warn "No files matched excluded pattern as the last matching glob: ${file}"
            fi
        done
        popd >/dev/null
    done

    # remove empty directories:
    if [ -d "${work_dir}"/vendor ]; then
        find "${work_dir}"/vendor -mindepth 1 -type d -empty -delete
    fi
}

## tarpack() takes two arguments:
##  1. directory to compress
##  2. tarball path/name
tarpack() {
    ( cd "$1" && \
      find -L . -xdev -type f -print | LC_ALL=C sort \
      | XZ_OPT="-6v" tar -caf "$2" -T- --owner=root --group=root --mode=a+rX \
    )
}

echo 1>&2 "========================================"
echo 1>&2 "$(basename $0) $@"
echo 1>&2 "========================================"

## prepare a workdir:
work_dir="$( mktemp -d -t get-orig-source_${DEB_SOURCE}_XXXXXXXX )"
trap "rm -rf '${work_dir}'" EXIT

## extract main tarball::
info "Unpack main tarball"
tar -xf "${filename}" -C "${work_dir}"

## make sure there's one and only one top directory:
topdir=$( ls -1 "${work_dir}" )
if [ $(echo "$topdir" | wc -l) -ne 1 ]; then
    error "Unexpected content in orig tarball"
    exit 1
fi

## move sources in a subdirectory:
mv "${work_dir}/${topdir}" "${work_dir}"/engine
mkdir "${work_dir}/${topdir}"
mv "${work_dir}"/engine "${work_dir}/${topdir}"

## drop excluded files:
# not needed, already done by uscan/mk-origtargz
# drop_files_excluded "${work_dir}"/${topdir}/engine

## repack:
info "Repack main tarball"
tarpack "${work_dir}" "${filename}"

## fetch Docker components:
for I in "${COMPONENTS[@]}"; do

    C=$(   echo ${I} | awk -F= '{print $1}' )
    REV=$( echo ${I} | awk -F= '{print $2}' )
    URL="github.com/${C}"

    if [ -z "$REV" ]; then
	# get revision from engine/vendor.mod
        REV=$( grep "${URL}" "${work_dir}"/*/engine/vendor.mod | head -1 | awk '{print $2}' | cut -d- -f3 )
    fi
    if [ -z "${REV}" ]; then
        error "Could not find commit for ${C}"
        exit 1
    fi

    COMP=${C##*/}
    FN="$( readlink -f ../${DEB_SOURCE}_${VERSION}.orig-${COMP}.tar.gz )"

    info "Process ${I}" "component = $COMP" "revision = $REV" "filename = $FN"

    if [ ! -s "${FN}" ]; then
        ## download tarball:
        archive_url="https://${URL}/archive/${REV}.tar.gz"
        info "Requesting URL:" "$archive_url"
        wget --quiet --tries=3 --timeout=40 --read-timeout=40 --continue \
            -O "${FN}" "$archive_url"
                    info "Successfully downloaded package: $(basename ${FN})"

        ## extract tarball:
        info "Unpack tarball:"
        component_dir="$( mktemp -d -t get-orig-source_XXXXXXXX )"
        mkdir "${component_dir}"/${COMP}
        tar -xf "${FN}" -C "${component_dir}"/${COMP} --strip-components=1

        ## drop excluded files:
        info "Drop excluded files:"
        drop_files_excluded "${component_dir}"/${COMP}

        ## repack:
        info "Repack tarball:"
        tarpack "${component_dir}" "${FN}"
        rm -rf "${component_dir}"

        ## make orig tarball:
        mkorigtargz_opts=(
            "--package" "${DEB_SOURCE}" "--version" "${VERSION}"
            "--rename" "--repack" "--compression" "xz" "--directory" ".."
            "--copyright-file" "debian/copyright" "--component" "${COMP}"
            "${FN}")
        info "Launch mk-origtargz with options:" "$(echo ${mkorigtargz_opts[@]})"
        mk-origtargz "${mkorigtargz_opts[@]}"
    fi
done

# vim: et sts=4 sw=4
