#
# Generic functions to deal with the open-source OxiGraph semantic graph database.
# See https://github.com/oxigraph/oxigraph
#
# Supports two deployment modes:
#   - Native binary (default): Fast, installed via cargo, data in .oxigraph/
#   - Docker mode (OXIGRAPH_DOCKER=1): Runs in Docker with named volume
#
ifndef _MK_OXIGRAPH_MK_
_MK_OXIGRAPH_MK_ := 1

#$(info ---> .make/oxigraph.mk)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
ifndef MK_DIR
MK_DIR := $(GIT_ROOT)/.make
endif

#
# Auto-detect oxigraph-* targets and enable OxiGraph support.
# This allows `gmake oxigraph-serve` to work even when EKG_VARIANT=graphdb in .env.
#
ifneq ($(filter oxigraph-%,$(MAKECMDGOALS)),)
USE_OXIGRAPH := 1
EKG_VARIANT := oxigraph
endif

#
# OxiGraph support is disabled by default.
# Set USE_OXIGRAPH=1 to enable OxiGraph functionality.
#
ifeq ($(USE_OXIGRAPH),1)

# Define OXIGRAPH_PORT early - it's needed by oxigraph-load.mk which may be
# included indirectly via oxigraph-count.mk before we finish this file
OXIGRAPH_PORT ?= 7879

# Set OXIGRAPH_DOCKER=1 to run Oxigraph in Docker instead of native binary.
# Docker mode uses named volumes and the upstream container image.
OXIGRAPH_DOCKER ?= 0

include $(MK_DIR)/os.mk
include $(MK_DIR)/os-tools.mk
include $(MK_DIR)/rdf-files.mk
include $(MK_DIR)/oxigraph-count.mk
include $(MK_DIR)/oxigraph-test.mk
include $(MK_DIR)/oxigraph-transform.mk

OXIGRAPH_VERSION_EXPECTED := 0.5.3

# ---------------------------------------------------------------------------
# Docker mode
# ---------------------------------------------------------------------------
ifeq ($(OXIGRAPH_DOCKER),1)

include $(MK_DIR)/triplestore-docker.mk

OXIGRAPH_DOCKER_IMAGE ?= ghcr.io/oxigraph/oxigraph:$(OXIGRAPH_VERSION_EXPECTED)
OXIGRAPH_DOCKER_INTERNAL_PORT ?= 7878
OXIGRAPH_DOCKER_MOUNT_DEST ?= /data

# Container and volume names derived from triplestore-docker.mk
OXIGRAPH_CONTAINER_NAME = $(TRIPLESTORE_CONTAINER_NAME)
OXIGRAPH_VOLUME_NAME = $(TRIPLESTORE_VOLUME_NAME)

.PHONY: oxigraph-check
oxigraph-check: docker-daemon-check

#
# Serve Oxigraph in Docker (foreground)
#
.PHONY: oxigraph-docker-serve
oxigraph-docker-serve: triplestore-volume-ensure
	@printf "$(bold)Starting Oxigraph Docker on port $(OXIGRAPH_PORT)...$(normal)\n"
	@printf "  Container: $(OXIGRAPH_CONTAINER_NAME)\n"
	@printf "  Volume:    $(OXIGRAPH_VOLUME_NAME)\n"
	@printf "  Instance:  $(TRIPLESTORE_INSTANCE)\n"
	@$(DOCKER_CMD) stop $(OXIGRAPH_CONTAINER_NAME) 2>/dev/null || true
	@$(DOCKER_CMD) rm $(OXIGRAPH_CONTAINER_NAME) 2>/dev/null || true
	$(DOCKER_CMD) run \
		--name $(OXIGRAPH_CONTAINER_NAME) \
		-p $(OXIGRAPH_PORT):$(OXIGRAPH_DOCKER_INTERNAL_PORT) \
		-v $(OXIGRAPH_VOLUME_NAME):$(OXIGRAPH_DOCKER_MOUNT_DEST) \
		$(OXIGRAPH_DOCKER_IMAGE) \
		serve --location $(OXIGRAPH_DOCKER_MOUNT_DEST) --bind 0.0.0.0:$(OXIGRAPH_DOCKER_INTERNAL_PORT)

#
# Serve Oxigraph in Docker (detached)
#
.PHONY: oxigraph-docker-serve-detached
oxigraph-docker-serve-detached: triplestore-volume-ensure
	@printf "$(bold)Starting Oxigraph Docker (detached) on port $(OXIGRAPH_PORT)...$(normal)\n"
	@printf "  Container: $(OXIGRAPH_CONTAINER_NAME)\n"
	@printf "  Volume:    $(OXIGRAPH_VOLUME_NAME)\n"
	@printf "  Instance:  $(TRIPLESTORE_INSTANCE)\n"
	@$(DOCKER_CMD) stop $(OXIGRAPH_CONTAINER_NAME) 2>/dev/null || true
	@$(DOCKER_CMD) rm $(OXIGRAPH_CONTAINER_NAME) 2>/dev/null || true
	$(DOCKER_CMD) run -d \
		--name $(OXIGRAPH_CONTAINER_NAME) \
		-p $(OXIGRAPH_PORT):$(OXIGRAPH_DOCKER_INTERNAL_PORT) \
		-v $(OXIGRAPH_VOLUME_NAME):$(OXIGRAPH_DOCKER_MOUNT_DEST) \
		$(OXIGRAPH_DOCKER_IMAGE) \
		serve --location $(OXIGRAPH_DOCKER_MOUNT_DEST) --bind 0.0.0.0:$(OXIGRAPH_DOCKER_INTERNAL_PORT)
	@printf "$(green)Oxigraph Docker started. Access at http://localhost:$(OXIGRAPH_PORT)$(normal)\n"
	@printf "Use 'gmake oxigraph-docker-logs' to view logs\n"
	@printf "Use 'gmake oxigraph-docker-stop' to stop the container\n"

.PHONY: oxigraph-docker-logs
oxigraph-docker-logs:
	$(DOCKER_CMD) logs -f $(OXIGRAPH_CONTAINER_NAME)

.PHONY: oxigraph-docker-stop
oxigraph-docker-stop: triplestore-container-stop

.PHONY: oxigraph-docker-kill
oxigraph-docker-kill: triplestore-container-rm

.PHONY: oxigraph-docker-clean
oxigraph-docker-clean: triplestore-docker-clean

.PHONY: oxigraph-docker-status
oxigraph-docker-status: triplestore-docker-status

# Dispatch main targets to Docker equivalents
.PHONY: oxigraph-serve
oxigraph-serve: oxigraph-docker-serve

.PHONY: oxigraph-kill
oxigraph-kill: oxigraph-docker-kill

.PHONY: oxigraph-delete-database
oxigraph-delete-database: oxigraph-kill
	@$(DOCKER_CMD) volume rm $(OXIGRAPH_VOLUME_NAME) 2>/dev/null \
		&& printf "$(green)Oxigraph volume $(OXIGRAPH_VOLUME_NAME) deleted$(normal)\n" \
		|| printf "No Oxigraph volume $(OXIGRAPH_VOLUME_NAME) to delete\n"

.PHONY: oxigraph-clean-info
oxigraph-clean-info:
	@echo "Cleaning OxiGraph (Docker mode)"

.PHONY: oxigraph-clean
oxigraph-clean: \
	oxigraph-clean-info \
	oxigraph-kill \
	oxigraph-delete-database \
	oxigraph-count-clean \
	oxigraph-test-clean \
	oxigraph-transform-clean \
	oxigraph-load-flags-delete

# ---------------------------------------------------------------------------
# Native binary mode (default)
# ---------------------------------------------------------------------------
else # OXIGRAPH_DOCKER != 1

include $(MK_DIR)/cargo.mk

OXIGRAPH_SERVER_BIN_NAME := oxigraph
OXIGRAPH_BIN := $(call where-is-binary,$(OXIGRAPH_SERVER_BIN_NAME))
OXIGRAPH_LOCATION_NAME := .oxigraph
OXIGRAPH_LOCATION := $(shell mkdir -p $(GIT_ROOT)/$(OXIGRAPH_LOCATION_NAME) 2>/dev/null ; cd $(GIT_ROOT)/$(OXIGRAPH_LOCATION_NAME) ; pwd )

ifdef OXIGRAPH_BIN
OXIGRAPH_VERSION := $(shell $(OXIGRAPH_BIN) --version | cut -d\  -f2)
endif
ifeq ($(OXIGRAPH_VERSION),$(OXIGRAPH_VERSION_EXPECTED))
OXIGRAPH_CHECKED := 1
else
OXIGRAPH_CHECKED := 0
$(info OxiGraph version $(OXIGRAPH_VERSION) does not match expected version $(OXIGRAPH_VERSION_EXPECTED))
endif

.PHONY: oxigraph-check
ifdef OXIGRAPH_BIN
ifeq ($(OXIGRAPH_CHECKED),1)
oxigraph-check:
	@#echo "Using OxiGraph $(OXIGRAPH_VERSION), storing its data in $(OXIGRAPH_LOCATION)"
else
oxigraph-check: cargo-check
	$(CARGO_BIN) +$(RUSTUP_TOOLCHAIN) install oxigraph-cli --version "^$(OXIGRAPH_VERSION_EXPECTED)"
endif
else
oxigraph-check:
	@echo "OxiGraph is not installed, can't run this function"
	exit 1
endif

#
# Install OxiGraph by building it from source using the "cargo install" command which puts the binary executable
# (oxigraph) in the Cargo bin directory (usually ~/.cargo/bin).
#
# This has the advantage that we can always use the latest and greatest version of OxiGraph (it's a moving target)
# and that this script should easily run anywhere where Rust and Cargo are available. (inside Docker containers,
# Github Actions Linux/Windows/Mac VMs or your local Windows/Ubuntu/MacOS machine).
#
.PHONY: oxigraph-install
oxigraph-install: oxigraph-clean os-tools-install cargo-check clang-check
	@printf "$(bold)Installing OxiGraph:$(normal)\n"
	$(CARGO_BIN) +$(RUSTUP_TOOLCHAIN) install oxigraph-cli --version "^$(OXIGRAPH_VERSION_EXPECTED)"

.PHONY: oxigraph-help
oxigraph-help: $(OXIGRAPH_LOCATION) oxigraph-check
	$(OXIGRAPH_BIN) help

$(OXIGRAPH_LOCATION):
	set -x ; mkdir -p $@
#
# Launch the OxiGraph server, with whatever you have loaded into the database.
# Usually http://localhost:7879 unless you override OXIGRAPH_PORT
# Note: ulimit -n 10240 is required to avoid RocksDB TryFromIntError on macOS
#
.PHONY: oxigraph-serve
oxigraph-serve: $(OXIGRAPH_LOCATION) oxigraph-check
	ulimit -n 10240 && $(OXIGRAPH_BIN) serve --location $(OXIGRAPH_LOCATION) --bind 0.0.0.0:$(OXIGRAPH_PORT)

#
# Optimize the OxiGraph database for read-heavy workloads.
# This triggers RocksDB compaction. Usually not needed as the server
# optimizes automatically in the background, but useful before serving
# a read-only endpoint under heavy load.
#
.PHONY: oxigraph-optimize
oxigraph-optimize: $(OXIGRAPH_LOCATION) oxigraph-check
	@printf "$(bold)Optimizing OxiGraph database...$(normal)\n"
	@ulimit -n 10240 && $(OXIGRAPH_BIN) optimize --location $(OXIGRAPH_LOCATION)
	@printf "$(green)OxiGraph database optimized$(normal)\n"

ifdef PKILL_BIN
.PHONY: oxigraph-kill
oxigraph-kill:
	@echo "oxigraph-kill called at $$(date)" >> /tmp/oxigraph-kills.log
	@echo "  Parent PID: $$PPID" >> /tmp/oxigraph-kills.log
	@ps -p $$PPID -o args= >> /tmp/oxigraph-kills.log 2>/dev/null || echo "  (parent process info unavailable)" >> /tmp/oxigraph-kills.log
	@echo "  Call stack:" >> /tmp/oxigraph-kills.log
	@ps -o ppid= -p $$PPID 2>/dev/null | xargs -I{} ps -p {} -o args= >> /tmp/oxigraph-kills.log 2>/dev/null || true
	@echo "---" >> /tmp/oxigraph-kills.log
	@-$(PKILL_BIN) $(OXIGRAPH_SERVER_BIN_NAME)
else
oxigraph-kill:
	@echo "Cannot kill OxiGraph instances on this platform, make sure OxiGraph is not running"
endif

.PHONY: oxigraph-delete-database
oxigraph-delete-database: oxigraph-kill
	@if [ -d $(OXIGRAPH_LOCATION) ] ; then \
    	echo "Deleting local OxiGraph database" ; \
		rm -rf $(OXIGRAPH_LOCATION) ; \
	else \
	    echo "No local OxiGraph database to delete" ; \
	fi

.PHONY: oxigraph-clean-info
oxigraph-clean-info:
	@echo "Cleaning OxiGraph"

.PHONY: oxigraph-clean
oxigraph-clean: \
	oxigraph-clean-info \
	oxigraph-kill \
	oxigraph-delete-database \
	oxigraph-count-clean \
	oxigraph-test-clean \
	oxigraph-transform-clean \
	oxigraph-load-flags-delete

.PHONY: oxigraph-clean-transform-serve
oxigraph-clean-transform-serve: \
	oxigraph-clean \
	oxigraph-reload \
	oxigraph-count-before-transform \
	_oxigraph-run-transforms-no-reload \
	oxigraph-count-after-transform\
	oxigraph-run-transforms \
	oxigraph-serve

endif # OXIGRAPH_DOCKER

endif # USE_OXIGRAPH

#$(info <--- .make/oxigraph.mk)

endif # _MK_OXIGRAPH_MK_
