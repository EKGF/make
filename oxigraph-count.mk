#
# Some basic SPARQL statements generating all sorts of counts or metrics for the OxiGraph database in this project.
#
ifndef _MK_OXIGRAPH_COUNT_MK_
_MK_OXIGRAPH_COUNT_MK_ := 1

#$(info ---> .make/oxigraph-count.mk)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
MK_DIR := $(GIT_ROOT)/.make

include $(MK_DIR)/jq.mk
include $(MK_DIR)/oxigraph.mk
include $(MK_DIR)/oxigraph-load.mk

OXIGRAPH_MINIMUM_NUMBER_OF_SUBJECTS := 125

OXIGRAPH_SPARQL_COUNT_ROOT := $(GIT_ROOT)/sparql/count

SPARQL_COUNT_TESTS := $(wildcard $(OXIGRAPH_SPARQL_COUNT_ROOT)/count-*.sparql)
SPARQL_COUNT_RESULT_FILES := $(SPARQL_COUNT_TESTS:.sparql=.tmp.csv)

OXIGRAPH_COUNTS_REPORT := $(TEST_TMP)/report-counts.csv

count-%.tmp.csv: count-%.sparql
	@file="$$(echo $? | sed 's@$(GIT_ROOT)/@@g')" ; printf "Counting: $(green)$${file}$(normal)\n"
	@$(OXIGRAPH_BIN) --location $(OXIGRAPH_LOCATION) query --query-file $? --results-file $@

.PHONY: oxigraph-count-clean
oxigraph-count-clean:
	@echo "Cleaning up count flag files"
	@rm -f $(OXIGRAPH_SPARQL_COUNT_ROOT)/*.tmp.csv $(OXIGRAPH_COUNTS_REPORT) >/dev/null 2>&1 || true

#.INTERMEDIATE: $(OXIGRAPH_COUNTS_REPORT)
$(OXIGRAPH_COUNTS_REPORT): $(TEST_TMP) $(SPARQL_COUNT_RESULT_FILES)
	#@echo "Generating report: $@"
	@rm -f $@ >/dev/null 2>&1 || true
	@for result_file in $(SPARQL_COUNT_RESULT_FILES) ; do \
		result="$$(cat $${result_file} | tr -d '\015' | xargs)" ; \
		IFS=\  read -r counter count <<< $${result} ; \
		file_name="$$(basename $${result_file})" ; \
		file_name="$${file_name/.tmp.csv/}" ; \
		printf "%10s: $(bold)%-30s$(normal) = $(green)$(bold)%-10d$(normal)\n" "$${file_name:0:10}" "$${counter}" "$${count}" >> $@ ; \
	done

.PHONY: _oxigraph-run-counts-no-report
_oxigraph-run-counts-no-report: oxigraph-count-clean $(OXIGRAPH_COUNTS_REPORT)

.PHONY: oxigraph-report-counts
oxigraph-report-counts: $(OXIGRAPH_COUNTS_REPORT)
	@echo "Report of all SPARQL SELECT statements that perform a COUNT:"
	@cat $?

.PHONY: _oxigraph-run-counts-no-reload
_oxigraph-run-counts-no-reload: oxigraph-count-clean oxigraph-report-counts

.PHONY: oxigraph-run-counts
oxigraph-run-counts: oxigraph-reload _oxigraph-run-counts-no-reload


#$(info <--- .make/oxigraph-count.mk)

endif # _MK_OXIGRAPH_COUNT_MK_
