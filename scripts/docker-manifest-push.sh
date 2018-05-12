#!/usr/bin/env bash
if [ $# -ne 1 ]; then
    echo "Usage: $0 <service-name>" > /dev/stderr
    exit 1
fi

set -euxo pipefail -o posix -o functrace
# shellcheck source=scripts/common.sh
source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/common.sh"

docker_login_and_enable_experimental_cli

echo "Set base directory to git root directory"
cd "$(git_root_directory)"

SERVICE_NAME="$1"

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

purge_docker_manifests

DOCKER_MANIFEST="$(docker_manifest_image_name "${SERVICE_NAME}" "${DOCKER_TAG_PREFIX}${DOCKER_TAG}")"

echo "Pull docker images"
# shellcheck disable=SC2086,SC2068
for platform in ${SUPPORTED_PLATFORMS[@]}; do
    ${DOCKER} pull "$(docker_image_name "${SERVICE_NAME}" "${platform}")"
done

echo "Create and annotate manifest"
# shellcheck disable=SC2086,SC2068
for platform in ${SUPPORTED_PLATFORMS[@]}; do
    docker_image_name "${SERVICE_NAME}" "${platform}"
done | xargs ${DOCKER} manifest create --amend "${DOCKER_MANIFEST}"
# shellcheck disable=SC2086,SC2068
for platform in ${SUPPORTED_PLATFORMS[@]}; do
    docker_annotate_arguments "${platform}" | xargs ${DOCKER} manifest annotate "${DOCKER_MANIFEST}" "$(docker_image_name "${SERVICE_NAME}" "${platform}")"
done

echo "Generated manifest"
${DOCKER} manifest inspect "${DOCKER_MANIFEST}"

echo "Push manifest"
${DOCKER} manifest push "${DOCKER_MANIFEST}"
