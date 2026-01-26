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

# SPARQL endpoints - loaded from dotenvage (.env files) or can be overridden.
# These support any SPARQL 1.1 compliant triplestore (Oxigraph, GraphDB, etc.)
# Set NODE_ENV=production to load production endpoints from .env.production
EKG_SPARQL_HEALTH_ENDPOINT ?= http://localhost:$(OXIGRAPH_PORT)/
EKG_SPARQL_QUERY_ENDPOINT ?= http://localhost:$(OXIGRAPH_PORT)/query
EKG_SPARQL_UPDATE_ENDPOINT ?= http://localhost:$(OXIGRAPH_PORT)/update
# Store endpoint derived from health endpoint (strip trailing slash, add /store)
EKG_SPARQL_STORE_ENDPOINT ?= $(patsubst %/,%,$(EKG_SPARQL_HEALTH_ENDPOINT))/store

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
		$(CURL_BIN) -sf -X PUT -H "Content-Type: text/turtle" \
			--data-binary @$? \
			"$(EKG_SPARQL_STORE_ENDPOINT)?graph=$${graph_name}" \
		|| { printf "$(red)ERROR: Failed to load $${file}. Is the SPARQL server running at $(EKG_SPARQL_HEALTH_ENDPOINT)?$(normal)\n" >&2; exit 1; }
	@touch $@

%.http-loaded.flag: %.nt
	@file="$$(echo $? | $(SED_BIN) 's@$(GIT_ROOT)/@@g')" && printf "HTTP loading RDF File $(green)$${file}$(normal)\n"
	@graph_name="$$(echo $? | $(SED_BIN) 's@$(GIT_ROOT)/@file:///@g')" ; \
		$(CURL_BIN) -sf -X PUT -H "Content-Type: application/n-triples" \
			--data-binary @$? \
			"$(EKG_SPARQL_STORE_ENDPOINT)?graph=$${graph_name}" \
		|| { printf "$(red)ERROR: Failed to load $${file}. Is the SPARQL server running at $(EKG_SPARQL_HEALTH_ENDPOINT)?$(normal)\n" >&2; exit 1; }
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
	@$(CURL_BIN) -sf "$(EKG_SPARQL_HEALTH_ENDPOINT)" >/dev/null 2>&1 \
		|| { printf "$(red)ERROR: SPARQL server is not running at $(EKG_SPARQL_HEALTH_ENDPOINT)$(normal)\n"; \
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
	@$(MAKE) --no-print-directory _oxigraph-http-load-sparql-queries

#
# Load SPARQL query files (.rq) into the knowledge graph
# For each .rq file, finds the corresponding story.ttl and inserts the query
# content as sparql-story:sparql property
#
.PHONY: _oxigraph-http-load-sparql-queries
_oxigraph-http-load-sparql-queries:
	@find $(GIT_ROOT)/use-case -name "*.rq" -type f 2>/dev/null | while read rq_file; do \
		story_dir="$$(dirname "$$rq_file")" ; \
		story_ttl="$$story_dir/story.ttl" ; \
		if [ -f "$$story_ttl" ]; then \
			rq_filename="$$(basename "$$rq_file")" ; \
			rel_story="$$(echo "$$story_ttl" | $(SED_BIN) 's@$(GIT_ROOT)/@@g')" ; \
			graph_name="file:///$$rel_story" ; \
			rel_rq="$$(echo "$$rq_file" | $(SED_BIN) 's@$(GIT_ROOT)/@@g')" ; \
			printf "HTTP loading SPARQL query $(green)$$rel_rq$(normal)\n" ; \
			query_content="$$(cat "$$rq_file" | $(SED_BIN) 's/\\/\\\\/g' | $(SED_BIN) 's/"/\\"/g' | tr '\n' '\r' | $(SED_BIN) 's/\r/\\n/g')" ; \
			sparql_update="PREFIX sparql-story: <https://ekgf.org/ontology/story-impl-sparql#> DELETE { GRAPH <$$graph_name> { ?impl sparql-story:sparql ?oldSparql . } } INSERT { GRAPH <$$graph_name> { ?impl sparql-story:sparql \"\"\"$$query_content\"\"\" . } } WHERE { GRAPH <$$graph_name> { ?impl sparql-story:fileName \"$$rq_filename\" . OPTIONAL { ?impl sparql-story:sparql ?oldSparql . } } }" ; \
			$(CURL_BIN) -sf -X POST -H "Content-Type: application/sparql-update" \
				--data-binary "$$sparql_update" \
				"$(EKG_SPARQL_UPDATE_ENDPOINT)" \
			|| { printf "$(red)ERROR: Failed to load SPARQL query $$rel_rq$(normal)\n" >&2; } ; \
		fi ; \
	done
	@printf "$(green)HTTP loaded all SPARQL query files$(normal)\n"

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
