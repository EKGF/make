#
# Some basic RDF file handling routines, primarily to discover the RDF files in this repo.
#
ifndef _MK_RDF_FILES_MK_
_MK_RDF_FILES_MK_ := 1

#$(info ---> .make/rdf-files.mk)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
ifndef MK_DIR
MK_DIR := $(GIT_ROOT)/.make
endif

include $(MK_DIR)/os.mk
include $(MK_DIR)/story-sparql-files.mk

ifndef RDF_STATIC_DATASET_DIR
RDF_STATIC_DATASET_DIR := $(GIT_ROOT)/static-dataset
endif
ifndef RDF_LOCAL_DATABASES_DIR
RDF_LOCAL_DATABASES_DIR := $(TMP_DIR)/database
endif
ifndef RDF_LOCAL_DATABASE_SERVERS_DIR
RDF_LOCAL_DATABASE_SERVERS_DIR := $(TMP_DIR)/database-server
endif
ifndef RDF_EXTERNAL_ONTOLOGY_DIR
RDF_EXTERNAL_ONTOLOGY_DIR := $(GIT_ROOT)/external-ontology
endif
ifndef RDF_LOCAL_ONTOLOGY_DIR
RDF_LOCAL_ONTOLOGY_DIR := $(GIT_ROOT)/ontology
endif
ifndef RDF_LOCAL_USECASES_DIR
RDF_LOCAL_USECASES_DIR := $(GIT_ROOT)/use-case
endif

EXTERNAL_ONTOLOGY_FILES := $(wildcard $(RDF_EXTERNAL_ONTOLOGY_DIR)/*.ttl)
LOCAL_ONTOLOGY_FILES := $(wildcard $(RDF_LOCAL_ONTOLOGY_DIR)/*.ttl)
ONTOLOGY_FILES := $(EXTERNAL_ONTOLOGY_FILES) $(LOCAL_ONTOLOGY_FILES)
USE_CASE_FILES := $(shell find -L $(RDF_LOCAL_USECASES_DIR) -mindepth 1 -a -name '*.ttl' -a \! -path "./.git*" -print 2>/dev/null | sort)
DATASET_NT_FILES := $(shell find -L $(RDF_STATIC_DATASET_DIR) -mindepth 1 -a -name '*.nt' -a \! -path "./.git*" -print 2>/dev/null | sort)
DATASET_TTL_FILES := $(shell find -L $(RDF_STATIC_DATASET_DIR) -mindepth 1 -a -name '*.ttl' -a \! -path "./.git*" -print 2>/dev/null | sort)
RDF_NT_FILES := $(DATASET_NT_FILES)
RDF_TTL_FILES := $(ONTOLOGY_FILES) $(USE_CASE_FILES) $(DATASET_TTL_FILES)
RDF_FILES := $(RDF_NT_FILES) $(RDF_TTL_FILES) $(STORY_SPARQL_TTL_FILES)

$(TEST_TMP)/rdf-files-to-load.txt: $(RDF_TTL_FILES)
	@echo $? | tr ' ' '\n' | sort > $@
	@printf "Found %s RDF Turtle files\n" $$(cat $@ | wc -l)

# List the RDF files in this repo
.PHONY: rdf-files-to-load
rdf-files-to-load: $(TEST_TMP)/rdf-files-to-load.txt
	@cat -n $? | sed 's@$(GIT_ROOT)/@@g'

#$(info <--- .make/rdf-files.mk)

endif # _MK_RDF_FILES_MK_
