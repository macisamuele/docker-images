#!/usr/bin/env bash
# This script requires bash v4.0+ (due to associative arrays)

DOCKER="${DOCKER:-docker}"
DOCKER_IMAGE_PREFIX="${DOCKER_USERNAME:-macisamuele}/"
DOCKER_TAG_PREFIX="$(git diff-index --quiet HEAD || echo 'dirty-')"
DOCKER_TAG="$(git rev-parse --short HEAD)"
export DOCKER DOCKER_TAG_PREFIX DOCKER_TAG

declare -A DOCKERFILE_EXTENSIONS=( \
    [amd64]=linux-amd64 \
    [armhf]=linux-arm-v7 \
)
declare -A DOCKER_MANIFEST_ANNOTATIONS=( \
    [amd64]="--os linux --arch amd64" \
    [armhf]="--os linux --arch arm --variant v7" \
)
declare -A QEMU_USER_STATIC_FILES=( \
    [amd64]=qemu-x86_64-static \
    [armhf]=qemu-arm-static \
)

if [ "${DEBUG:-}" != "" ]; then
    # If debug is enabled then docker commands are only echoed
    export DOCKER="echo ${DOCKER}"
fi

function git_root_directory() {
    git rev-parse --show-toplevel
}

SUPPORTED_PLATFORMS="${!DOCKERFILE_EXTENSIONS[*]}"
export SUPPORTED_PLATFORMS
function assert_supported_platform() { # $1 platform to check
    if ! test ${DOCKERFILE_EXTENSIONS[$1]++isset}; then
       echo "$1 is not a supported platforms. Supported platforms are: ${SUPPORTED_PLATFORMS}" > /dev/stderr
       exit 1
    fi
}

function docker_annotate_arguments() { # $1=BUILD_PLATFORM
    echo "${DOCKER_MANIFEST_ANNOTATIONS[$1]}"
}

function dockerfile() { # $1=platform
    echo "Dockerfile.${DOCKERFILE_EXTENSIONS[$1]}"
}

function docker_image_name() { # $1=SERVICE_NAME $2=BUILD_PLATFORM
    echo "${DOCKER_IMAGE_PREFIX}$1:$2-${DOCKER_TAG_PREFIX}${DOCKER_TAG}"
}

function docker_latest_platform_image_name() { # $1=SERVICE_NAME $2=BUILD_PLATFORM
    echo "${DOCKER_IMAGE_PREFIX}$1:$2-latest"
}

function docker_manifest_image_name() { # $1=SERVICE_NAME $2=[TAG]
    echo "${DOCKER_IMAGE_PREFIX}$1:${2:-latest}"
}

function docker_login_and_enable_experimental_cli() {
    if [ "${DOCKER_USERNAME:-}" != "" ] && [ "${DOCKER_PASSWORD:-}" != "" ]; then
        test -d "${HOME}/.docker/" || mkdir -p "${HOME}/.docker/"
        echo '{"experimental": "enabled"}' > "${HOME}/.docker/config.json"
        echo "${DOCKER_PASSWORD}" | docker login -u "${DOCKER_USERNAME}" --password-stdin
    fi
}

function purge_docker_manifests() {
    rm -rf "${HOME}/.docker/manifests/"
}

function qemu_user_static_link() { # $1=platform
    QEMU_USER_STATIC_VERSION="2.11.1"
    echo "https://github.com/multiarch/qemu-user-static/releases/download/v${QEMU_USER_STATIC_VERSION}/${QEMU_USER_STATIC_FILES[$1]}.tar.gz"
}
