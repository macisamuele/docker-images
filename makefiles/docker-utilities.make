ifdef LOW_RESOURCES
	# Reduce resource usage while building docker images
	MAX_CPU_TO_USE := $(shell ${CPU_COUNT_COMMAND} | awk '{print int(($$0+1)/2)-1}')
	DOCKER_BUILD_OPTIONS := ${DOCKER_BUILD_OPTIONS:} --cpuset-cpus 0-${MAX_CPU_TO_USE}
endif

# Usage: $(call tag_docker_image, target)
define tag_docker_image
set -x && \
	${DOCKER} tag \
		${DOCKER_IMAGE_PREFIX}/${BUILD_DIR}:${BUILD_PLATFORM}-${DOCKER_TAG_PREFIX}${DOCKER_TAG} \
		${DOCKER_IMAGE_PREFIX}/${BUILD_DIR}:${BUILD_PLATFORM}-${DOCKER_TAG_PREFIX}latest && \
	set +x
endef

# Usage: $(call annotate_docker_manifest, service_name)
# WARNING: this is strictly dependent on the defined platforms ... find a way to use a config file
define annotate_docker_manifest
	${DOCKER} manifest create --amend ${DOCKER_IMAGE_PREFIX}/${1}:latest $(foreach \
		platform, \
		${SUPPORTED_PLATFORMS}, \
		${DOCKER_IMAGE_PREFIX}/${1}:${platform}-latest \
	)
	${DOCKER} manifest annotate ${DOCKER_IMAGE_PREFIX}/${1}:latest ${DOCKER_IMAGE_PREFIX}/${1}:amd64-latest --os linux --arch amd64
	${DOCKER} manifest annotate ${DOCKER_IMAGE_PREFIX}/${1}:latest ${DOCKER_IMAGE_PREFIX}/${1}:armhf-latest --os linux --arch arm --variant v7
	${DOCKER} manifest push ${DOCKER_IMAGE_PREFIX}/${1}:latest
	rm -rf ${HOME}/.docker/manifests/*
endef
