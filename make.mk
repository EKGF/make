ifndef _MK_MAKE_MK_
_MK_MAKE_MK_ := 1

#$(info ---> .make/make.mk)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
MK_DIR := $(GIT_ROOT)/.make

ifndef MK_TAR_DIR
MK_TAR_DIR := $(HOME)/.tmp
endif
ifndef MK_TAR
MK_TAR := $(MK_TAR_DIR)/make.tar.gz
endif

# Avoid failing recipes leaving behind bad outputs that are then
# treated as current by subsequent make invocations.
.DELETE_ON_ERROR:

# Suppress some annoying output that GNU make would otherwise produce
MAKEFLAGS += --silent

include $(MK_DIR)/os.mk

ifeq ($(UNAME_S),Windows)
MAKE_BIN := $(call where-is-binary,make)
else
MAKE_BIN := $(call where-is-binary,gmake)
ifndef MAKE_BIN
MAKE_BIN := $(call where-is-binary,make)
endif
endif

MAKE_BIN := $(strip $(MAKE_BIN))

IS_MAKE_3 := $(shell $(MAKE) --version 2>/dev/null | head -n1 | grep -q 'GNU Make 3' && echo 1 || echo 0)
ifeq ($(IS_MAKE_3),1)
$(warning You're using GNU Make version $(MAKE_VERSION), you should use version 4, try the gmake command)
else
undefine IS_MAKE_3
endif

ifdef MAKE_BIN
# Since "sops exec-env" does not seem to work with fully qualified path names
# to executables we just have to fully rely on the PATH then on cygwin
ifeq ($(UNAME_O),Cygwin)
MAKE_BIN := make
endif
endif

ifdef MAKE_BIN
ifeq ($(UNAME_S),Windows)
MAKE_VERSION := 4.3
MAKE_VERSION_MAJOR := 4
else
MAKE_VERSION := $(shell $(MAKE_BIN) --version 2>/dev/null | head -n1 | cut -d\  -f3)
MAKE_VERSION_MAJOR := $(shell echo $(MAKE_VERSION) | cut -d. -f1)
endif
ifneq ($(MAKE_VERSION_MAJOR),4)
#$(info MAKE_VERSION=$(MAKE_VERSION))
$(warning Install GNU Make version 4, you currently have: $(MAKE_VERSION))
endif
endif

.PHONY: help
help: $(GIT_ROOT)/Makefile $(MK_DIR)/*.mk
	@printf "$(bold)$(green)Usage:$(normal)\n\n"
	@printf "$(bold)  make <target>$(normal)\n\n"
	@printf "$(bold)  where <target> is any of the following:$(normal)\n\n"
	-@$(SED_BIN) -n 's/^\.PHONY: \([^_].*\)/\1/p' $^ | sort -u

.PHONY: mk-tar
mk-tar:
	@echo "Creating the $(MK_TAR) file"
	mkdir -p $(MK_TAR_DIR)
	tar --exclude .git --exclude .idea --exclude .tmp -czvf  $(MK_TAR) .

#$(info <--- .make/make.mk)

endif # _MK_MAKE_MK_
