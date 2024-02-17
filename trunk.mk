ifndef _MK_TRUNK_MK_
_MK_TRUNK_MK_ := 1
#
# Dealing with trunk, see https://trunkrs.dev
#

#$(info ---> .make/trunk.mk)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
ifndef MK_DIR
MK_DIR := $(GIT_ROOT)/.make
endif

include $(MK_DIR)/os.mk

TRUNK_VERSION := $(shell trunk --version 2>/dev/null)
ifndef TRUNK_VERSION
TRUNK_VERSION := $(shell ~/.cargo/bin/trunk --version 2>/dev/null)
endif

ifdef release
ifeq ($(UNAME_S),Windows)
	TRUNK_CONFIG := Trunk-release-windows.toml
else
	TRUNK_CONFIG := Trunk-release.toml
endif
else
ifeq ($(UNAME_S),Windows)
	TRUNK_CONFIG := Trunk-windows.toml
else
	TRUNK_CONFIG := Trunk.toml
endif
endif

ifdef release
	TRUNK_BUILD_RELEASE := true
	TRUNK_PROFILE := release
else
	TRUNK_BUILD_RELEASE := false
	TRUNK_PROFILE := debug
endif

TRUNK_BUILD_TARGET     := index-app.html
TRUNK_BUILD_PUBLIC_URL := /
TRUNK_BUILD_DIST       := dist
TRUNK_CLEAN_DIST       := dist
TRUNK_CLEAN_CARGO      := false

.PHONY: trunk-check
trunk-check: cargo-check
ifndef TRUNK_VERSION
	@echo Trunk is not installed
	$(MAKE) -e -r trunk-install
endif
	@echo Using ${TRUNK_VERSION}

.PHONY: trunk-install
trunk-install: cargo-check
	@echo Trunk is not installed
	@$(CARGO_BIN) +$(RUSTUP_TOOLCHAIN) install trunk --version ^0.16

.PHONY: trunk-build
ifdef release
trunk-build: trunk-build-release
else
trunk-build: trunk-build-debug
endif

.PHONY: trunk-build-debug
trunk-build-debug: trunk-check rustup-nightly rustup-wasm cargo-check $(TRUNK_BUILD_TARGET) $(TRUNK_CONFIG)
	@echo "Current directory: $(shell pwd)"
	@echo "Trunk config: $(TRUNK_CONFIG)"
	@rm -rf ./dist 2>/dev/null || true
	trunk build --dist ./dist
	@$(CARGO_BIN) +$(RUSTUP_TOOLCHAIN) wasm2map --patch --base-url http://localhost:7878 ./dist/dataroad-ux-site*.wasm
	@ls -al ./dist/*

.PHONY: trunk-build-release
trunk-build-release: trunk-check rustup-nightly rustup-wasm cargo-check $(TRUNK_BUILD_TARGET) $(TRUNK_CONFIG)
	@echo "Current directory: $(shell pwd)"
	@echo "Trunk config: $(TRUNK_CONFIG)"
	@rm -rf ./dist 2>/dev/null || true
	trunk build --dist ./dist --release $(TRUNK_BUILD_TARGET)
	@ls -al ./dist/*

#$(info <--- .make/trunk.mk)

endif # _MK_TRUNK_MK_
