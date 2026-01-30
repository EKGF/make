#
# Shared Docker volume and container lifecycle for triplestore backends.
#
# Provides a unified abstraction for running any SPARQL triplestore
# (Oxigraph, GraphDB, etc.) in Docker with named volumes.
#
# Key variables:
#   TRIPLESTORE_INSTANCE   - Scopes Docker resources (default: "default")
#   TRIPLESTORE_VOLUME_NAME    - Computed: ekg-<variant>-<instance>
#   TRIPLESTORE_CONTAINER_NAME - Computed: ekg-<variant>-<instance>
#   DOCKER_CMD                 - Docker binary (prefers OrbStack on macOS)
#
ifndef _MK_TRIPLESTORE_DOCKER_MK_
_MK_TRIPLESTORE_DOCKER_MK_ := 1

#$(info ---> .make/triplestore-docker.mk)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
ifndef MK_DIR
MK_DIR := $(GIT_ROOT)/.make
endif

include $(MK_DIR)/os.mk
include $(MK_DIR)/docker.mk

# ---------------------------------------------------------------------------
# Instance scoping
# ---------------------------------------------------------------------------
# TRIPLESTORE_INSTANCE controls Docker resource naming.
# Default is "default" (shared across worktrees).
# Override to scope resources per worktree, branch, tenant, etc.:
#   gmake serve TRIPLESTORE_INSTANCE=feature-xyz
#   gmake serve TRIPLESTORE_INSTANCE=org-acme
#
TRIPLESTORE_INSTANCE ?= default

# ---------------------------------------------------------------------------
# Computed names (recursive = so EKG_VARIANT late-binding works)
# ---------------------------------------------------------------------------
TRIPLESTORE_VOLUME_NAME = ekg-$(EKG_VARIANT)-$(TRIPLESTORE_INSTANCE)
TRIPLESTORE_CONTAINER_NAME = ekg-$(EKG_VARIANT)-$(TRIPLESTORE_INSTANCE)

# ---------------------------------------------------------------------------
# Docker command (prefer OrbStack if available, fall back to docker)
# ---------------------------------------------------------------------------
DOCKER_CMD := $(if $(wildcard $(ORB_STACK_DOCKER)),$(ORB_STACK_DOCKER),docker)

# ---------------------------------------------------------------------------
# docker-daemon-check: Verify Docker is installed and the daemon is running.
# On macOS with OrbStack installed, auto-starts it as a convenience.
# ---------------------------------------------------------------------------
.PHONY: docker-daemon-check
docker-daemon-check:
	@if ! command -v $(DOCKER_CMD) >/dev/null 2>&1; then \
		printf "$(red)Docker is not installed.$(normal)\n"; \
		if [ "$(UNAME_S)" = "Darwin" ]; then \
			echo "Install OrbStack: brew install --cask orbstack"; \
		else \
			echo "Install Docker: https://docs.docker.com/engine/install/"; \
		fi; \
		exit 1; \
	fi
	@echo "Using Docker: $(DOCKER_CMD)"
	@if ! $(DOCKER_CMD) info >/dev/null 2>&1; then \
		if [ "$(UNAME_S)" = "Darwin" ] && [ -d "$(ORB_STACK_HOME)" ]; then \
			printf "$(bold)Docker daemon is not running. Starting OrbStack...$(normal)\n"; \
			open -a OrbStack; \
			printf "Waiting for OrbStack to start"; \
			for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30; do \
				if $(DOCKER_CMD) info >/dev/null 2>&1; then \
					printf "\n$(green)OrbStack is ready$(normal)\n"; \
					break; \
				fi; \
				printf "."; \
				sleep 1; \
			done; \
			if ! $(DOCKER_CMD) info >/dev/null 2>&1; then \
				printf "\n$(red)Timed out waiting for OrbStack to start$(normal)\n"; \
				exit 1; \
			fi; \
		else \
			printf "$(red)Docker daemon is not running.$(normal)\n"; \
			if [ "$(UNAME_S)" = "Darwin" ]; then \
				echo "Start OrbStack or Docker Desktop and try again."; \
			else \
				echo "Start the Docker daemon (e.g. sudo systemctl start docker) and try again."; \
			fi; \
			exit 1; \
		fi; \
	fi

# ---------------------------------------------------------------------------
# Volume lifecycle
# ---------------------------------------------------------------------------

.PHONY: triplestore-volume-ensure
triplestore-volume-ensure: docker-daemon-check
	@$(DOCKER_CMD) volume inspect $(TRIPLESTORE_VOLUME_NAME) >/dev/null 2>&1 \
		|| $(DOCKER_CMD) volume create $(TRIPLESTORE_VOLUME_NAME) >/dev/null
	@printf "Volume: $(bold)$(TRIPLESTORE_VOLUME_NAME)$(normal)\n"

.PHONY: triplestore-volume-delete
triplestore-volume-delete: docker-daemon-check
	@if $(DOCKER_CMD) volume inspect $(TRIPLESTORE_VOLUME_NAME) >/dev/null 2>&1; then \
		$(DOCKER_CMD) volume rm $(TRIPLESTORE_VOLUME_NAME); \
		printf "$(green)Volume $(TRIPLESTORE_VOLUME_NAME) deleted$(normal)\n"; \
	else \
		printf "Volume $(TRIPLESTORE_VOLUME_NAME) does not exist\n"; \
	fi

.PHONY: triplestore-volume-info
triplestore-volume-info: docker-daemon-check
	@$(DOCKER_CMD) volume inspect $(TRIPLESTORE_VOLUME_NAME) 2>/dev/null \
		|| printf "Volume $(TRIPLESTORE_VOLUME_NAME) does not exist\n"

# ---------------------------------------------------------------------------
# Container lifecycle
# ---------------------------------------------------------------------------

.PHONY: triplestore-container-stop
triplestore-container-stop: docker-daemon-check
	@$(DOCKER_CMD) stop $(TRIPLESTORE_CONTAINER_NAME) 2>/dev/null || true

.PHONY: triplestore-container-rm
triplestore-container-rm: triplestore-container-stop
	@$(DOCKER_CMD) rm $(TRIPLESTORE_CONTAINER_NAME) 2>/dev/null || true

# ---------------------------------------------------------------------------
# Status and listing
# ---------------------------------------------------------------------------

.PHONY: triplestore-docker-status
triplestore-docker-status: docker-daemon-check
	@printf "$(bold)EKG Containers:$(normal)\n"
	@$(DOCKER_CMD) ps -a --filter "name=ekg-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null \
		|| echo "  (none)"
	@printf "\n$(bold)EKG Volumes:$(normal)\n"
	@$(DOCKER_CMD) volume ls --filter "name=ekg-" --format "table {{.Name}}\t{{.Driver}}" 2>/dev/null \
		|| echo "  (none)"

# ---------------------------------------------------------------------------
# Clean up container + volume for the current variant+instance
# ---------------------------------------------------------------------------

.PHONY: triplestore-docker-clean
triplestore-docker-clean: triplestore-container-rm triplestore-volume-delete

#$(info <--- .make/triplestore-docker.mk)

endif # _MK_TRIPLESTORE_DOCKER_MK_
