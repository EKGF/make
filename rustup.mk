ifndef _MK_RUSTUP_MK_
_MK_RUSTUP_MK_ := 1

#$(info ---> .make/rustup.mk)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
MK_DIR := $(GIT_ROOT)/.make

include $(MK_DIR)/os.mk
include $(MK_DIR)/rust-target.mk
include $(MK_DIR)/curl.mk

# See https://substrate.stackexchange.com/a/9069/4489
# Don't forget to also update /rust-toolchain.toml !!
#RUSTUP_TOOLCHAIN := nightly-2023-08-26
RUSTUP_TOOLCHAIN := stable

ifneq ($(skip_rustup_check),1)
ifeq ($(RUSTUP_HOME),)
#$(info RUSTUP_HOME is not defined, trying to find a good default)
ifeq ($(USE_USERPROFILE_AS_HOME),1)
RUSTUP_HOME_X := $(shell cygpath --windows "$(USERPROFILE)\\.cargo")
ifneq ("$(wildcard $(RUSTUP_HOME_X))","")
RUSTUP_HOME := "$(RUSTUP_HOME_X)"
else
$(info $(RUSTUP_HOME_X) does not exist either)
endif
RUSTUP_HOME_X :=
else
ifneq ("$(wildcard $(HOME)/.cargo)","")
RUSTUP_HOME := $(HOME)/.cargo
else
$(info $(HOME)/.cargo does not exist either)
endif
endif
endif

ifeq ($(UNAME_O),Cygwin)
RUSTUP_HOME := $(shell cygpath --windows $(RUSTUP_HOME))
endif

ifeq ($(RUSTUP_HOME),)
$(warning Could not find rustup home, define RUSTUP_HOME)
$(info $(MAKE) --no-print-directory --environment-overrides --no-builtin-rules rustup-install skip_rustup_check=1 skip_cargo_check=1)
$(shell $(MAKE) --no-print-directory --environment-overrides --no-builtin-rules rustup-install skip_rustup_check=1 skip_cargo_check=1)
endif

ifneq ("$(wildcard $(HOME)/.cargo/bin/rustup)","")
RUSTUP_BIN := $(HOME)/.cargo/bin/rustup
else
$(warning $(HOME)/.cargo/bin/rustup does not exist, assuming "rustup" instead)
RUSTUP_BIN := rustup
endif
endif

ifeq ($(UNAME_O),Cygwin)
RUSTUP_BIN := $(shell cygpath --windows $(RUSTUP_BIN))
else
RUSTUP_BIN := $(shell command -v rustup 2>/dev/null)
endif

ifneq ($(RUSTUP_BIN),)
RUSTUP_VERSION := $(shell $(RUSTUP_BIN) --version 2>/dev/null | cut -d\  -f2)
endif

ifeq ($(UNAME_O),Windows)
RUSTUP_ALL_TARGETS := $(RUST_TARGET) wasm32-unknown-unknown
else
ifeq ($(UNAME_O),GNU/Linux)
RUSTUP_ALL_TARGETS := $(RUST_TARGET) wasm32-unknown-unknown x86_64-unknown-linux-musl x86_64-unknown-linux-gnu
else
#$(info unrecognized UNAME_O: $(UNAME_O))
RUSTUP_ALL_TARGETS := $(RUST_TARGET) \
					  wasm32-unknown-unknown \
					  x86_64-unknown-linux-musl \
					  x86_64-unknown-linux-gnu \
					  x86_64-apple-darwin
endif
endif

#$(info RUSTUP_BIN=$(RUSTUP_BIN))
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
	@echo "Installing Rust"


.PHONY: rustup-init-install-with-brew
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
rustup-info:
	@printf "$(bold)Installed targets:$(normal)\n"
	@~/.cargo/bin/rustup target list --installed
	@printf "$(bold)Installed toolchains:$(normal)\n"
	@~/.cargo/bin/rustup toolchain list
	@printf "$(bold)Active toolchain:$(normal)\n"
	@~/.cargo/bin/rustup show

.PHONY: rustup-toolchain-install
rustup-toolchain-install: _rustup-toolchain-install-no-info rustup-info

.PHONY: _rustup-toolchain-install-no-info
_rustup-toolchain-install-no-info:
	@printf "$(bold)rustup-toolchain-install:$(normal)\n"
	@~/.cargo/bin/rustup toolchain install \
		stable \
		--target $(RUSTUP_ALL_TARGETS) \
		--profile default \
		--allow-downgrade \
		--force-non-host
	@~/.cargo/bin/rustup toolchain install \
		nightly \
		--target $(RUSTUP_ALL_TARGETS) \
		--profile default \
		--allow-downgrade \
		--force-non-host
	@~/.cargo/bin/rustup toolchain install \
		$(RUSTUP_TOOLCHAIN) \
		--target $(RUSTUP_ALL_TARGETS) \
		--profile default \
		--allow-downgrade \
		--force-non-host

.PHONY: rustup-check
ifdef RUSTUP_VERSION
rustup-check:
else
rustup-check: rustup-install
	@~/.cargo/bin/rustup show
endif

.PHONY: rustup-update
rustup-update: rustup-install
	$(RUSTUP_BIN) update stable nightly

.PHONY: rustup-check-components
ifeq ($(RUNNING_IN_DOCKER),1)
rustup-check-components:
	@echo "Running in docker, skipping rustup-check-components"
else
rustup-check-components: rustup-check
	@printf "$(bold)rustup-check-components:$(normal)\n"
	@#echo "RUSTUP_TOOLCHAIN=$${RUSTUP_TOOLCHAIN}"
	@#echo "RUSTUP_ALL_TARGETS=$${RUSTUP_ALL_TARGETS}"
	@printf "Check rustup toolchain and components\nfor default toolchain $(green)$(RUSTUP_TOOLCHAIN)$(normal)\n and targets\n$(green)$(RUSTUP_ALL_TARGETS)$(normal):"
	$(RUSTUP_BIN) \
		toolchain install $(RUSTUP_TOOLCHAIN) \
		--target $(RUSTUP_ALL_TARGETS) \
		--component rust-docs rustc rust-std rust-src rustfmt clippy rust-analyzer
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
