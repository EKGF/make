ifndef _MK_CARGO_COMMANDS_MK_
_MK_CARGO_COMMANDS_MK_ := 1

#$(info ---> .make/cargo-commands.mk)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
ifndef MK_DIR
MK_DIR := $(GIT_ROOT)/.make
endif

include $(MK_DIR)/os.mk
include $(MK_DIR)/cargo.mk

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
	$(CARGO_BIN) +$(RUSTUP_TOOLCHAIN) upgrade --verbose 2>&1 | $(GREP_BIN) -v "warning: ignoring"

.PHONY: cargo-upgrade-locked
cargo-upgrade-locked: cargo-check
	$(CARGO_BIN) +$(RUSTUP_TOOLCHAIN) upgrade --verbose --locked 2>&1 | $(GREP_BIN) -v "warning: ignoring"

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

#$(info <--- .make/cargo-commands.mk)

endif # _MK_CARGO_COMMANDS_MK_
