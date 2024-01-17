ifndef _MK_CARGO_MK_
_MK_CARGO_MK_ := 1

#$(info ---> .make/cargo.mk)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
ifndef MK_DIR
MK_DIR := $(GIT_ROOT)/.make
endif

include $(MK_DIR)/os.mk
include $(MK_DIR)/os-tools.mk
include $(MK_DIR)/git.mk
include $(MK_DIR)/rust-target.mk
include $(MK_DIR)/rustup.mk
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
$(shell $(MAKE) --no-print-directory --environment-overrides --no-builtin-rules rustup-install skip_cargo_check=1 skip_rustup_check=1)
endif

ifeq ($(UNAME_O),Cygwin)
$(info AAAA2)
CARGO_HOME := $(shell cygpath --windows "$(CARGO_HOME)")
endif

ifneq ("$(wildcard $(CARGO_HOME)/bin/cargo)","")
CARGO_BIN := $(CARGO_HOME)/bin/cargo
else
CARGO_BIN := $(call where-is-binary,cargo)
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
else
$(info skipped cargo check)
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

.PHONY: cargo-install
cargo-install: rustup-check cargo-install-components

.PHONY: cargo-install-components
cargo-install-components: rustup-check cargo-extensions

.PHONY: cargo-extensions
cargo-extensions: rustup-check \
	cargo-install-cocogitto \
	cargo-install-cargo-lambda \
	cargo-install-cargo-outdated \
	cargo-install-cargo-cache \
	cargo-install-cargo-edit \
	cargo-install-cargo-upgrades \
	cargo-install-wasm-pack \
	cargo-install-wasm-bindgen-cli \
	cargo-install-wasm2map

.PHONY: cargo-install-cocogitto
cargo-install-cocogitto:
	@printf "$(bold)Installing Cocogitto:\n"
	@$(CARGO_BIN) +$(RUSTUP_TOOLCHAIN) install --locked cocogitto

.PHONY: cargo-install-cargo-lambda
cargo-install-cargo-lambda: zig-install
	@printf "$(bold)Installing Cargo Lambda:\n"
	@$(CARGO_BIN) +$(RUSTUP_TOOLCHAIN) install --locked cargo-lambda

# zig is exclusively used by cargo-lambda only so for now we just put this here
# eventually we may want to move it to its own zig.mk file
.PHONY: zig-install
zig-install: brew-check $(BREW_PACKAGES)
	@printf "$(bold)Installing Zig:\n"
	@grep "^zig " $(BREW_PACKAGES) || $(BREW_BIN) install zig

.PHONY: cargo-install-cargo-edit
cargo-install-cargo-edit:
	@printf "$(bold)Installing Cargo Edit:\n"
	@$(CARGO_BIN) +$(RUSTUP_TOOLCHAIN) install --locked cargo-edit

.PHONY: cargo-install-cargo-cache
cargo-install-cargo-cache: cargo-install-cargo-outdated
	@printf "$(bold)Installing Cargo Cache:\n"
	@$(CARGO_BIN) +$(RUSTUP_TOOLCHAIN) install --locked cargo-cache

.PHONY: cargo-install-cargo-outdated
cargo-install-cargo-outdated:
	@printf "$(bold)Installing Cargo Outdated:\n"
	@$(CARGO_BIN) +$(RUSTUP_TOOLCHAIN) install --locked cargo-outdated

.PHONY: cargo-install-wasm-pack
cargo-install-wasm-pack:
	@printf "$(bold)Installing WASM Pack:\n"
	@$(CARGO_BIN) +$(RUSTUP_TOOLCHAIN) install --locked wasm-pack

.PHONY: cargo-install-wasm-bindgen-cli
cargo-install-wasm-bindgen-cli:
	@printf "$(bold)Installing WASM Bindgen CLI:\n"
	@$(CARGO_BIN) +$(RUSTUP_TOOLCHAIN) install --locked wasm-bindgen-cli

.PHONY: cargo-install-wasm2map
cargo-install-wasm2map:
	@printf "$(bold)Installing WASM2Map:\n"
	@$(CARGO_BIN) +$(RUSTUP_TOOLCHAIN) install --locked cargo-wasm2map

.PHONY: cargo-install-cargo-upgrades
cargo-install-cargo-upgrades:
	@printf "$(bold)Installing Cargo Upgrades:\n"
	@$(CARGO_BIN) +$(RUSTUP_TOOLCHAIN) install --locked cargo-upgrades

#$(info <--- .make/cargo.mk)

endif # _MK_CARGO_MK_
