#!/usr/bin/env bash
if [ $# -ne 2 ]; then
    echo "Usage: $0 <build-platform> <service-name>" > /dev/stderr
    exit 1
fi

set -euo pipefail -o posix -o functrace
# shellcheck source=scripts/common.sh
source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/common.sh"

BUILD_PLATFORM="$1"
SERVICE_NAME="$2"
DOCKER_CONTEXT_DIRECTORY="$(git_root_directory)/$2"

echo "Set base directory to git root directory"
cd "$(git_root_directory)"

assert_supported_platform "${BUILD_PLATFORM}"

TMP_DIR=$(mktemp -d)
clean_tmp_dir() {
    exit_status=$?
    rm -rf "${TMP_DIR}"
    exit $exit_status
}
# ERR -> command failed, shell exits due to set -e
# SIGx -> Documented on http://www.comptechdoc.org/os/linux/programming/linux_pgsignals.html
trap 'exit 2' ERR SIGINT SIGTERM
trap clean_tmp_dir EXIT
cd "${TMP_DIR}"

echo "Copy docker context in temporary directory"
cp -R "${DOCKER_CONTEXT_DIRECTORY}" "${TMP_DIR}/context"

echo "Fetch qemu-user-static from github (allow to run resulting image on all platforms)"
curl --silent --location "$(qemu_user_static_link "${BUILD_PLATFORM}")" | \
    tar -xz -C "${TMP_DIR}/context"

echo "Register qemu-user-static binfmt"
${DOCKER} run --rm --privileged multiarch/qemu-user-static:register --reset

latest_platform_image_name="$(docker_latest_platform_image_name "${SERVICE_NAME}" "${BUILD_PLATFORM}")"
echo "Pulling ${latest_platform_image_name} to speed-up build. This is usually a correct guess especially during docker cross architecture builing"
${DOCKER} pull "${latest_platform_image_name}" || echo "Pull failed, but it was a tentative so that's OK"

if [ "${SERVICE_NAME}" = "openvpn" ]; then
    echo "Copy Dockerfile to ${TMP_DIR}/context/$(dockerfile "${BUILD_PLATFORM}") and add qemu-*-static"
    sed -r 's|(FROM.*)|\1\n# Add qemu-*-static to allow execution of the build process from any platform\nCOPY qemu-*-static /usr/bin/\n|' "${TMP_DIR}/context/Dockerfile" > "${TMP_DIR}/context/$(dockerfile "${BUILD_PLATFORM}")"
    if [ "${BUILD_PLATFORM}" = "armhf" ]; then
        echo "Use different alpine base image while builing for armhf (linux-arm-v7)"
        sed -ri 's|FROM alpine:latest|FROM easypi/alpine-arm:latest|' "${TMP_DIR}/context/$(dockerfile "${BUILD_PLATFORM}")"
    fi
fi

echo "Start effective docker image build"
# shellcheck disable=SC2086
${DOCKER} build ${DOCKER_BUILD_OPTIONS:-} \
    --file "${TMP_DIR}/context/$(dockerfile "${BUILD_PLATFORM}")" \
    --force-rm \
    --pull \
    --memory-swap -1 \
    --tag "$(docker_image_name "${SERVICE_NAME}" "${BUILD_PLATFORM}")" \
    "${TMP_DIR}/context/"
