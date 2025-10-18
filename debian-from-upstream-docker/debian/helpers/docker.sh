#!/bin/bash

# Make it easy to build a docker image aimed at building the docker
# package, and the build the package, either as unprivileged user or
# as root. The idea with building as root is that it allows to run
# more unit tests.
#
# Copyright: Arnaud Rebillout <elboulangero@gmail.com>
# License: GPL-3+

set -e
set -u

DOCKER=docker
APT_PROXY=
IMAGE_TAG=${IMAGE_TAG:-debian/sid/docker-builder}
ACNG_PORT=${ACNG_PORT:-3142}

CMD=${1:-}
shift || :


## misc helpers

fail() {
    echo >&2 "$@"
    exit 1
}

user_in_docker_group() {
    id -Gn | grep -q '\bdocker\b'
}

apt_cacher_ng_running() {
    command -v nc >/dev/null 2>&1 || return 1
    nc -z localhost $1
}


## docker helpers

docker_build() {
    local opts=()

    [ "$APT_PROXY" ] && \
        opts+=("--build-arg" "http_proxy=$APT_PROXY")

    $DOCKER build \
        "${opts[@]}" \
        -t $IMAGE_TAG \
        .
}

docker_run_as_user() {
    $DOCKER run -it --rm \
        -u $(id -u):$(id -g) \
        -v /etc/group:/etc/group:ro \
        -v /etc/passwd:/etc/passwd:ro \
        -v $(pwd)/..:/usr/src/ \
        -w /usr/src/$(basename $(pwd)) \
        $IMAGE_TAG \
        "$@"
}

docker_run_as_root() {
    $DOCKER run -it --rm \
        --privileged \
        -v $(pwd)/..:/usr/src \
        -w /usr/src/$(basename $(pwd)) \
        $IMAGE_TAG \
        "$@"
}


## main

[ -d debian ] || \
    fail "No 'debian' directory. Please run from the root of the source tree"

if ! user_in_docker_group; then
    DOCKER='sudo docker'
    echo "You are not part of the docker group, running docker with '$DOCKER'"
fi

if apt_cacher_ng_running $ACNG_PORT; then
    APT_PROXY="http://172.17.0.1:$ACNG_PORT"
    echo "Detected local apt proxy, using $APT_PROXY as container proxy"
fi

case "$CMD" in
    (build)
        cd debian
        docker_build ;;
    (run-user)
        docker_run_as_user "$@" ;;
    (run-root)
        docker_run_as_root "$@" ;;
    (*)
        fail "Usage: $(basename $0) build | run-user [CMD] | run-root [CMD]" ;;
esac

# vim: et sts=4 sw=4
