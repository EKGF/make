#
# Install cargo-lambda see https://www.cargo-lambda.info/guide/getting-started.html
#
ifndef _MK_CARGO_LAMBDA_MK_
_MK_CARGO_LAMBDA_MK_ := 1

#$(info ---> .make/cargo-lambda.mk)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
ifndef MK_DIR
MK_DIR := $(GIT_ROOT)/.make
endif

include $(MK_DIR)/os.mk
include $(MK_DIR)/cargo.mk
include $(MK_DIR)/jq.mk

CARGO_LAMBDA_FROM_SOURCE := 1

CARGO_LAMBDA_BIN := $(call where-is-binary,cargo-lambda)

ifdef CARGO_LAMBDA_BIN
CARGO_LAMBDA_VERSION := $(shell $(CARGO_BIN) lambda --version 2>/dev/null | cut -d\  -f2)
endif
ifeq ($(CARGO_LAMBDA_FROM_SOURCE),1)
CARGO_LAMBDA_VERSION_EXPECTED := 1.0.0
else
CARGO_LAMBDA_VERSION_EXPECTED := 0.20.1
endif
ifeq ($(CARGO_LAMBDA_VERSION),$(CARGO_LAMBDA_VERSION_EXPECTED))
CARGO_LAMBDA_CHECKED := 1
else
CARGO_LAMBDA_CHECKED := 0
$(info cargo-lambda version $(CARGO_LAMBDA_VERSION) does not match expected version $(CARGO_LAMBDA_VERSION_EXPECTED))
endif

.PHONY: cargo-lambda-check
ifdef CARGO_LAMBDA_BIN
ifeq ($(CARGO_LAMBDA_CHECKED),1)
cargo-lambda-check:
	@#echo "Using cargo-lambda $(CARGO_LAMBDA_VERSION)"
else
cargo-lambda-check: cargo-lambda-install
endif
else
cargo-lambda-check: cargo-lambda-install
endif

_cargo-lambda-install-from-source: cargo-check
	@echo "Installing cargo-lambda by building it from source:"
	$(CARGO_BIN) install --locked cargo-lambda

.PHONY: _cargo-lambda-install-with-brew
_cargo-lambda-install-with-brew: brew-check cargo-check
	@echo "Installing cargo-lambda with HomeBrew:"
	$(BREW_BIN) tap cargo-lambda/cargo-lambda
	$(BREW_BIN) install cargo-lambda

.PHONY: cargo-lambda-install
ifeq ($(CARGO_LAMBDA_FROM_SOURCE),1)
cargo-lambda-install: _cargo-lambda-install-from-source
else
cargo-lambda-install: _cargo-lambda-install-with-brew
endif

#$(info <--- .make/cargo-lambda.mk)

endif # _MK_CARGO_LAMBDA_MK_
