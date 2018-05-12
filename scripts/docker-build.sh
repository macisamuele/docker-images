#!/usr/bin/env bash
if [ $# -ne 2 ]; then
    echo "Usage: $0 <build-platform> <service-name>" > /dev/stderr
    exit 1
fi

set -euxo pipefail -o posix -o functrace
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
curl --location "$(qemu_user_static_link "${BUILD_PLATFORM}")" | \
    tar -xz -C "${TMP_DIR}/context"

echo "Start effective docker image build"
# shellcheck disable=SC2086
${DOCKER} build ${DOCKER_BUILD_OPTIONS:-} \
    --file "${TMP_DIR}/context/$(dockerfile ${BUILD_PLATFORM})" \
    --force-rm \
    --pull \
    --memory-swap -1 \
    --tag "$(docker_image_name "${SERVICE_NAME}" "${BUILD_PLATFORM}")" \
    "${TMP_DIR}/context/"
