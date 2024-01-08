ifndef _MK_CARGO_MK_
_MK_CARGO_MK_ := 1

#$(info ---> .make/cargo.mk)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
MK_DIR := $(GIT_ROOT)/.make

include $(MK_DIR)/os.mk
include $(MK_DIR)/os-tools.mk
include $(MK_DIR)/git.mk
include $(MK_DIR)/rust-target.mk
include $(MK_DIR)/rustup.mk
include $(MK_DIR)/cog.mk
include $(MK_DIR)/curl.mk

ifndef RUSTUP_TOOLCHAIN
$(warning RUSTUP_TOOLCHAIN not defined)
else
#$(info RUSTUP_TOOLCHAIN=$(RUSTUP_TOOLCHAIN))
endif

CARGO_BUILD_TARGET := $(RUST_TARGET)
CARGO_TARGET_DIR := $(GIT_ROOT)/target

ifndef CARGO_TARGET_DIR
$(warning CARGO_TARGET_DIR is undefined)
endif

ifdef release
BUILD_TARGET_DIR := $(CARGO_TARGET_DIR)/$(RUST_TARGET)/release
else
BUILD_TARGET_DIR := $(CARGO_TARGET_DIR)/$(RUST_TARGET)/debug
endif

# When we're doing tauri for the windows MSI file on Cygwin
# we need to not use the rust-target-specific directory
ifeq ($(UNAME_O),Cygwin)
ifdef release
BUILD_TARGET_DIR := $(CARGO_TARGET_DIR)/release
else
BUILD_TARGET_DIR := $(CARGO_TARGET_DIR)/debug
endif
endif

#$(info RUST_TARGET=$(RUST_TARGET))
#$(info RUST_TARGET_OS=$(RUST_TARGET_OS))
#$(info CARGO_TARGET_DIR=$(CARGO_TARGET_DIR))
#$(info BUILD_TARGET_DIR=$(BUILD_TARGET_DIR))

ifndef CARGO_BUILD_TARGET
$(warning CARGO_BUILD_TARGET not defined)
else
#$(info CARGO_BUILD_TARGET=$(CARGO_BUILD_TARGET))
endif

ifneq ($(skip_cargo_check),1)
ifeq ($(CARGO_HOME),)
ifeq ($(USE_USERPROFILE_AS_HOME),1)
CARGO_HOME := $(shell cygpath --windows "$(USERPROFILE)\\.cargo")
CARGO_HOME_X := $(shell cygpath --windows "$(USERPROFILE)\\.cargo")
ifneq ("$(wildcard $(CARGO_HOME_X))","")
CARGO_HOME := "$(CARGO_HOME_X)"
endif
endif
ifneq ("$(wildcard $(HOME)/.cargo)","")
CARGO_HOME := $(HOME)/.cargo
else
$(warning Could not find $(HOME)/.cargo)
endif
endif

ifeq ($(CARGO_HOME),)
$(warning Specify CARGO_HOME)
$(shell $(MAKE) --no-print-directory --environment-overrides --no-builtin-rules cargo-check skip_cargo_check=1)
endif

ifeq ($(UNAME_O),Cygwin)
$(info AAAA2)
CARGO_HOME := $(shell cygpath --windows "$(CARGO_HOME)")
endif

ifneq ("$(wildcard $(CARGO_HOME)/bin/cargo)","")
	CARGO_BIN := $(call where-is-binary,cargo)
else
	CARGO_BIN := $(CARGO_HOME)/bin/cargo
endif

# Since "sops exec-env" does not seem to work with fully qualified path names
# to executables we just have to fully rely on the PATH then on cygwin
ifeq ($(UNAME_O),Cygwin)
CARGO_BIN := cargo
endif

#$(info UNAME_O=$(UNAME_O))
#$(info CARGO_HOME=$(CARGO_HOME))
#$(info CARGO_BIN=$(CARGO_BIN))

ifdef CARGO_BIN
CARGO_VERSION := $(shell $(CARGO_BIN) --version 2>/dev/null)
else
$(warning Cargo is not installed)
endif
endif

ifdef release
CARGO_BUILD_RELEASE_FLAG := --release
CARGO_INSTALL_RELEASE_FLAG :=
else
CARGO_BUILD_RELEASE_FLAG :=
CARGO_INSTALL_RELEASE_FLAG := --debug
endif

CARGO_INCREMENTAL := 1

REQUIRE_MUSL ?= 0

ifeq ($(REQUIRE_MUSL),1)
X86_64_LINUX_MUSL_GCC_VERSION := $(shell x86_64-linux-musl-gcc --version 2>/dev/null | head -n 1 2>/dev/null)
ifndef X86_64_LINUX_MUSL_GCC_VERSION
X86_64_LINUX_MUSL_GCC_VERSION := $(shell /usr/local/bin/x86_64-linux-musl-gcc --version 2>/dev/null | head -n 1 2>/dev/null)
endif
MUSL_GCC_VERSION := $(shell musl-gcc --version 2>/dev/null | head -n 1 2>/dev/null)

$(info X86_64_LINUX_MUSL_GCC_VERSION=$(X86_64_LINUX_MUSL_GCC_VERSION))
$(info MUSL_GCC_VERSION=$(MUSL_GCC_VERSION))

ifdef X86_64_LINUX_MUSL_GCC_VERSION
CARGO_TARGET_X86_64_UNKNOWN_LINUX_MUSL_LINKER := $(shell command -v x86_64-linux-musl-gcc)
CC_x86_64_unknown_linux_musl := $(shell command -v x86_64-linux-musl-gcc)
else
ifdef MUSL_GCC_VERSION
$(info making symlink: $(shell sudo ln -fsv /usr/local/bin/musl-gcc /usr/local/bin/x86_64-linux-musl-gcc 2>&1))
#CARGO_TARGET_X86_64_UNKNOWN_LINUX_MUSL_LINKER := $(shell command -v musl-gcc)
#CC_x86_64_unknown_linux_musl := $(shell command -v musl-gcc)
CARGO_TARGET_X86_64_UNKNOWN_LINUX_MUSL_LINKER := /usr/local/bin/x86_64-linux-musl-gcc
CC_x86_64_unknown_linux_musl := /usr/local/bin/x86_64-linux-musl-gcc
else
ifneq ($(UNAME_S),Windows)
$(warning Could not find x86_64-linux-musl-gcc or musl-gcc)
# Setting it anyway, just in case
CARGO_TARGET_X86_64_UNKNOWN_LINUX_MUSL_LINKER := musl-gcc
CC_x86_64_unknown_linux_musl := musl-gcc
endif
endif
endif
endif
#CARGO_TARGET_X86_64_UNKNOWN_LINUX_MUSL_LINKER := rust-lld

unexport X86_64_LINUX_MUSL_GCC_VERSION
unexport MUSL_GCC_VERSION

#$(info CC_x86_64_unknown_linux_musl=$(CC_x86_64_unknown_linux_musl))

.PHONY: cargo-check
ifdef CARGO_BIN
cargo-check:
	@#echo "Using cargo: $(CARGO_VERSION)"
else
cargo-check: rustup-check
endif

.PHONY: cargo-install-components
cargo-install-components: rustup-check cargo-extensions

.PHONY: cargo-extensions
cargo-extensions: rustup-check \
	cog-check \
	cargo-install-lambda \
	cargo-install-cargo-outdated \
	cargo-install-cargo-cache \
	cargo-install-cargo-edit \
	cargo-install-cargo-upgrades \
	cargo-install-cargo-udeps \
	cargo-install-wasm-pack \
	cargo-install-wasm-bindgen-cli \
	cargo-install-wasm2map

.PHONY: cargo-install-cargo-lambda
cargo-install-cargo-lambda:
	@echo Install Cargo Lambda
	@$(CARGO_BIN) +$(RUSTUP_TOOLCHAIN) install --locked cargo-lambda --force

.PHONY: cargo-install-cargo-edit
cargo-install-cargo-edit:
	@echo Install Cargo Edit
	@$(CARGO_BIN) +$(RUSTUP_TOOLCHAIN) install --locked cargo-edit --force

.PHONY: cargo-install-cargo-cache
cargo-install-cargo-cache: cargo-install-cargo-outdated
	@echo Install Cargo Cache
	@$(CARGO_BIN) +$(RUSTUP_TOOLCHAIN) install --locked cargo-cache --force

.PHONY: cargo-install-cargo-outdated
cargo-install-cargo-outdated:
	@echo Install Cargo Outdated
	@$(CARGO_BIN) +$(RUSTUP_TOOLCHAIN) install --locked cargo-outdated --force

.PHONY: cargo-install-cargo-udeps
cargo-install-cargo-udeps:
	@echo Install Cargo UDeps
	@$(CARGO_BIN) +$(RUSTUP_TOOLCHAIN) install --locked cargo-udeps --force

.PHONY: cargo-install-wasm-pack
cargo-install-wasm-pack:
	@echo Install WASM Pack
	@$(CARGO_BIN) +$(RUSTUP_TOOLCHAIN) install --locked wasm-pack --force

.PHONY: cargo-install-wasm-bindgen-cli
cargo-install-wasm-bindgen-cli:
	@echo Install WASM Bindgen CLI
	@$(CARGO_BIN) +$(RUSTUP_TOOLCHAIN) install --locked wasm-bindgen-cli --force

.PHONY: cargo-install-wasm2map
cargo-install-wasm2map:
	@echo Install WASM2Map
	@$(CARGO_BIN) +$(RUSTUP_TOOLCHAIN) install --locked cargo-wasm2map --force

.PHONY: cargo-install-cargo-upgrades
cargo-install-cargo-upgrades:
	@echo Install Cargo Upgrades
	@$(CARGO_BIN) +$(RUSTUP_TOOLCHAIN) install --locked cargo-upgrades --force

.PHONY: cargo-unused-dependencies
cargo-unused-dependencies: cargo-check
	@$(CARGO_BIN) +$(RUSTUP_TOOLCHAIN) udeps --no-default-features --features no-wasm

.PHONY: cargo-unused-dependencies-wasm
cargo-unused-dependencies-wasm: cargo-check
	@$(CARGO_BIN) +$(RUSTUP_TOOLCHAIN) udeps --target wasm32-unknown-unknown --no-default-features --features wasm-support

.PHONY: cargo-outdated-dependencies
cargo-outdated-dependencies: cargo-check
	@#echo Check for outdated dependencies GIT_ROOT=$(GIT_ROOT)
	@# Copying the CI version of config.toml to config to temporarily overrule the
	@# standard .cargo/config.toml file because "cargo outdated" cannot deal with
	@# the patch statements in that file.
	#cp -v $(GIT_ROOT)/.cargo/config.toml $(GIT_ROOT)/.cargo/config.toml.original
	#cp -v $(GIT_ROOT)/.cargo/config-ci.toml $(GIT_ROOT)/.cargo/config.toml
	$(CARGO_BIN) +$(RUSTUP_TOOLCHAIN) outdated --workspace --aggressive -x rdf-store-rs -x salvo
	#cp -v $(GIT_ROOT)/.cargo/config.toml.original $(GIT_ROOT)/.cargo/config.toml

.PHONY: cargo-update-dependencies-dry-run
cargo-update-dependencies-dry-run: cargo-check
	$(CARGO_BIN) +$(RUSTUP_TOOLCHAIN) update --dry-run

.PHONY: cargo-update-dependencies
cargo-update-dependencies: cargo-check
	$(CARGO_BIN) +$(RUSTUP_TOOLCHAIN) update --color always

.PHONY: cargo-show-upgrades
cargo-show-upgrades: cargo-check
	$(CARGO_BIN) +$(RUSTUP_TOOLCHAIN) upgrades

.PHONY: cargo-upgrade
cargo-upgrade: cargo-check
	$(CARGO_BIN) +$(RUSTUP_TOOLCHAIN) upgrade --verbose 2>&1 | ggrep -v "warning: ignoring"

.PHONY: cargo-upgrade-locked
cargo-upgrade-locked: cargo-check
	$(CARGO_BIN) +$(RUSTUP_TOOLCHAIN) upgrade --verbose --locked 2>&1 | ggrep -v "warning: ignoring"

.PHONY: tree-wasm
tree-wasm: cargo-check rustup-nightly
	@$(CARGO_BIN) +$(RUSTUP_TOOLCHAIN) tree --target wasm32-unknown-unknown --features wasm-support --no-default-features --edges features

.PHONY: tree-no-wasm
tree-no-wasm: cargo-check rustup-nightly
	@$(CARGO_BIN) +$(RUSTUP_TOOLCHAIN) tree --target $(CARGO_BUILD_TARGET) --features no-wasm --no-default-features --edges features

.PHONY: build-no-wasm
build-no-wasm: cargo-check rustup-nightly
	$(CARGO_BIN) +$(RUSTUP_TOOLCHAIN) build --target $(CARGO_BUILD_TARGET) --features no-wasm --no-default-features $(CARGO_BUILD_RELEASE_FLAG)

.PHONY: build-no-wasm-and-tracing-default
build-no-wasm-and-tracing-default: cargo-check rustup-nightly
	$(CARGO_BIN) +$(RUSTUP_TOOLCHAIN) build --target $(CARGO_BUILD_TARGET) --features no-wasm,tracing-default --no-default-features $(CARGO_BUILD_RELEASE_FLAG)

.PHONY: build-wasm
build-wasm: cargo-check rustup-nightly
	$(CARGO_BIN) +$(RUSTUP_TOOLCHAIN) build --target wasm32-unknown-unknown --features wasm-support,tracing-wasm --no-default-features $(CARGO_BUILD_RELEASE_FLAG)

ifdef CARGO_BUILD_FEATURES
$(info build-with-features=$(CARGO_BUILD_FEATURES))
.PHONY: build-no-wasm-with-features
build-no-wasm-with-features: cargo-check rustup-nightly
	$(CARGO_BIN) +$(RUSTUP_TOOLCHAIN) build --target $(CARGO_BUILD_TARGET) --features no-wasm,$(CARGO_BUILD_FEATURES) --no-default-features $(CARGO_BUILD_RELEASE_FLAG)

.PHONY: build-no-wasm-with-features-and-tracing-default
build-no-wasm-with-features-and-tracing-default: cargo-check rustup-nightly
	$(CARGO_BIN) +$(RUSTUP_TOOLCHAIN) build --target $(CARGO_BUILD_TARGET) --features no-wasm,tracing-default,$(CARGO_BUILD_FEATURES) --no-default-features $(CARGO_BUILD_RELEASE_FLAG)

.PHONY: build-wasm-with-features
build-wasm-with-features: cargo-check rustup-nightly
	$(CARGO_BIN) +$(RUSTUP_TOOLCHAIN) build --target wasm32-unknown-unknown --features wasm-support,tracing-wasm,$(CARGO_BUILD_FEATURES) --no-default-features $(CARGO_BUILD_RELEASE_FLAG)

.PHONY: build-with-features
build-with-features: cargo-check rustup-nightly
	$(CARGO_BIN) +$(RUSTUP_TOOLCHAIN) build --target $(CARGO_BUILD_TARGET) --features $(CARGO_BUILD_FEATURES) --no-default-features $(CARGO_BUILD_RELEASE_FLAG)
else
#$(info no specific build features)
endif

.PHONY: test-no-wasm
test-no-wasm: cargo-check rustup-nightly
	@$(CARGO_BIN) +$(RUSTUP_TOOLCHAIN) test --target $(CARGO_BUILD_TARGET) --features no-wasm --no-default-features

.PHONY: test-bins-no-wasm
test-bins-no-wasm: cargo-check
	@$(CARGO_BIN) +$(RUSTUP_TOOLCHAIN) test --target $(CARGO_BUILD_TARGET) --features no-wasm --no-default-features --bins

.PHONY: lint-no-wasm
lint-no-wasm: cargo-check rustup-nightly
	@$(CARGO_BIN) +$(RUSTUP_TOOLCHAIN) clippy --target $(CARGO_BUILD_TARGET) --no-deps --features no-wasm --no-default-features -- --deny warnings

.PHONY: lint-wasm
lint-wasm: cargo-check rustup-nightly rustup-wasm
	@$(CARGO_BIN) +$(RUSTUP_TOOLCHAIN) clippy --target wasm32-unknown-unknown --no-deps --features wasm-support --no-default-features -- --deny warnings

#$(info <--- .make/cargo.mk)

endif # _MK_CARGO_MK_
