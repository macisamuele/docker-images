#!/usr/bin/env bash
if [ $# -ne 2 ]; then
    echo "Usage: $0 <build-platform> <service-name>" > /dev/stderr
    exit 1
fi

set -euxo pipefail -o posix -o functrace
# shellcheck source=scripts/common.sh
source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/common.sh"

docker_login_and_enable_experimental_cli

echo "Set base directory to git root directory"
cd "$(git_root_directory)"

BUILD_PLATFORM="$1"
SERVICE_NAME="$2"

assert_supported_platform "${BUILD_PLATFORM}"

image_name="$(docker_image_name "${SERVICE_NAME}" "${BUILD_PLATFORM}")"

if ! ${DOCKER} images -q "${image_name}" | grep -q '.'; then
    echo "Image is not present. Rebuilding it"
    bash "$(git_root_directory)/scripts/docker-build.sh" "$1" "$2"
fi

${DOCKER} push "$(docker_image_name "${SERVICE_NAME}" "${BUILD_PLATFORM}")"
