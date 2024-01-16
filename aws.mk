ifndef _MK_AWS_MK_
_MK_AWS_MK_ := 1

#$(info ---> .make/aws.mk)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
ifndef MK_DIR
MK_DIR := $(GIT_ROOT)/.make
endif

include $(MK_DIR)/os.mk

AWS_BIN := $(call where-is-binary,aws)
ifdef AWS_BIN
AWS_CLI_VERSION := $(shell "$(AWS_BIN)" --version 2>/dev/null | cut -d/ -f2 | cut -d\  -f1)
#$(info Using AWS CLI $(AWS_CLI_VERSION))
else
ifeq ($(UNAME_S),Windows)
$(warning Install AWS CLI manually)
endif
endif

.PHONY: aws-cli-check
ifeq ($(AWS_CLI_VERSION),)
ifeq ($(UNAME_S),Windows)
aws-cli-check:
	@echo Install AWS CLI manually
	exit 1
else
aws-cli-check: brew-check
	@echo Install AWS CLI
	$(BREW_BIN) install awscli
endif
else
aws-cli-check:
	@#echo "Using AWS CLI $(AWS_CLI_VERSION)"
endif

#$(info <--- .make/aws.mk)

endif # _MK_AWS_MK_
