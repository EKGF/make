ifndef _MK_LLVM_MK_
_MK_LLVM_MK_ := 1

#$(info ---> .make/llvm.mk)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
MK_DIR := $(GIT_ROOT)/.make

include $(MK_DIR)/os.mk
include $(MK_DIR)/git.mk
include $(MK_DIR)/os-tools-*.mk
include $(MK_DIR)/rustup.mk
include $(MK_DIR)/brew.mk
include $(MK_DIR)/curl.mk

LLVM_VERSION_EXPECTED := 17.0.6
LLVM_MAIN_VERSION_EXPECTED := $(shell echo $(LLVM_VERSION_EXPECTED) | cut -d. -f1)

ifneq ($(wildcard /home/linuxbrew/.linuxbrew/Cellar/llvm/$(LLVM_VERSION_EXPECTED)/lib),)
LLVM_LIB_PATH := /home/linuxbrew/.linuxbrew/Cellar/llvm/$(LLVM_VERSION_EXPECTED)/lib
else
ifneq ($(wildcard /usr/lib/llvm-$(LLVM_MAIN_VERSION_EXPECTED)/lib),)
LLVM_LIB_PATH := /usr/lib/llvm-$(LLVM_MAIN_VERSION_EXPECTED)/lib
endif
endif

ifndef LLVM_LIB_PATH
ifdef LLVM_PATH
LLVM_LIB_PATH := $(LLVM_PATH)
else
LLVM_LIB_PATH := /usr/local/opt/llvm/lib
endif
endif

ifndef LLVM_LIB_PATH
$(warning LLVM_LIB_PATH is not defined)
endif

ifeq ("$(wildcard $(LLVM_LIB_PATH))","")
$(warning Directory $(LLVM_LIB_PATH) does not exist)
endif

# LLVM_BIN_PATH is something like: /usr/local/opt/llvm/bin/
export LLVM_BIN_PATH := $(shell cd $(LLVM_LIB_PATH) 2>/dev/null && cd ../bin && pwd)
#$(info LLVM_BIN_PATH=$(LLVM_BIN_PATH))

# LLVM_INC_PATH is something like: /usr/local/opt/llvm/include
export LLVM_INC_PATH := $(shell cd $(LLVM_LIB_PATH) 2>/dev/null && cd ../include && pwd)
#$(info LLVM_INC_PATH=$(LLVM_INC_PATH))

export LDFLAGS="-L$(LLVM_LIB_PATH)/c++ -Wl,-rpath,$(LLVM_LIB_PATH)/c++"
export CPPFLAGS="-I$(LLVM_INC_PATH)"

export CC=$(LLVM_BIN_PATH)/clang
export CXX=$(LLVM_BIN_PATH)/clang++

ifeq ($(UNAME_S),Darwin)
export BINDGEN_EXTRA_LLVM_ARGS="-I /Library/Developer/CommandLineTools/usr/include/c++/v1 -I /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include"
endif

#$(info LLVM_LIB_PATH=$(LLVM_LIB_PATH))

#$(info LLVM_PATH=$(LLVM_PATH))

CLANG_BIN := $(call where-is-binary,clang)

ifdef CLANG_BIN
LLVM_VERSION := $(shell "$(CLANG_BIN)" --version 2>/dev/null | head -n1 | cut -d\  -f4)
#$(info LLVM_VERSION=$(LLVM_VERSION))
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
llvm-check: llvm-install
endif
else
llvm-check: llvm-install
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

.PHONY: llvm-install
llvm-install: brew-check
	$(BREW_BIN) install --overwrite llvm@$(LLVM_MAIN_VERSION_EXPECTED)
	$(BREW_BIN) unlink llvm@$(LLVM_MAIN_VERSION_EXPECTED)
	$(BREW_BIN) link --force --overwrite llvm@$(LLVM_MAIN_VERSION_EXPECTED)

.PHONY: clang-check
clang-check: llvm-check

.PHONY: clang-install
clang-install: llvm-install

#$(info <--- .make/llvm.mk)

endif # _MK_LLVM_MK_
