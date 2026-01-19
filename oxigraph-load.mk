#
# Load all the RDF files in this repo into OxiGraph
#
# Two loading strategies:
# - bulk-load: Kills server, loads directly via CLI (faster for initial/full loads)
# - http-load: Loads via HTTP to running server (for incremental updates, supports parallel)
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

ifeq ($(USE_OXIGRAPH),1)

include $(MK_DIR)/oxigraph.mk
include $(MK_DIR)/rdf-files.mk
include $(MK_DIR)/curl.mk

OXIGRAPH_ENDPOINT := http://localhost:$(OXIGRAPH_PORT)

# Bulk load flags (CLI-based, requires server to be stopped)
ONTOLOGY_FILES_BULK_LOADED_FLAGS := $(ONTOLOGY_FILES:.ttl=.bulk-loaded.flag)
TTL_FILES_BULK_LOADED_FLAGS := $(RDF_TTL_FILES:.ttl=.bulk-loaded.flag)
NT_FILES_BULK_LOADED_FLAGS := $(RDF_NT_FILES:.nt=.bulk-loaded.flag)
RDF_FILES_BULK_LOADED_FLAGS := $(TTL_FILES_BULK_LOADED_FLAGS) $(NT_FILES_BULK_LOADED_FLAGS)

# HTTP load flags (HTTP-based, server must be running, supports parallel)
ONTOLOGY_FILES_HTTP_LOADED_FLAGS := $(ONTOLOGY_FILES:.ttl=.http-loaded.flag)
TTL_FILES_HTTP_LOADED_FLAGS := $(RDF_TTL_FILES:.ttl=.http-loaded.flag)
NT_FILES_HTTP_LOADED_FLAGS := $(RDF_NT_FILES:.nt=.http-loaded.flag)
RDF_FILES_HTTP_LOADED_FLAGS := $(TTL_FILES_HTTP_LOADED_FLAGS) $(NT_FILES_HTTP_LOADED_FLAGS)

#
# Bulk load rules - load directly to database files via CLI
# Server must be stopped (oxigraph-kill is a dependency)
#
%.bulk-loaded.flag: %.ttl
	@file="$$(echo $? | $(SED_BIN) 's@$(GIT_ROOT)/@@g')" && printf "Bulk loading RDF File $(green)$${file}$(normal)\n"
	@graph_name="$$(echo $? | $(SED_BIN) 's@$(GIT_ROOT)/@file:///@g')" ; \
		ulimit -n 10240 && $(OXIGRAPH_BIN) load --location $(OXIGRAPH_LOCATION) --file $? --graph $${graph_name} 2>&1 | { grep -v "If you plan to run a read-heavy workload" || true; }
	@touch $@

%.bulk-loaded.flag: %.nt
	@file="$$(echo $? | $(SED_BIN) 's@$(GIT_ROOT)/@@g')" && printf "Bulk loading RDF File $(green)$${file}$(normal)\n"
	@graph_name="$$(echo $? | $(SED_BIN) 's@$(GIT_ROOT)/@file:///@g')" ; \
		ulimit -n 10240 && $(OXIGRAPH_BIN) load --location $(OXIGRAPH_LOCATION) --file $? --graph $${graph_name} 2>&1 | { grep -v "If you plan to run a read-heavy workload" || true; }
	@touch $@

#
# HTTP load rules - load via HTTP POST to running server
# Supports parallel execution (use make -j)
#
%.http-loaded.flag: %.ttl
	@file="$$(echo $? | $(SED_BIN) 's@$(GIT_ROOT)/@@g')" && printf "HTTP loading RDF File $(green)$${file}$(normal)\n"
	@graph_name="$$(echo $? | $(SED_BIN) 's@$(GIT_ROOT)/@file:///@g')" ; \
		$(CURL_BIN) -sf -X POST -H "Content-Type: text/turtle" \
			--data-binary @$? \
			"$(OXIGRAPH_ENDPOINT)/store?graph=$${graph_name}" \
		|| { printf "$(red)ERROR: Failed to load $${file}. Is OxiGraph running? Try: gmake oxigraph-serve$(normal)\n" >&2; exit 1; }
	@touch $@

%.http-loaded.flag: %.nt
	@file="$$(echo $? | $(SED_BIN) 's@$(GIT_ROOT)/@@g')" && printf "HTTP loading RDF File $(green)$${file}$(normal)\n"
	@graph_name="$$(echo $? | $(SED_BIN) 's@$(GIT_ROOT)/@file:///@g')" ; \
		$(CURL_BIN) -sf -X POST -H "Content-Type: application/n-triples" \
			--data-binary @$? \
			"$(OXIGRAPH_ENDPOINT)/store?graph=$${graph_name}" \
		|| { printf "$(red)ERROR: Failed to load $${file}. Is OxiGraph running? Try: gmake oxigraph-serve$(normal)\n" >&2; exit 1; }
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

.PHONY: oxigraph-bulk-load-flags-delete
oxigraph-bulk-load-flags-delete:
	@rm -f $(ONTOLOGY_FILES_BULK_LOADED_FLAGS) $(TTL_FILES_BULK_LOADED_FLAGS) $(NT_FILES_BULK_LOADED_FLAGS) >/dev/null 2>&1 || true

.PHONY: oxigraph-http-load-flags-delete
oxigraph-http-load-flags-delete:
	@rm -f $(ONTOLOGY_FILES_HTTP_LOADED_FLAGS) $(TTL_FILES_HTTP_LOADED_FLAGS) $(NT_FILES_HTTP_LOADED_FLAGS) >/dev/null 2>&1 || true

.PHONY: oxigraph-load-flags-delete
oxigraph-load-flags-delete: oxigraph-bulk-load-flags-delete oxigraph-http-load-flags-delete

#
# Bulk load: kills server first, loads via CLI (fast, sequential)
#
.PHONY: oxigraph-bulk-load
oxigraph-bulk-load: oxigraph-kill $(ONTOLOGY_FILES_BULK_LOADED_FLAGS) $(RDF_FILES_BULK_LOADED_FLAGS)
	@printf "$(green)Bulk loaded all RDF files$(normal)\n"

#
# Check if OxiGraph server is running
#
.PHONY: oxigraph-server-check
oxigraph-server-check:
	@$(CURL_BIN) -sf "$(OXIGRAPH_ENDPOINT)/" >/dev/null 2>&1 \
		|| { printf "$(red)ERROR: OxiGraph server is not running at $(OXIGRAPH_ENDPOINT)$(normal)\n"; \
		     printf "$(yellow)Start it with: gmake oxigraph-serve$(normal)\n"; exit 1; }

#
# Internal target for HTTP loading files (called with parallelism)
#
.PHONY: _oxigraph-http-load-files
_oxigraph-http-load-files: $(ONTOLOGY_FILES_HTTP_LOADED_FLAGS) $(RDF_FILES_HTTP_LOADED_FLAGS)

#
# HTTP load: loads to running server via HTTP (incremental, parallel-safe)
# Automatically runs with -j10 for parallel loading
# Requires server to be running (checks first)
#
OXIGRAPH_HTTP_LOAD_JOBS ?= 20

.PHONY: oxigraph-http-load
oxigraph-http-load: oxigraph-server-check
	@$(MAKE) -j$(OXIGRAPH_HTTP_LOAD_JOBS) --no-print-directory _oxigraph-http-load-files
	@printf "$(green)HTTP loaded all RDF files$(normal)\n"

#
# Convenience aliases
#
.PHONY: oxigraph-load
oxigraph-load: oxigraph-bulk-load

.PHONY: oxigraph-reload
oxigraph-reload: oxigraph-bulk-load-flags-delete oxigraph-bulk-load

.PHONY: oxigraph-http-reload
oxigraph-http-reload: oxigraph-http-load-flags-delete oxigraph-http-load

oxigraph-graph-names: $(RDF_FILES)
	@for file in $? ; do \
		graph_name="$$(echo $${file} | $(SED_BIN) 's@$(GIT_ROOT)/@file:///@g')" ; \
		echo "$${graph_name}" ; \
	done

endif # USE_OXIGRAPH

#$(info <--- .make/oxigraph-load.mk)

endif # _MK_OXIGRAPH_LOAD_MK_
