ifndef _MK_LLVM_MK_
_MK_LLVM_MK_ := 1

#$(info ---> .make/llvm.mk)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
ifndef MK_DIR
MK_DIR := $(GIT_ROOT)/.make
endif

include $(MK_DIR)/os.mk
include $(MK_DIR)/git.mk
include $(MK_DIR)/os-tools-*.mk
include $(MK_DIR)/rustup.mk
include $(MK_DIR)/brew.mk
include $(MK_DIR)/curl.mk

LLVM_VERSION_EXPECTED := 17.0.6
LLVM_MAIN_VERSION_EXPECTED := $(shell echo $(LLVM_VERSION_EXPECTED) | cut -d. -f1)

ifneq ($(wildcard $(HOMEBREW_CELLAR)/llvm/$(LLVM_VERSION_EXPECTED)/lib),)
LLVM_LIB_PATH := $(HOMEBREW_CELLAR)/llvm/$(LLVM_VERSION_EXPECTED)/lib
else
ifneq ($(wildcard /usr/lib/llvm-$(LLVM_MAIN_VERSION_EXPECTED)/lib),)
LLVM_LIB_PATH := /usr/lib/llvm-$(LLVM_MAIN_VERSION_EXPECTED)/lib
endif
endif

ifndef LLVM_LIB_PATH
ifdef LLVM_PATH
LLVM_LIB_PATH := $(LLVM_PATH)
else
ifneq ($(wildcard $(HOMEBREW_PREFIX)/opt/llvm/lib),)
LLVM_LIB_PATH := $(HOMEBREW_PREFIX)/opt/llvm/lib
else
LLVM_LIB_PATH := /usr/local/opt/llvm/lib
endif
endif
endif

ifndef LLVM_LIB_PATH
$(warning LLVM_LIB_PATH is not defined)
endif

ifneq ($(skip_llvm_check),1)
ifeq ("$(wildcard $(LLVM_LIB_PATH))","")
$(warning Directory $(LLVM_LIB_PATH) does not exist, we need to install LLVM)
$(shell $(MAKE) --no-print-directory --environment-overrides --no-builtin-rules llvm-install-with-brew skip_cargo_check=1 skip_llvm_check=1)
endif
endif

ifdef LLVM_LIB_PATH
# LLVM_BIN_PATH is something like: /usr/local/opt/llvm/bin/
export LLVM_BIN_PATH := $(shell cd $(LLVM_LIB_PATH) 2>/dev/null && cd ../bin && pwd)
#$(info LLVM_BIN_PATH=$(LLVM_BIN_PATH))

# LLVM_INC_PATH is something like: /usr/local/opt/llvm/include
export LLVM_INC_PATH := $(shell cd $(LLVM_LIB_PATH) 2>/dev/null && cd ../include && pwd)
#$(info LLVM_INC_PATH=$(LLVM_INC_PATH))

export LDFLAGS="-L$(LLVM_LIB_PATH)/c++ -Wl,-rpath,$(LLVM_LIB_PATH)/c++"
endif

ifdef LLVM_INC_PATH
export CPPFLAGS="-I$(LLVM_INC_PATH)"
endif

ifdef LLVM_BIN_PATH
export CC=$(LLVM_BIN_PATH)/clang
export CXX=$(LLVM_BIN_PATH)/clang++
endif

ifeq ($(UNAME_S),Darwin)
export BINDGEN_EXTRA_LLVM_ARGS="-I /Library/Developer/CommandLineTools/usr/include/c++/v1 -I /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include"
endif

CLANG_BIN := $(call where-is-binary,clang)

ifdef CLANG_BIN
LLVM_VERSION := $(shell "$(CLANG_BIN)" --version 2>/dev/null | head -n1 | cut -d\  -f4)
endif
ifeq ($(LLVM_VERSION),$(LLVM_VERSION_EXPECTED))
LLVM_CHECKED := 1
else
LLVM_CHECKED := 0
$(info LLVM version $(LLVM_VERSION) does not match expected version $(LLVM_VERSION_EXPECTED))
endif

.PHONY: llvm-check
ifdef CLANG_BIN
ifeq ($(LLVM_CHECKED),1)
llvm-check:
	@echo "Using LLVM $(LLVM_VERSION)"
else
llvm-check: llvm-install-with-brew
endif
else
llvm-check: llvm-install-with-brew
endif

ifdef CLANG_BIN
.INTERMEDIATE: $(TMP_DIR)/llvm
$(TMP_DIR)/llvm:
	ln -s $(CLANG_BIN) $@
	chmod +x $@
else
$(TMP_DIR)/llvm:
	@echo "ERROR: llvm $(LLVM_VERSION_EXPECTED) not installed"
	exit 1
endif

.PHONY: llvm-install-with-brew
llvm-install-with-brew: brew-check
	$(BREW_BIN) install --overwrite llvm@$(LLVM_MAIN_VERSION_EXPECTED)
	$(BREW_BIN) unlink llvm@$(LLVM_MAIN_VERSION_EXPECTED)
	$(BREW_BIN) link --force --overwrite llvm@$(LLVM_MAIN_VERSION_EXPECTED)

.PHONY: clang-check
clang-check: llvm-check

.PHONY: clang-install
clang-install: llvm-install-with-brew

#$(info <--- .make/llvm.mk)

endif # _MK_LLVM_MK_
