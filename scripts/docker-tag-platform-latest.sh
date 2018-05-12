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
latest_platform_image_name="$(docker_latest_platform_image_name "${SERVICE_NAME}" "${BUILD_PLATFORM}")"

echo "Tag and push ${image_name} as ${latest_platform_image_name}"
# Pull image -> avoid rebuilding it -> keep same image digest
${DOCKER} pull "${image_name}"
${DOCKER} tag "${image_name}" "${latest_platform_image_name}"
${DOCKER} push "${latest_platform_image_name}"
