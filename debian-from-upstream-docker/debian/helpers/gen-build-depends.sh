#!/bin/bash
set -eu
set -o pipefail

goBuildTags='apparmor cgo daemon pkcs11 selinux'

debDir="$PWD/debian"

debVer="$(dpkg-parsechangelog -SVersion)"
origVer="${debVer%-*}" # strip everything from the last dash
origVer="$(echo "$origVer" | sed -r 's/^[0-9]+://')" # strip epoch
upstreamVer="${origVer%%[+~]ds*}"
upstreamVer="${upstreamVer//[~]/-}"

goImportPath="$(awk -F ': ' '$1 == "XS-Go-Import-Path" { print $2; exit }' debian/control)"
[ "$goImportPath" ]

upstreamArchiveUri="https://$goImportPath/archive/v${upstreamVer}.tar.gz"

tempDir="$(mktemp -d -t debian-docker-gen-build-depends-XXXXXXXXXX)"
trap "rm -rf '$tempDir'" EXIT
cd "$tempDir"

mkdir -p "gopath/src/$goImportPath"
wget -qO archive.tar.gz "$upstreamArchiveUri"
tar \
	--extract \
	--file archive.tar.gz \
	--directory "gopath/src/$goImportPath" \
	--strip-components 1
export GOPATH="$PWD/gopath:$PWD/gopath/src/$goImportPath/vendor"
cd "gopath/src/$goImportPath"

IFS=$'\n'
# get the full list of "docker/docker" Go packages
goPkgs=( $(go list "$goImportPath/..." | grep -vE "^$goImportPath/vendor/") )
# get the list of their dependencies, normalized:
#   - skip stdlib, docker/docker
#   - adjust known hosting locations for their top-level repos
goDeps=( $(
	go list \
		-e \
		-tags "$goBuildTags" \
		-f '{{ join .Deps "\n" }}{{ "\n" }}{{ join .TestImports "\n" }}' \
		"${goPkgs[@]}" \
	| grep -vE '^$' \
	| grep -vE '^[^/]+$' \
	| grep -vE "^$goImportPath/" \
	| sort -u \
	| xargs \
		go list \
			-e \
			-f '{{ if not .Standard }}{{ .ImportPath }}{{ end }}' \
	| grep -vE '^$' \
	| sed -r \
		-e 's!^(github.com/[^/]+/[^/]+)/.*$!\1!' \
		-e 's!^(golang.org/x/[^/]+)/.*$!\1!' \
		-e 's!^(google.golang.org/[^/]+)/.*$!\1!' \
		-e 's!^(gopkg.in/[^/]+)/.*$!\1!' \
	| sort -u
) )
unset IFS

# converts a given "goPkg" into the relevant Debian "-dev" package name
debian_pkg() {
	local goPkg="$1"
	local domain="${goPkg%%/*}"
	domain="${domain%%.*}"
	local goPkgPath="${goPkg#*/}"
	local package="golang-$domain-${goPkgPath//\//-}-dev"
	package="${package,,}"
	echo "$package"
}

# converts "gitRepo" and "gitRef" into a concrete version number
git_version() {
	local goPkg="$1"; shift
	local gitRepo="$1"; shift
	local gitRef="$1"; shift

	[ "$gitRef" ] || return

	local gitSnapshotPrefix='0.0~git'

	# normalize a few "special" cases
	case "$goPkg=$gitRef" in
		github.com/docker/go=*-*-*-*)
			# turn "v1.5.1-1-1-gbaf439e" into "v1.5.1-1" so we can "ls-remote" and generate via commit instead of version
			local remoteCommit="$(git ls-remote "$gitRepo" "refs/tags/${gitRef%-*-*}" | cut -d$'\t' -f1)"
			if [ "$remoteCommit" ]; then
				gitRef="$remoteCommit"
			fi
			;;

		github.com/docker/libnetwork=v0.7.2-rc.1)
			# TODO get newer version in the archive
			gitRef='v0.7.0~rc.6'
			;;

		github.com/docker/distribution=467fc068d88aa6610691b7f1a677271a3fac4aac)
			# TODO get newer version in the archive (467fc068d88aa6610691b7f1a677271a3fac4aac really corresponds to v2.5.0-rc.1+)
			gitRef='v2.4.1'
			;;

		github.com/agl/ed25519=*)
			gitSnapshotPrefix='0~'
			;;

		github.com/docker/containerd=*|github.com/opencontainers/runc=*)
			# attempt to resolve commit to tag
			local remoteTag="$(git ls-remote --tags "$gitRepo" | awk -F '[\t/]' '$1 == "'"$gitRef"'" { print $4; exit }')"
			if [ "$remoteTag" ]; then
				gitRef="$remoteTag"
			fi
			# TODO get newer (compatible) versions of each of these into the archive
			case "$goPkg" in
				github.com/docker/containerd)
					gitRef='v0.2.1'
					;;
				github.com/opencontainers/runc)
					gitRef='v0.1.0'
					;;
			esac
			;;
	esac

	case "$gitRef" in
		v[0-9]*|[0-9].*)
			echo "${gitRef#v}"
			return
			;;
	esac

	local commitDate
	case "$goPkg" in
		github.com/*)
			# for GitHub repos, we can shortcut the date calculation (saves a _lot_ of time)
			local githubPatchUri="https://$goPkg/commit/$gitRef.patch"
			commitDate="$(wget -qO- "$githubPatchUri" | awk -F ': ' '$1 == "Date" { print $2 }' | tail -1)"
			# ".patch" returns potentially multiple commits, so we want the final "Date:" value, hence the "tail -1"
			;;

		*)
			mkdir -p "$tempDir/git/$goPkg"
			git clone --quiet "$gitRepo" "$tempDir/git/$goPkg"
			local commitUnix="$(git -C "$tempDir/git/$goPkg" log -1 --format='%at' "$gitRef" --)"
			commitDate="@$commitUnix"
			;;
	esac
	[ "$commitDate" ]
	commitDate="$(TZ=UTC date --date="$commitDate" +'%Y%m%d')"
	echo "$gitSnapshotPrefix$commitDate"
}

declare -A transitionals=(
	[golang-github-agl-ed25519-dev]='golang-ed25519-dev'
	[golang-github-coreos-etcd-dev]='golang-etcd-server-dev'
	[golang-github-go-check-check-dev]='golang-gopkg-check.v1-dev'
	[golang-github-godbus-dbus-dev]='golang-dbus-dev'
	[golang-github-golang-protobuf-dev]='golang-goprotobuf-dev'
	[golang-github-miekg-dns-dev]='golang-dns-dev'
	[golang-github-mistifyio-go-zfs-dev]='golang-go-zfs-dev'
	[golang-github-syndtr-gocapability-dev]='golang-gocapability-dev'
	[golang-github-ugorji-go-dev]='golang-github-ugorji-go-codec-dev'
	[golang-gopkg-fsnotify.v1-dev]='golang-github-fsnotify-fsnotify-dev'

	# golang-golang-x-oauth2 version 0.0~git20161103.0.36bc617-2 introduced a separate google/ package
	[golang-golang-x-oauth2-dev]='golang-golang-x-oauth2-google-dev'
)

for goDep in "${goDeps[@]}"; do
	if grep -q "^vendor/src/$goDep\$" "$debDir"/repack/keep/* 2>/dev/null; then
		# skip vendored deps we don't remove
		continue
	fi

	debPkg="$(debian_pkg "$goDep")"

	gitRepoRef="$(awk '$1 == "clone" && $2 == "git" && $3 == "'"$goDep"'" { print ($5 && $5 != "#" ? $5 : "") "=" $4; exit }' hack/vendor.sh)"
	gitRepo="${gitRepoRef%=*}"
	gitRef="${gitRepoRef##$gitRepo=}"
	: "${gitRepo:=https://$goDep}"

	debVer="$(git_version "$goDep" "$gitRepo" "$gitRef")"

	# deal with "golang-dns-dev" and friends of that nature
	transitional="${transitionals[$debPkg]:-}"
	if [ "$transitional" ]; then
		echo -n "$transitional${debVer:+ (>= ${debVer}~)} | "
	fi

	echo "$debPkg${debVer:+ (>= ${debVer}~)},"
done | sort
