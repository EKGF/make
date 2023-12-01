ifndef _MK_GIT_MK_
_MK_GIT_MK_ := 1

#$(info ---> .make/git.mk)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif

# Pass GIT_ROOT through to all terraform scripts as well
ifndef TF_VAR_git_root
export TF_VAR_git_root := $(GIT_ROOT)
endif

MK_DIR := $(GIT_ROOT)/.make

include $(MK_DIR)/brew.mk

GIT_CURRENT_BRANCH := $(shell git symbolic-ref --short HEAD 2>/dev/null)
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
GIT_USER_NAME := $(shell git config user.name 2>/dev/null)
GIT_REPO_NAME := $(shell x=$$(basename $$(git remote show origin -n | grep "Fetch URL" | cut -d\  -f5)); echo $${x%.git})
#$(info GIT_REPO_NAME=[$(GIT_REPO_NAME)])

GH_VERSION := $(shell gh --version 2>/dev/null | head -n1 | cut -d\  -f3)

#$(info GIT_CURRENT_BRANCH=$(GIT_CURRENT_BRANCH))

# TODO: Make the name of the environment dependent on the current git branch
ifndef TF_VAR_environment
export TF_VAR_environment := dev
else
export TF_VAR_environment := $(TF_VAR_environment)
endif

#$(info GH_VERSION=$(GH_VERSION))
#$(info GIT_ROOT=$(GIT_ROOT))

.PHONY: gh-install
ifeq ($(GH_VERSION),)
gh-install: brew-check
	@echo "Install the Github CLI (gh)"
	$(BREW_BIN) install gh
	gh --version
else
gh-install:
	@#echo "Using Github CLI: $(GH_VERSION)"
endif

#$(info <--- .make/git.mk)

endif # _MK_GIT_MK_
