#
# Load all the RDF files in this repo into OxiGraph
#
ifndef _MK_OXIGRAPH_LOAD_MK_
_MK_OXIGRAPH_LOAD_MK_ := 1

#$(info ---> .make/oxigraph-load.mk)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
ifndef MK_DIR
MK_DIR := $(GIT_ROOT)/.make
endif

include $(MK_DIR)/oxigraph.mk
include $(MK_DIR)/rdf-files.mk

ONTOLOGY_FILES_LOADED_FLAGS := $(ONTOLOGY_FILES:.ttl=.loaded.flag)
TTL_FILES_LOADED_FLAGS := $(RDF_TTL_FILES:.ttl=.loaded.flag)
NT_FILES_LOADED_FLAGS := $(RDF_NT_FILES:.nt=.loaded.flag)
RDF_FILES_LOADED_FLAGS := $(TTL_FILES_LOADED_FLAGS) $(NT_FILES_LOADED_FLAGS)

%.loaded.flag: %.ttl
	@file="$$(echo $? | $(SED_BIN) 's@$(GIT_ROOT)/@@g')" && printf "Loading RDF File $(green)$${file}$(normal)\n"
	@graph_name="$$(echo $? | $(SED_BIN) 's@$(GIT_ROOT)/@file:///@g')" ; \
		ulimit -n 10240 && $(OXIGRAPH_BIN) load --location $(OXIGRAPH_LOCATION) --file $? --graph $${graph_name} 2>&1 | grep -v "If you plan to run a read-heavy workload"
	@touch $@

%.loaded.flag: %.nt
	@file="$$(echo $? | $(SED_BIN) 's@$(GIT_ROOT)/@@g')" && printf "Loading RDF File $(green)$${file}$(normal)\n"
	@graph_name="$$(echo $? | $(SED_BIN) 's@$(GIT_ROOT)/@file:///@g')" ; \
		ulimit -n 10240 && $(OXIGRAPH_BIN) load --location $(OXIGRAPH_LOCATION) --file $? --graph $${graph_name} 2>&1 | grep -v "If you plan to run a read-heavy workload"
	@touch $@

#
# Dump all content of the OxiGraph database (stored in .oxigraph) to a temporary file called oxigraph-everything.trig
# in TriG format
#
#.INTERMEDIATE: $(TMP_DIR)/oxigraph-everything.trig
$(TMP_DIR)/oxigraph-everything.trig: oxigraph-check
	@ulimit -n 10240 && $(OXIGRAPH_BIN) dump --location $(OXIGRAPH_LOCATION) --format trig --file $@

#
# Show all content of the OxiGraph database (stored in .oxigraph) to stdout in TriG format
#
.PHONY: oxigraph-dump-trig
oxigraph-dump-trig: $(TMP_DIR)/oxigraph-everything.trig
	@cat -n $?

.PHONY: oxigraph-load-flags-delete
oxigraph-load-flags-delete:
	@rm -f $(ONTOLOGY_FILES_LOADED_FLAGS) $(TTL_FILES_LOADED_FLAGS) $(NT_FILES_LOADED_FLAGS) >/dev/null 2>&1 || true

.PHONY: oxigraph-load
oxigraph-load: oxigraph-kill $(ONTOLOGY_FILES_LOADED_FLAGS) $(RDF_FILES_LOADED_FLAGS)

.PHONY: oxigraph-reload
oxigraph-reload: oxigraph-load-flags-delete oxigraph-load
	@echo "(Re)loaded all RDF files"

oxigraph-graph-names: $(RDF_FILES)
	@for file in $? ; do \
		graph_name="$$(echo $${file} | $(SED_BIN) 's@$(GIT_ROOT)/@file:///@g')" ; \
		echo "$${graph_name}" ; \
	done

#$(info <--- .make/oxigraph-load.mk)

endif # _MK_OXIGRAPH_LOAD_MK_
