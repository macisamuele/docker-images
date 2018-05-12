CUR_MAKE_FILE := $(filter %docker-builder.make,${MAKEFILE_LIST})
include $(dir ${CUR_MAKE_FILE})/common.make
include $(dir ${CUR_MAKE_FILE})/docker-utilities.make

DOCKER_IMAGE_PREFIX := macisamuele
DOCKER_TAG_PREFIX := $(shell git diff-index --quiet HEAD || echo 'dirty-')
DOCKER_TAG := $(shell git rev-parse --short HEAD)
SERVICES_TO_BUILD := $(sort $(patsubst %/,%,$(dir $(wildcard */Dockerfile*))))
SUPPORTED_PLATFORMS := $(shell bash -c 'source ${CURDIR}/scripts/common.sh; echo $$SUPPORTED_PLATFORMS')

# Build targets
BUILD_SERVICE := $(patsubst %,build-%,${SERVICES_TO_BUILD})
.PHONY: ${BUILD_SERVICE}
${BUILD_SERVICE}: export SERVICE_TO_BUILD=$(patsubst build-%,%,$@)
${BUILD_SERVICE}: # Target to build a given service, all platforms will be built
	${MAKE} $(patsubst %,build-${SERVICE_TO_BUILD}-%,${SUPPORTED_PLATFORMS})

BUILD_PLATFROM_SERVICE := $(foreach \
	build_platform, \
	${SUPPORTED_PLATFORMS}, \
	$(patsubst %,build-%-${build_platform},${SERVICES_TO_BUILD}) \
)
.PHONY: ${BUILD_PLATFROM_SERVICE}
${BUILD_PLATFROM_SERVICE}: export PLATFORM_TO_BUILD=$(lastword $(subst -, ,$@))
${BUILD_PLATFROM_SERVICE}: export SERVICE_TO_BUILD=$(patsubst build-%-${PLATFORM_TO_BUILD},%,$@)
${BUILD_PLATFROM_SERVICE}:
	$(CURDIR)/scripts/docker-build.sh ${PLATFORM_TO_BUILD} ${SERVICE_TO_BUILD}

# Push targets
PUSH_SERVICE := $(patsubst %,push-%,${SERVICES_TO_BUILD})
.PHONY: ${PUSH_SERVICE}
${PUSH_SERVICE}: export SERVICE_TO_PUSH=$(patsubst push-%,%,$@)
${PUSH_SERVICE}: # Target to push a given service, all platforms will be pushed
	${MAKE} $(patsubst %,push-${SERVICE_TO_PUSH}-%,${SUPPORTED_PLATFORMS})

PUSH_PLATFROM_SERVICE := $(foreach \
	push_platform, \
	${SUPPORTED_PLATFORMS}, \
	$(patsubst %,push-%-${push_platform},${SERVICES_TO_BUILD}) \
)
.PHONY: ${PUSH_PLATFROM_SERVICE}
${PUSH_PLATFROM_SERVICE}: export PLATFORM_TO_PUSH=$(lastword $(subst -, ,$@))
${PUSH_PLATFROM_SERVICE}: export SERVICE_TO_PUSH=$(patsubst push-%-${PLATFORM_TO_PUSH},%,$@)
${PUSH_PLATFROM_SERVICE}:
	$(CURDIR)/scripts/docker-push.sh ${PLATFORM_TO_PUSH} ${SERVICE_TO_PUSH}

# Tag platform targets
TAG_LATEST_SERVICE := $(patsubst %,tag-%,${SERVICES_TO_BUILD})
.PHONY: ${TAG_LATEST_SERVICE}
${TAG_LATEST_SERVICE}: export SERVICE_TO_TAG=$(patsubst tag-%,%,$@)
${TAG_LATEST_SERVICE}: # Target to push latest images of a given service, all platforms will be tagged
	${MAKE} $(patsubst %,tag-${SERVICE_TO_TAG}-%,${SUPPORTED_PLATFORMS})

TAG_LATEST_PLATFROM_SERVICE := $(foreach \
	tag_latest_platform, \
	${SUPPORTED_PLATFORMS}, \
	$(patsubst %,tag-%-${tag_latest_platform},${SERVICES_TO_BUILD}) \
)
.PHONY: ${TAG_LATEST_PLATFROM_SERVICE}
${TAG_LATEST_PLATFROM_SERVICE}: export PLATFORM_TO_TAG=$(lastword $(subst -, ,$@))
${TAG_LATEST_PLATFROM_SERVICE}: export SERVICE_TO_TAG=$(patsubst tag-%-${PLATFORM_TO_TAG},%,$@)
${TAG_LATEST_PLATFROM_SERVICE}:
	$(CURDIR)/scripts/docker-tag-platform-latest.sh ${PLATFORM_TO_TAG} ${SERVICE_TO_TAG}

# Manifest targets
MANIFEST_SHA_SERVICE := $(patsubst %,push-manifest-%-sha,${SERVICES_TO_BUILD})
.PHONY: ${MANIFEST_SHA_SERVICE}
${MANIFEST_SHA_SERVICE}: export SERVICE_TO_PUSH_MANIFEST=$(patsubst push-manifest-%-sha,%,$@)
${MANIFEST_SHA_SERVICE}:
	$(CURDIR)/scripts/docker-manifest-push.sh ${SERVICE_TO_PUSH_MANIFEST}

# Manifest targets
MANIFEST_LATEST_SERVICE := $(patsubst %,push-manifest-%,${SERVICES_TO_BUILD})
.PHONY: ${MANIFEST_LATEST_SERVICE}
${MANIFEST_LATEST_SERVICE}: export SERVICE_TO_PUSH_MANIFEST=$(patsubst push-manifest-%,%,$@)
${MANIFEST_LATEST_SERVICE}:
	$(CURDIR)/scripts/docker-manifest-latest-push.sh ${SERVICE_TO_PUSH_MANIFEST}
