ifndef _MK_USE_CASE_MK_
_MK_USE_CASE_MK_ := 1

#$(info ---> .make/use-case.mk)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
ifndef MK_DIR
MK_DIR := $(GIT_ROOT)/.make
endif

include $(MK_DIR)/os.mk

USE_CASE_ROOT := $(RDF_LOCAL_USECASES_DIR)/
USE_CASE_DIRECTORIES := $(filter-out $(USE_CASE_ROOT),$(sort $(dir $(wildcard $(USE_CASE_ROOT)*/))))
STORY_DIRECTORIES := $(foreach dir,$(USE_CASE_DIRECTORIES),$(dir)stories)

$(USE_CASE_DIRECTORIES):
	@echo $@bbb

$(STORY_DIRECTORIES): $(USE_CASE_DIRECTORIES)
	@mkdir -p $@

.PHONY: use-case-directories-check
use-case-directories-check: $(STORY_DIRECTORIES)

.PHONY: use-case-directories
use-case-show-directories: $(USE_CASE_DIRECTORIES)
	@echo $(USE_CASE_DIRECTORIES) | xargs -n 1

.PHONY: story-show-directories
story-show-directories: $(STORY_DIRECTORIES)
	@echo $(STORY_DIRECTORIES) | xargs -n 1

#$(info <--- .make/use-case.mk)

endif # _MK_USE_CASE_MK_
