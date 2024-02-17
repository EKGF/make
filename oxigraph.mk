#
# Generic functions to deal with the open-source OxiGraph semantic graph database.
# See https://github.com/oxigraph/oxigraph
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

include $(MK_DIR)/os.mk
include $(MK_DIR)/os-tools.mk
include $(MK_DIR)/cargo.mk
include $(MK_DIR)/rdf-files.mk
include $(MK_DIR)/oxigraph-count.mk
include $(MK_DIR)/oxigraph-test.mk
include $(MK_DIR)/oxigraph-transform.mk

OXIGRAPH_SERVER_BIN_NAME := oxigraph_server
OXIGRAPH_BIN := $(call where-is-binary,$(OXIGRAPH_SERVER_BIN_NAME))
OXIGRAPH_LOCATION_NAME := .oxigraph
OXIGRAPH_LOCATION := $(shell mkdir -p $(GIT_ROOT)/$(OXIGRAPH_LOCATION_NAME) 2>/dev/null ; cd $(GIT_ROOT)/$(OXIGRAPH_LOCATION_NAME) ; pwd )
OXIGRAPH_PORT := 7879

ifdef OXIGRAPH_BIN
OXIGRAPH_VERSION := $(shell $(OXIGRAPH_BIN) --version | cut -d\  -f2)
endif
OXIGRAPH_VERSION_EXPECTED := 0.3.22
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
	$(CARGO_BIN) +$(RUSTUP_TOOLCHAIN) install oxigraph_server --version "^$(OXIGRAPH_VERSION_EXPECTED)"
endif
else
oxigraph-check:
	@echo "OxiGraph is not installed, can't run this function"
	exit 1
endif

#
# Install OxiGraph by building it from source using the "cargo install" command which puts the binary executable
# (oxigraph_server) in the Cargo bin directory (usually ~/.cargo/bin).
#
# This has the advantage that we can always use the latest and greatest version of OxiGraph (it's a moving target)
# and that this script should easily run anywhere where Rust and Cargo are available. (inside Docker containers,
# Github Actions Linux/Windows/Mac VMs or your local Windows/Ubuntu/MacOS machine).
#
.PHONY: oxigraph-install
oxigraph-install: oxigraph-clean os-tools-install cargo-check clang-check
	@printf "$(bold)Installing OxiGraph:$(normal)\n"
	$(CARGO_BIN) +$(RUSTUP_TOOLCHAIN) install oxigraph_server --version "^$(OXIGRAPH_VERSION_EXPECTED)"

.PHONY: oxigraph-help
oxigraph-help: $(OXIGRAPH_LOCATION) oxigraph-check
	$(OXIGRAPH_BIN) --location $(OXIGRAPH_LOCATION) help

$(OXIGRAPH_LOCATION):
	set -x ; mkdir -p $@
#
# Launch the OxiGraph server, with whatever you have loaded into the database.
# Usually http://localhost:7879 unless you override OXIGRAPH_PORT
#
.PHONY: oxigraph-serve
oxigraph-serve: $(OXIGRAPH_LOCATION) oxigraph-check
	$(OXIGRAPH_BIN) --location $(OXIGRAPH_LOCATION) serve --bind 0.0.0.0:$(OXIGRAPH_PORT)

ifdef PKILL_BIN
.PHONY: oxigraph-kill
oxigraph-kill:
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
	oxigraph-run-transforms \
	oxigraph-serve

#$(info <--- .make/oxigraph.mk)

endif # _MK_OXIGRAPH_MK_
