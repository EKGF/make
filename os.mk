ifndef _MK_OS_MK_
_MK_OS_MK_ := 1

#$(info ---> .make/os.mk)
#
#$(info UNAME_M=$(UNAME_M) UNAME_S=$(UNAME_S) UNAME_O=$(UNAME_O) OS=$(OS) a)

ifeq (/usr/bin/bash,$(wildcard /usr/bin/bash))
SHELL := /usr/bin/bash
else
ifeq (/bin/bash,$(wildcard /bin/bash))
SHELL := /bin/bash
else
$(error Cannot continue without bash)
endif
endif
#ifeq (/usr/bin/zsh,$(wildcard /usr/bin/zsh))
#SHELL := /usr/bin/zsh
#else
#ifeq (/bin/zsh,$(wildcard /bin/zsh))
#SHELL := /bin/zsh
#endif
#endif

export SHELL := $(SHELL)
#$(info SHELL=$(SHELL))

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
MK_DIR := $(GIT_ROOT)/.make

ifeq ($(shell uname -r | cut -d- -f4),WSL2)
WSL := 1
endif
ifdef WSL
#$(info We are running under WSL2)
OS := GNU/Linux
endif

ifndef UNAME_M
ifeq ($(OS),Windows_NT)
UNAME_M := x86_64
else
UNAME_M := $(shell uname -m)
endif
endif

#$(info UNAME_M=$(UNAME_M) UNAME_S=$(UNAME_S) UNAME_O=$(UNAME_O) OS=$(OS) b)

ifndef UNAME_S
ifeq ($(OS),Windows_NT)
UNAME_S := Windows
else
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
else
endif
endif
endif

ifndef UNAME_O
ifeq ($(OS),Windows_NT)
UNAME_O := Windows
else
ifeq ($(UNAME_S),Darwin)
UNAME_O := Darwin
OS := Darwin
else
UNAME_O := $(shell uname -o)
OS := $(UNAME_O)
endif
endif
endif

ifeq ($(UNAME_O),Windows)
UNAME_S_lc := windows
BIN_SUFFIX := .exe
WHICH := where
TMP_DIR ?= $(TMP)
BSDTAR := bsdtar
else
BIN_SUFFIX :=
WHICH := command -v
ifeq ($(UNAME_O),Darwin)
UNAME_S_lc := darwin
TMP_DIR ?: $(shell cd $(TMPDIR) && pwd)
BSDTAR := bsdtar
else
UNAME_S_lc := linux
TMP_DIR ?= /var/tmp
BSDTAR := bsdtar
endif
endif

#$(info UNAME_M=$(UNAME_M) UNAME_S_lc=$(UNAME_S_lc) UNAME_S=$(UNAME_S) UNAME_O=$(UNAME_O) OS=[$(OS)])

ifeq ($(AWS_EXECUTION_ENV),CloudShell)
RUNNING_IN_CLOUDSHELL := 1
$(info We are running in AWS CloudShell)
else
RUNNING_IN_CLOUDSHELL := 0
#$(info We are not running in AWS CloudShell)
endif

IS_LINUX_WITH_APT := 0
IS_LINUX_WITH_YUM := 0
ifeq ($(UNAME_S_lc),linux)
ifeq ($(RUNNING_IN_CLOUDSHELL),1)
IS_LINUX_WITH_APT := 0
IS_LINUX_WITH_YUM := 1
else
ifndef WSL
$(info Unrecognized linux distribution, assuming apt over yum)
endif
IS_LINUX_WITH_APT := 1
IS_LINUX_WITH_YUM := 0
endif
endif

USE_USERPROFILE_AS_HOME := 0
ifdef USERPROFILE
ifeq ($(UNAME_O),Cygwin)
USE_USERPROFILE_AS_HOME := 1
endif
endif

ifeq ($(IS_LINUX_WITH_APT),1)
export DEBIAN_FRONTEND := noninteractive
endif

ifneq ($(wildcard /home/linuxbrew/.linuxbrew/sbin),)
export PATH := /home/linuxbrew/.linuxbrew/sbin:$(PATH)
endif
ifneq ($(wildcard /home/linuxbrew/.linuxbrew/bin),)
export PATH := /home/linuxbrew/.linuxbrew/bin:$(PATH)
endif

#$(info UNAME_S_lc=$(UNAME_S_lc) UNAME_M=$(UNAME_M) UNAME_S=$(UNAME_S) UNAME_O=$(UNAME_O) OS=$(OS) e)

define check-directory
$(shell mkdir -p $1 >/dev/null 2>&1 && echo $1)
endef

define check-file
$(shell mkdir -p $(shell echo $$(dirname $1)) >/dev/null 2>&1 && echo $1)
endef

define where-is-binary
$(shell command -v $1 2>/dev/null)
endef

define command-exists
$(shell command -v $1 2>/dev/null)
endef

# Overrule the TMP_DIR definition that we have above for now, just want to keep the tmp directory close by
override TMP_DIR := $(call check-directory,$(GIT_ROOT)/.tmp)
TEST_TMP := $(call check-directory,$(TMP_DIR)/test-data)

ifdef TMP_DIR
#
# We'll be creating a number of (temporary) executable symlinks in the TMP_DIR,
# so we need to make sure that it's in the PATH
#
export PATH := $(TMP_DIR):$(PATH)
else
$(error Cannot continue without a proper value in TMP_DIR)
endif

$(TMP_DIR):
	@mkdir -p $@

$(TEST_TMP): $(TMP_DIR)
	@mkdir -p $@

PKG_CONFIG_SYSROOT_DIR := /

bold   := \033[1m
normal := \033[0m
black  := \033[30m
red    := \033[31m
green  := \033[32m
blue   := \033[34m
gray   := \033[100m

REALPATH_BIN := $(call where-is-binary,grealpath)
ifndef REALPATH_BIN
ifeq ($(UNAME_S_lc),darwin)
$(error GNU realpath is not installed, please install it using 'brew install coreutils')
else
REALPATH_BIN := $(call where-is-binary,realpath)
endif
endif

SED_BIN := $(call where-is-binary,gsed)
ifndef SED_BIN
SED_BIN := $(call where-is-binary,sed)
endif

GREP_BIN := $(call where-is-binary,ggrep)
ifndef GREP_BIN
GREP_BIN := $(call where-is-binary,grep)
endif

PGREP_BIN := $(call where-is-binary,pgrep)
ifdef PGREP_BIN
PKILL_BIN := $(call where-is-binary,pkill)
endif

# A literal space, using a trick documented here: https://ftp.gnu.org/old-gnu/Manuals/make-3.79.1/html_chapter/make_6.html
nullstring :=
space := $(nullstring) # end of the line
comma := ,
comma_space := ,$(space)

# Joins elements of the list in arg 2 with the given separator.
#   1. Element separator.
#   2. The list.
join-with = $(subst $(space),$1,$(strip $2))

#$(info <--- .make/os.mk)

endif # _MK_OS_MK_
