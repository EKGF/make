ifndef _MK_RUSTUP_MK_
_MK_RUSTUP_MK_ := 1

#$(info ---> .make/rustup.mk)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
ifndef MK_DIR
MK_DIR := $(GIT_ROOT)/.make
endif

include $(MK_DIR)/os.mk
include $(MK_DIR)/rust-target.mk
include $(MK_DIR)/curl.mk

# See https://substrate.stackexchange.com/a/9069/4489
# Don't forget to also update /rust-toolchain.toml !!
#RUSTUP_TOOLCHAIN := nightly-2023-08-26
ifndef RUSTUP_TOOLCHAIN
export RUSTUP_TOOLCHAIN := nightly
endif

ifneq ($(skip_rustup_check),1)
ifeq ($(RUSTUP_HOME),)
#$(info RUSTUP_HOME is not defined, trying to find a good default)
ifeq ($(USE_USERPROFILE_AS_HOME),1)
RUSTUP_HOME_X := $(shell cygpath --windows "$(USERPROFILE)\\.cargo")
ifneq ("$(wildcard $(RUSTUP_HOME_X))","")
export RUSTUP_HOME := "$(RUSTUP_HOME_X)"
else
$(info $(RUSTUP_HOME_X) does not exist)
endif
RUSTUP_HOME_X :=
else
ifneq ("$(wildcard $(HOME)/.rustup)","")
export RUSTUP_HOME := $(HOME)/.rustup
else
ifneq ("$(wildcard $(HOME)/.cargo)","")
export RUSTUP_HOME := $(HOME)/.cargo
else
$(info $(HOME)/.cargo does not exist)
endif
endif
endif
endif

ifeq ($(UNAME_O),Cygwin)
RUSTUP_HOME := $(shell cygpath --windows $(RUSTUP_HOME))
endif

ifeq ($(RUSTUP_HOME),)
$(warning Could not find rustup home, define RUSTUP_HOME)
export RUSTUP_HOME := $(HOME)/.rustup
$(info $(MAKE) --no-print-directory --environment-overrides --no-builtin-rules rustup-install skip_rustup_check=1 skip_cargo_check=1)
$(shell $(MAKE) --no-print-directory --environment-overrides --no-builtin-rules rustup-install skip_rustup_check=1 skip_cargo_check=1)
endif

ifneq ($(skip_rustup_check),1)
ifneq ("$(wildcard $(HOME)/.cargo/bin/rustup)","")
RUSTUP_BIN := $(HOME)/.cargo/bin/rustup
else
$(warning $(HOME)/.cargo/bin/rustup does not exist, assuming "rustup" instead)
RUSTUP_BIN := rustup
endif
endif
endif

RUSTUP_BIN := $(call where-is-binary,rustup)
# if not found look in the obvious places
ifndef RUSTUP_BIN
ifneq ("$(wildcard $(HOME)/.cargo/bin/rustup)","")
RUSTUP_BIN := $(HOME)/.cargo/bin/rustup
else
ifneq ("$(wildcard $(HOME)/.rustup/bin/rustup)","")
RUSTUP_BIN := $(HOME)/.rustup/bin/rustup
endif
endif
endif

RUSTUP_INIT_BIN := $(call where-is-binary,rustup-init)
# if not found look in the obvious places
ifndef RUSTUP_INIT_BIN
ifneq ("$(wildcard $(HOME)/.cargo/bin/rustup-init)","")
RUSTUP_INIT_BIN := $(HOME)/.cargo/bin/rustup-init
else
ifneq ("$(wildcard $(HOME)/.rustup/bin/rustup-init)","")
RUSTUP_INIT_BIN := $(HOME)/.rustup/bin/rustup-init
else
ifneq ("$(wildcard /opt/homebrew/bin/rustup-init)","")
RUSTUP_INIT_BIN := /opt/homebrew/bin/rustup-init
endif
endif
endif
else
endif

ifneq ($(RUSTUP_BIN),)
RUSTUP_VERSION := $(shell $(RUSTUP_BIN) --version 2>/dev/null | cut -d\  -f2)
endif

ifeq ($(UNAME_O),Windows)
RUSTUP_ALL_TARGETS := $(RUST_TARGET) wasm32-unknown-unknown
RUSTUP_ALL_TARGETS_STABLE := $(RUST_TARGET) wasm32-unknown-unknown
else
ifeq ($(UNAME_O),GNU/Linux)
RUSTUP_ALL_TARGETS := $(RUST_TARGET) wasm32-unknown-unknown $(UNAME_M_rust)-unknown-linux-musl $(UNAME_M)-unknown-linux-gnu
RUSTUP_ALL_TARGETS_STABLE := $(RUST_TARGET) wasm32-unknown-unknown $(UNAME_M_rust)-unknown-linux-musl $(UNAME_M)-unknown-linux-gnu
else
#$(info unrecognized UNAME_O: $(UNAME_O))
RUSTUP_ALL_TARGETS := $(RUST_TARGET) \
					  wasm32-unknown-unknown \
					  $(UNAME_M_rust)-unknown-linux-musl \
					  $(UNAME_M_rust)-unknown-linux-gnu \
					  aarch64-unknown-linux-gnu \
					  $(UNAME_M_rust)-apple-darwin
RUSTUP_ALL_TARGETS_STABLE := $(RUST_TARGET) \
                      wasm32-unknown-unknown \
                      aarch64-unknown-linux-gnu

endif
endif

#$(info RUSTUP_BIN=$(RUSTUP_BIN))
#$(info RUSTUP_INIT_BIN=$(RUSTUP_INIT_BIN))
#$(info RUSTUP_VERSION=$(RUSTUP_VERSION))
#$(info RUSTUP_TOOLCHAIN=$(RUSTUP_TOOLCHAIN))

.PHONY: rustup-install
ifdef RUSTUP_BIN
rustup-install: rustup-install-info-before rustup-toolchain-install
endif
ifdef BREW_BIN
rustup-install: rustup-install-info-before rustup-init-install-with-brew rustup-toolchain-install
else
rustup-install: rustup-install-info-before rustup-install-with-curl rustup-toolchain-install
endif

.PHONY: rustup-install-info-before
rustup-install-info-before:
	@printf "$(bold)Installing Rust:$(normal)\n"

.PHONY: rustup-init-install-with-brew
ifdef RUSTUP_INIT_BIN
rustup-init-install-with-brew: brew-check
	@printf "$(bold)rustup-init-install-with-brew:$(normal)\n"
	$(BREW_BIN) install rustup-init
else
rustup-init-install-with-brew: brew-check
	@printf "$(bold)rustup-init-install-with-brew:$(normal)\n"
	@if ! command -v rustup-init ; then \
		echo "Installing rustup-init" ; \
		$(BREW_BIN) install rustup-init ; \
		if ! command -v rustup-init ; then \
			echo "ERROR: Could not find rustup-init" ; \
			exit 1 ; \
		fi ; \
	else \
	  	echo "rustup-init is already installed" ; \
	fi
#	@rustup-init \
#  		--quiet -y \
#  		--no-update-default-toolchain \
#  		--default-toolchain $(RUSTUP_TOOLCHAIN) \
#  		--target $(RUSTUP_ALL_TARGETS) \
#  		--profile default
	@echo "****** Rustup, rust, cargo etc. have been installed ******"
endif

.PHONY: rustup-install-with-curl
rustup-install-with-curl: curl-check
	@printf "$(bold)rustup-install-with-curl:$(normal)\n"
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- \
  		--quiet -y \
  		--no-update-default-toolchain \
  		--default-toolchain $(RUSTUP_TOOLCHAIN) \
  		--target $(RUSTUP_ALL_TARGETS) \
  		--profile default
	@echo "****** Rustup, rust, cargo etc. have been installed ******"

.PHONY: rustup-info
ifdef RUSTUP_BIN
rustup-info:
	@printf "$(bold)Installed targets:$(normal)\n"
	@$(RUSTUP_BIN) target list --installed
	@printf "$(bold)Installed toolchains:$(normal)\n"
	@$(RUSTUP_BIN) toolchain list
	@printf "$(bold)Active toolchain:$(normal)\n"
	@$(RUSTUP_BIN) show
else
rustup-info:
endif

.PHONY: rustup-toolchain-install
rustup-toolchain-install: _rustup-toolchain-install-no-info rustup-info

.PHONY: _rustup-toolchain-install-no-info
ifdef RUSTUP_BIN
_rustup-toolchain-install-no-info:
	@printf "$(bold)rustup-toolchain-install:$(normal)\n"
	@printf "Installing rust via rustup\n"
	@if [[ "$(RUSTUP_TOOLCHAIN)" == "stable" ]] ; then \
		RUSTUP_INIT_SKIP_PATH_CHECK=yes $(RUSTUP_BIN) toolchain install \
			stable \
			--target $(RUSTUP_ALL_TARGETS_STABLE) \
			--profile default \
			--allow-downgrade \
			--force-non-host ; \
	else \
		RUSTUP_INIT_SKIP_PATH_CHECK=yes $(RUSTUP_BIN) toolchain install \
			$(RUSTUP_TOOLCHAIN) \
			--target $(RUSTUP_ALL_TARGETS) \
			--profile default \
			--allow-downgrade \
			--force-non-host ; \
	fi
	@$(RUSTUP_BIN) toolchain install \
		nightly \
		--target $(RUSTUP_ALL_TARGETS) \
		--profile default \
		--allow-downgrade \
		--force-non-host
else
ifdef RUSTUP_INIT_BIN
_rustup-toolchain-install-no-info:
	@printf "$(bold)rustup-toolchain-install:$(normal)\n"
	@printf "Installing rust via rustup-init\n"
	@if [[ "$(RUSTUP_TOOLCHAIN)" == "stable" ]] ; then \
  		RUSTUP_INIT_SKIP_PATH_CHECK=yes $(RUSTUP_INIT_BIN) \
  			--quiet -y \
  			--no-update-default-toolchain \
  			--default-toolchain $(RUSTUP_TOOLCHAIN) \
  			--target $(RUSTUP_ALL_TARGETS_STABLE) \
  			--profile default ; \
  	else \
		RUSTUP_INIT_SKIP_PATH_CHECK=yes $(RUSTUP_INIT_BIN) \
			--quiet -y \
			--no-update-default-toolchain \
			--default-toolchain $(RUSTUP_TOOLCHAIN) \
			--target $(RUSTUP_ALL_TARGETS) \
			--profile default ; \
	fi
else
_rustup-toolchain-install-no-info:
	$echo "ERROR: rustup-init is not installed, run $(MAKE) rustup-init-install-with-brew"
endif
endif

.PHONY: rustup-check
ifndef RUSTUP_BIN
rustup-check:
else
rustup-check: rustup-install
	@$(RUSTUP_BIN) show
endif

.PHONY: rustup-update
rustup-update: rustup-install
	$(RUSTUP_BIN) update stable nightly

.PHONY: rustup-check-components
ifeq ($(RUNNING_IN_DOCKER),1)
rustup-check-components:
	@echo "Running in docker, skipping rustup-check-components"
else
ifdef RUSTUP_BIN
rustup-check-components: rustup-check
	@printf "$(bold)rustup-check-components:$(normal)\n"
	@#echo "RUSTUP_TOOLCHAIN=$${RUSTUP_TOOLCHAIN}"
	@#echo "RUSTUP_ALL_TARGETS=$${RUSTUP_ALL_TARGETS}"
	@printf "Check rustup toolchain and components\nfor default toolchain $(green)$(RUSTUP_TOOLCHAIN)$(normal)\n and targets\n$(green)$(RUSTUP_ALL_TARGETS)$(normal):"
	$(RUSTUP_BIN) \
		toolchain install $(RUSTUP_TOOLCHAIN) \
		--target $(RUSTUP_ALL_TARGETS) \
		--component rust-docs rustc rust-std rust-src rustfmt clippy rust-analyzer
else
rustup-check-components:
endif
endif

.PHONY: rustup-nightly
rustup-nightly: rustup-check
	@$(RUSTUP_BIN) --quiet override set $(RUSTUP_TOOLCHAIN)

.PHONY: rustup-wasm
ifeq ($(RUNNING_IN_DOCKER),1)
rustup-wasm:
	@echo "Running in docker, skipping rustup-wasm"
else
rustup-wasm: rustup-check
	@$(RUSTUP_BIN) --quiet target add --toolchain $(RUSTUP_TOOLCHAIN) wasm32-unknown-unknown
endif

.PHONY: rustup-add-targets
ifeq ($(RUNNING_IN_DOCKER),1)
rustup-add-targets:
	@echo "Running in docker, skipping rustup-add-targets"
else
rustup-add-targets: rustup-target-add-default rustup-target-add-musl rustup-target-add-wasm rustup-linux-x86-64
endif

.PHONY: rustup-target-add-default
rustup-target-add-default: rustup-check
	@echo "Adding rust target: $(RUST_TARGET)"
	@$(RUSTUP_BIN) --quiet target add --toolchain $(RUSTUP_TOOLCHAIN) $(RUST_TARGET) 2>/dev/null

.PHONY: rustup-target-add-musl
ifeq ($(UNAME_O),Darwin)
rustup-target-add-musl: rustup-check musl-cross-install
	@echo "Adding rust target x86_64-unknown-linux-musl"
	@$(RUSTUP_BIN) --quiet target add --toolchain $(RUSTUP_TOOLCHAIN) x86_64-unknown-linux-musl
else
ifeq ($(UNAME_O),GNU/Linux)
rustup-target-add-musl: rustup-check _linux-tool-musl
	@echo "Adding rust target x86_64-unknown-linux-musl"
	@$(RUSTUP_BIN) --quiet target add --toolchain $(RUSTUP_TOOLCHAIN) x86_64-unknown-linux-musl
else
rustup-target-add-musl: rustup-check
	@echo "Not installing x86_64-unknown-linux-musl since we're not running on MacOS or Linux"
endif
endif

.PHONY: rustup-linux-x86-64
ifeq ($(UNAME_O),GNU/Linux)
rustup-linux-x86-64: rustup-check
	@$(RUSTUP_BIN) --quiet target add --toolchain $(RUSTUP_TOOLCHAIN) x86_64-unknown-linux-gnu
else
rustup-linux-x86-64:
	@echo "Not installing x86_64-linux-gnu since we're not running on Linux"
endif

musl-cross-install: brew-check
	@if [ ! -d $(HOMEBREW_CELLAR)/musl-cross/0.9.* ] ; then $(BREW_BIN) install FiloSottile/musl-cross/musl-cross ; else echo "musl-cross 0.9.* is already installed" ; fi

.PHONY: rustup-target-add-wasm
rustup-target-add-wasm: rustup-check
	@$(RUSTUP_BIN) --quiet target add --toolchain $(RUSTUP_TOOLCHAIN) wasm32-unknown-unknown

#$(info <--- .make/rustup.mk)

endif # _MK_RUSTUP_MK_
