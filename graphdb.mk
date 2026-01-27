#
# GraphDB triplestore support via Docker.
# See https://graphdb.ontotext.com/
#
ifndef _MK_GRAPHDB_MK_
_MK_GRAPHDB_MK_ := 1

#$(info ---> .make/graphdb.mk)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
ifndef MK_DIR
MK_DIR := $(GIT_ROOT)/.make
endif

#
# Auto-detect graphdb-* targets and enable GraphDB support.
# This allows `gmake graphdb-serve` to work even when EKG_VARIANT=oxigraph in .env.
#
ifneq ($(filter graphdb-%,$(MAKECMDGOALS)),)
USE_GRAPHDB := 1
EKG_VARIANT := graphdb
endif

#
# GraphDB support is disabled by default.
# Set USE_GRAPHDB=1 to enable GraphDB functionality.
#
ifeq ($(USE_GRAPHDB),1)

include $(MK_DIR)/os.mk
include $(MK_DIR)/docker.mk
include $(MK_DIR)/dotenvage.mk
include $(MK_DIR)/rdf-http-load.mk

# Get EKG_AGE_KEY from dotenvage (it's filtered from dump for security)
# This reads it from .env.local or the key file
ifdef DOTENVAGE_BIN
EKG_AGE_KEY ?= $(shell $(DOTENVAGE_BIN) get EKG_AGE_KEY 2>/dev/null)
endif

GRAPHDB_PORT ?= 7200
GRAPHDB_CONTAINER_NAME ?= graphdb-local
GRAPHDB_IMAGE_NAME ?= graphdb-local
GRAPHDB_DOCKERFILE ?= $(GIT_ROOT)/Dockerfile.graphdb
GRAPHDB_DATA_DIR ?= $(GIT_ROOT)/.graphdb
GRAPHDB_REPO_NAME ?= ekg

# Docker command (prefer OrbStack if available)
DOCKER_CMD := $(if $(wildcard $(ORB_STACK_DOCKER)),$(ORB_STACK_DOCKER),docker)

.PHONY: graphdb-check
graphdb-check:
	@if ! command -v $(DOCKER_CMD) >/dev/null 2>&1; then \
		echo "Docker is not installed. Please install Docker or OrbStack."; \
		exit 1; \
	fi
	@echo "Using Docker: $(DOCKER_CMD)"

$(GRAPHDB_DATA_DIR):
	@mkdir -p $@

# Determine which environment to build for (local by default for development)
GRAPHDB_BUILD_ENV ?= local

#
# Build the GraphDB Docker image
# Uses EKG_ENV build arg to determine which .env file to bake in
#
.PHONY: graphdb-build
graphdb-build: graphdb-check
	@printf "$(bold)Building GraphDB Docker image for $(GRAPHDB_BUILD_ENV)...$(normal)\n"
	$(DOCKER_CMD) build --load -t $(GRAPHDB_IMAGE_NAME) \
		--build-arg EKG_ENV=$(GRAPHDB_BUILD_ENV) \
		-f $(GRAPHDB_DOCKERFILE) $(GIT_ROOT)

#
# Run GraphDB in a Docker container
# Data is persisted in .graphdb directory
# License and config are baked into image; EKG_AGE_KEY decrypts at runtime
#
.PHONY: graphdb-serve
graphdb-serve: $(GRAPHDB_DATA_DIR) graphdb-check graphdb-build
	@printf "$(bold)Starting GraphDB on port $(GRAPHDB_PORT)...$(normal)\n"
	@# Stop existing container if running
	@$(DOCKER_CMD) stop $(GRAPHDB_CONTAINER_NAME) 2>/dev/null || true
	@$(DOCKER_CMD) rm $(GRAPHDB_CONTAINER_NAME) 2>/dev/null || true
	@# Run new container - dotenvage inside decrypts .env files using EKG_AGE_KEY
	$(DOCKER_CMD) run \
		--name $(GRAPHDB_CONTAINER_NAME) \
		-p $(GRAPHDB_PORT):7200 \
		-v $(GRAPHDB_DATA_DIR):/opt/graphdb/data \
		-e EKG_AGE_KEY="$(EKG_AGE_KEY)" \
		$(GRAPHDB_IMAGE_NAME)

#
# Run GraphDB in background (detached mode)
# License and config are baked into image; EKG_AGE_KEY decrypts at runtime
#
.PHONY: graphdb-serve-detached
graphdb-serve-detached: $(GRAPHDB_DATA_DIR) graphdb-check graphdb-build
	@printf "$(bold)Starting GraphDB in background on port $(GRAPHDB_PORT)...$(normal)\n"
	@# Stop existing container if running
	@$(DOCKER_CMD) stop $(GRAPHDB_CONTAINER_NAME) 2>/dev/null || true
	@$(DOCKER_CMD) rm $(GRAPHDB_CONTAINER_NAME) 2>/dev/null || true
	@# Run new container - dotenvage inside decrypts .env files using EKG_AGE_KEY
	$(DOCKER_CMD) run -d \
		--name $(GRAPHDB_CONTAINER_NAME) \
		-p $(GRAPHDB_PORT):7200 \
		-v $(GRAPHDB_DATA_DIR):/opt/graphdb/data \
		-e EKG_AGE_KEY="$(EKG_AGE_KEY)" \
		$(GRAPHDB_IMAGE_NAME)
	@printf "$(green)GraphDB started. Access at http://localhost:$(GRAPHDB_PORT)$(normal)\n"
	@printf "Use 'gmake graphdb-logs' to view logs\n"
	@printf "Use 'gmake graphdb-stop' to stop the container\n"

#
# View GraphDB logs
#
.PHONY: graphdb-logs
graphdb-logs:
	$(DOCKER_CMD) logs -f $(GRAPHDB_CONTAINER_NAME)

#
# Stop the GraphDB container
#
.PHONY: graphdb-stop
graphdb-stop:
	@printf "$(bold)Stopping GraphDB...$(normal)\n"
	@$(DOCKER_CMD) stop $(GRAPHDB_CONTAINER_NAME) 2>/dev/null || true
	@printf "$(green)GraphDB stopped$(normal)\n"

#
# Kill and remove the GraphDB container
#
.PHONY: graphdb-kill
graphdb-kill:
	@printf "$(bold)Killing GraphDB container...$(normal)\n"
	@$(DOCKER_CMD) kill $(GRAPHDB_CONTAINER_NAME) 2>/dev/null || true
	@$(DOCKER_CMD) rm $(GRAPHDB_CONTAINER_NAME) 2>/dev/null || true

#
# Delete the GraphDB data directory
#
.PHONY: graphdb-delete-database
graphdb-delete-database: graphdb-kill
	@if [ -d $(GRAPHDB_DATA_DIR) ]; then \
		echo "Deleting GraphDB database at $(GRAPHDB_DATA_DIR)"; \
		rm -rf $(GRAPHDB_DATA_DIR); \
	else \
		echo "No GraphDB database to delete"; \
	fi

#
# Clean everything (stop container, delete data)
#
.PHONY: graphdb-clean
graphdb-clean: graphdb-kill graphdb-delete-database
	@printf "$(green)GraphDB cleaned$(normal)\n"

#
# Wait for GraphDB to be ready
#
.PHONY: graphdb-wait
graphdb-wait:
	@printf "Waiting for GraphDB to be ready...\n"
	@for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30; do \
		if curl -sf "http://localhost:$(GRAPHDB_PORT)/rest/repositories" >/dev/null 2>&1; then \
			echo "GraphDB is ready"; \
			exit 0; \
		fi; \
		echo "Waiting... ($$i/30)"; \
		sleep 2; \
	done; \
	echo "GraphDB failed to start"; \
	exit 1

#
# Check if repository exists
#
.PHONY: graphdb-repo-check
graphdb-repo-check:
	@if curl -sf "http://localhost:$(GRAPHDB_PORT)/rest/repositories/$(GRAPHDB_REPO_NAME)" >/dev/null 2>&1; then \
		echo "Repository $(GRAPHDB_REPO_NAME) exists"; \
	else \
		echo "Repository $(GRAPHDB_REPO_NAME) does not exist"; \
		exit 1; \
	fi

#
# Show GraphDB status
#
.PHONY: graphdb-status
graphdb-status:
	@if $(DOCKER_CMD) ps --filter "name=$(GRAPHDB_CONTAINER_NAME)" --format "{{.Names}}" | grep -q $(GRAPHDB_CONTAINER_NAME); then \
		echo "GraphDB container is running"; \
		echo "  Container: $(GRAPHDB_CONTAINER_NAME)"; \
		echo "  Port: $(GRAPHDB_PORT)"; \
		echo "  URL: http://localhost:$(GRAPHDB_PORT)"; \
		echo "  Repository: $(GRAPHDB_REPO_NAME)"; \
		echo "  SPARQL: http://localhost:$(GRAPHDB_PORT)/repositories/$(GRAPHDB_REPO_NAME)"; \
	else \
		echo "GraphDB container is not running"; \
	fi

#
# HTTP load: loads to running GraphDB server via HTTP (incremental, parallel-safe)
# Automatically runs with -j20 for parallel loading
# Requires server to be running (checks first)
#
GRAPHDB_HTTP_LOAD_JOBS ?= 20

.PHONY: graphdb-http-load
graphdb-http-load: sparql-server-check
	@$(MAKE) -j$(GRAPHDB_HTTP_LOAD_JOBS) --no-print-directory _rdf-http-load-files
	@printf "$(green)HTTP loaded all RDF files to GraphDB$(normal)\n"
	@$(MAKE) --no-print-directory _rdf-http-load-sparql-queries

.PHONY: graphdb-http-load-flags-delete
graphdb-http-load-flags-delete: rdf-http-load-flags-delete

.PHONY: graphdb-http-reload
graphdb-http-reload: graphdb-http-load-flags-delete graphdb-http-load

#
# Bulk load alias (uses HTTP load since GraphDB doesn't have CLI bulk load)
#
.PHONY: graphdb-load
graphdb-load: graphdb-http-load

endif # USE_GRAPHDB

#$(info <--- .make/graphdb.mk)

endif # _MK_GRAPHDB_MK_
