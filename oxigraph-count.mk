#
# Some basic SPARQL statements generating all sorts of counts or metrics for the OxiGraph database in this project.
#
ifndef _MK_OXIGRAPH_COUNT_MK_
_MK_OXIGRAPH_COUNT_MK_ := 1

#$(info ---> .make/oxigraph-count.mk)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
ifndef MK_DIR
MK_DIR := $(GIT_ROOT)/.make
endif

include $(MK_DIR)/jq.mk
include $(MK_DIR)/oxigraph.mk
include $(MK_DIR)/oxigraph-load.mk

OXIGRAPH_MINIMUM_NUMBER_OF_SUBJECTS := 125

OXIGRAPH_SPARQL_COUNT_ROOT := $(GIT_ROOT)/sparql/count

SPARQL_COUNT_TESTS := $(wildcard $(OXIGRAPH_SPARQL_COUNT_ROOT)/count-*.rq)
SPARQL_COUNT_RESULT_FILES1 := $(SPARQL_COUNT_TESTS:.rq=-before-transformation.tmp.csv)
SPARQL_COUNT_RESULT_FILES2 := $(SPARQL_COUNT_TESTS:.rq=-after-transformation.tmp.csv)

OXIGRAPH_COUNTS_REPORT1 := $(TEST_TMP)/report-counts-before-transformation.csv
OXIGRAPH_COUNTS_REPORT2 := $(TEST_TMP)/report-counts-after-transformation.csv

count%-before-transformation.tmp.csv: count%.rq
	@file="$$(echo $? | sed 's@$(GIT_ROOT)/@@g')" ; printf "Counting: $(green)$${file}$(normal)\n"
	@ulimit -n 10240 && $(OXIGRAPH_BIN) query --location $(OXIGRAPH_LOCATION) --query-file $? --results-file $@

count%-after-transformation.tmp.csv: count%.rq
	@file="$$(echo $? | sed 's@$(GIT_ROOT)/@@g')" ; printf "Counting: $(green)$${file}$(normal)\n"
	@ulimit -n 10240 && $(OXIGRAPH_BIN) query --location $(OXIGRAPH_LOCATION) --query-file $? --results-file $@

.PHONY: oxigraph-count-clean
oxigraph-count-clean: _oxigraph-count1-clean _oxigraph-count2-clean
	@rm -f $(OXIGRAPH_SPARQL_COUNT_ROOT)/*.tmp.csv

.PHONY: _oxigraph-count1-clean
_oxigraph-count1-clean:
#	@echo "Cleaning up count1 flag files"
	@rm -f $(OXIGRAPH_COUNTS_REPORT1) $(SPARQL_COUNT_RESULT_FILES1) >/dev/null 2>&1 || true

.PHONY: _oxigraph-count2-clean
_oxigraph-count2-clean:
#	@echo "Cleaning up count2 flag files"
	@rm -f $(OXIGRAPH_COUNTS_REPORT2) $(SPARQL_COUNT_RESULT_FILES2) >/dev/null 2>&1 || true

#.INTERMEDIATE: $(OXIGRAPH_COUNTS_REPORT1)
$(OXIGRAPH_COUNTS_REPORT1): $(TEST_TMP) $(SPARQL_COUNT_RESULT_FILES1)
	@#echo "Generating report: $@"
	@rm -f $@ >/dev/null 2>&1 || true
	@for result_file in $(SPARQL_COUNT_RESULT_FILES1) ; do \
		result="$$(cat $${result_file} | tr -d '\015' | xargs)" ; \
		IFS=\  read -r counter count <<< $${result} ; \
		file_name="$$(basename $${result_file})" ; \
		file_name="$${file_name/-before-transformation.tmp.csv/}" ; \
		printf "%10s: $(bold)%-30s$(normal) = $(green)$(bold)%-10d$(normal)\n" "$${file_name:0:10}" "$${counter}" "$${count}" >> $@ ; \
	done

#.INTERMEDIATE: $(OXIGRAPH_COUNTS_REPORT2)
$(OXIGRAPH_COUNTS_REPORT2): $(TEST_TMP) $(SPARQL_COUNT_RESULT_FILES2)
	@#echo "Generating report: $@"
	@rm -f $@ >/dev/null 2>&1 || true
	@for result_file in $(SPARQL_COUNT_RESULT_FILES2) ; do \
		result="$$(cat $${result_file} | tr -d '\015' | xargs)" ; \
		IFS=\  read -r counter count <<< $${result} ; \
		file_name="$$(basename $${result_file})" ; \
		file_name="$${file_name/-after-transformation.tmp.csv/}" ; \
		printf "%10s: $(bold)%-30s$(normal) = $(green)$(bold)%-10d$(normal)\n" "$${file_name:0:10}" "$${counter}" "$${count}" >> $@ ; \
	done

.PHONY: _oxigraph-run-counts-no-report1
_oxigraph-run-counts-no-report1: _oxigraph-count1-clean $(OXIGRAPH_COUNTS_REPORT1)

.PHONY: _oxigraph-run-counts-no-report2
_oxigraph-run-counts-no-report2: _oxigraph-count2-clean $(OXIGRAPH_COUNTS_REPORT2)

.PHONY: oxigraph-report-counts1
oxigraph-report-counts1: $(OXIGRAPH_COUNTS_REPORT1)
	@echo "Report of all SPARQL SELECT statements that perform a COUNT before transformation:"
	@cat $?

.PHONY: oxigraph-report-counts2
oxigraph-report-counts2: $(OXIGRAPH_COUNTS_REPORT2)
	@echo "Report of all SPARQL SELECT statements that perform a COUNT after transformation:"
	@cat $?

.PHONY: _oxigraph-run-counts1-no-reload
_oxigraph-run-counts1-no-reload: _oxigraph-count1-clean oxigraph-report-counts1

.PHONY: _oxigraph-run-counts2-no-reload
_oxigraph-run-counts2-no-reload: _oxigraph-count2-clean oxigraph-report-counts2

.PHONY: oxigraph-run-counts1
oxigraph-run-counts1: oxigraph-reload _oxigraph-run-counts1-no-reload

.PHONY: oxigraph-run-counts2
oxigraph-run-counts2: oxigraph-reload _oxigraph-run-counts2-no-reload

.PHONY: oxigraph-count-before-transform
oxigraph-count-before-transform: _oxigraph-run-counts1-no-reload
	printf "$(bold)$(green)Ran the counts before transformation$(normal)\n"

.PHONY: oxigraph-count-after-transform
oxigraph-count-after-transform: _oxigraph-run-counts2-no-reload
	printf "$(bold)$(green)Ran the counts after transformation$(normal)\n"

#$(info <--- .make/oxigraph-count.mk)

endif # _MK_OXIGRAPH_COUNT_MK_
