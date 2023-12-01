ifndef _MK_DOCKER_MK_
_MK_DOCKER_MK_ := 1

#$(info ---> .make/docker.mk)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
MK_DIR := $(GIT_ROOT)/.make

ORB_STACK_HOME := $(HOME)/.orbstack
ORB_STACK_BIN_DIR := $(ORB_STACK_HOME)/bin
ORB_STACK_DOCKER := $(ORB_STACK_BIN_DIR)/docker

ifndef RUNNING_IN_DOCKER
RUNNING_IN_DOCKER := 0
ifeq ($(UNAME_S),Linux)
RUNNING_IN_DOCKER_CODE := $(shell grep -sq 'docker\|lxc' /proc/1/cgroup 2>/dev/null ; echo $?)
ifeq ($(RUNNING_IN_DOCKER_CODE),1)
RUNNING_IN_DOCKER := 1
endif
endif
endif

ifeq ($(RUNNING_IN_DOCKER),1)
$(info We are running in a docker container)
endif

PACKAGE_RESULTS_DIR := /root/results

$(ORB_STACK_DOCKER):
	@echo "Building with $(ORB_STACK_DOCKER)"

DOCKER_REGISTRY ?= ekgf.azurecr.io

.PHONY: docker-login-azure
docker-login-azure:
	@echo "Logging into docker registry $(DOCKER_REGISTRY):"
	@(\
		USER_NAME="00000000-0000-0000-0000-000000000000" && \
		PASSWORD=$$(az acr login --name $(DOCKER_REGISTRY) --expose-token --output tsv --query accessToken) && \
		echo "$$PASSWORD" | docker login $(DOCKER_REGISTRY) --username "$$USER_NAME" --password-stdin \
	) 2>&1 | \
	    grep -v "WARNING: The login server endpoint suffix " | \
	    grep -v "WARNING: You can perform manual login"

# ------------------------------------------------------------------------------
# The rest of this file is only available if the variables below are defined
# ------------------------------------------------------------------------------
ifdef DOCKER_REGISTRY
ifdef DOCKER_IMAGE
ifdef DOCKER_IMAGE_TAG
ifdef DOCKER_FILE

ifndef GIT_ROOT
$(error GIT_ROOT must be defined)
endif

$(DOCKER_FILE):
	@printf "$(bold)Building docker image $(DOCKER_IMAGE):$(DOCKER_IMAGE_TAG)$(normal)\n"

.PHONY: build-image
build-image: $(DOCKER_FILE) $(ORB_STACK_DOCKER)
	cd $(GIT_ROOT) && \
	docker buildx build \
		--progress=plain \
		--tag $(DOCKER_REGISTRY)/$(DOCKER_IMAGE):$(DOCKER_IMAGE_TAG) \
		--build-arg "RUSTUP_TOOLCHAIN=$(RUSTUP_TOOLCHAIN)" \
		--build-arg "RUSTUP_ALL_TARGETS=$(RUSTUP_ALL_TARGETS)" \
		--build-arg "PACKAGE_RESULTS_DIR=$(PACKAGE_RESULTS_DIR)" \
		--build-arg "CARGO_BUILD_FEATURES=$(CARGO_BUILD_FEATURES)" \
		--build-arg "CARGO_BUILD_TARGET=$(CARGO_BUILD_TARGET)" \
	    --file "$(DOCKER_FILE)" \
	    $(GIT_ROOT)

.PHONY: push-image
push-image: docker-login-azure
	docker tag $(DOCKER_REGISTRY)/$(DOCKER_IMAGE):$(DOCKER_IMAGE_TAG) $(DOCKER_REGISTRY)/$(DOCKER_IMAGE):latest
	docker push $(DOCKER_REGISTRY)/$(DOCKER_IMAGE):$(DOCKER_IMAGE_TAG)
	docker push $(DOCKER_REGISTRY)/$(DOCKER_IMAGE):latest

.PHONY: build-and-push-image
build-and-push-image: build-image push-image

endif # DOCKER_FILE
endif # DOCKER_IMAGE_TAG
endif # DOCKER_IMAGE
endif # DOCKER_REGISTRY

#$(info <--- .make/docker.mk)

endif # _MK_DOCKER_MK_
