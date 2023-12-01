#
# Some basic SPARQL tests for the OxiGraph database in this project.
#
ifndef _MK_OXIGRAPH_TEST_MK_
_MK_OXIGRAPH_TEST_MK_ := 1

#$(info ---> .make/oxigraph-test.mk)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
MK_DIR := $(GIT_ROOT)/.make

include $(MK_DIR)/os.mk
include $(MK_DIR)/jq.mk
include $(MK_DIR)/oxigraph.mk
include $(MK_DIR)/oxigraph-load.mk

OXIGRAPH_MINIMUM_NUMBER_OF_SUBJECTS := 125

OXIGRAPH_SPARQL_ASK_ROOT := $(GIT_ROOT)/sparql/test

SPARQL_ASK_TESTS := $(wildcard $(OXIGRAPH_SPARQL_ASK_ROOT)/ask-*.sparql)
SPARQL_ASK_RESULT_FILES := $(SPARQL_ASK_TESTS:.sparql=.tmp.csv)

OXIGRAPH_TEST_REPORT := $(TEST_TMP)/report-tests.csv

ask-%.tmp.csv: ask-%.sparql
	@file="$$(echo $? | sed 's@$(GIT_ROOT)/@@g')" ; printf "Test: $(green)$${file}$(normal)\n"
	@$(OXIGRAPH_BIN) --location $(OXIGRAPH_LOCATION) query --query-file $? --results-file $@

.PHONY: oxigraph-test-clean
oxigraph-test-clean:
	@echo "Cleaning up test flag files"
	-@rm -f $(OXIGRAPH_SPARQL_ASK_ROOT)/*.tmp.csv $(OXIGRAPH_TEST_REPORT) >/dev/null 2>&1

#.INTERMEDIATE: $(OXIGRAPH_SPARQL_ASK_ROOT)/report-tests.tmp.csv
$(OXIGRAPH_TEST_REPORT): $(TEST_TMP) $(SPARQL_ASK_RESULT_FILES)
#	@echo "Generating report: $@"
	@rm -f $@ >/dev/null 2>&1 || true
	@for result_file in $(SPARQL_ASK_RESULT_FILES) ; do \
		result="$$(cat $${result_file})" ; \
		result="$${result/true/$(green)pass}" ; \
		result="$${result/false/$(red)fail}" ; \
		file_name="$$(basename $${result_file})" ; \
		file_name="$${file_name/.tmp.csv/}" ; \
		printf "%10s: $(bold)$${result}$(normal)\n" "$${file_name}" >> $@ ; \
	done

# Determine whether any of the tests failed, if so exit with a non-zero exit code
.PHONY: oxigraph-test-passed
oxigraph-test-passed: $(OXIGRAPH_TEST_REPORT)
	@if grep -q fail $(OXIGRAPH_TEST_REPORT) ; then \
		printf "$(bold)$(red)Some tests failed!!$(normal)\n" ; \
		exit 1 ; \
	else \
		printf "$(bold)$(green)All tests passed!!$(normal)\n" ; \
		true ; \
	fi

.PHONY: oxigraph-report-tests
oxigraph-report-tests: $(OXIGRAPH_TEST_REPORT)
	@echo "Report of all SPARQL ASK statements that perform an ASK:"
	@cat $?

.PHONY: oxigraph-run-ask-tests
oxigraph-run-ask-tests: $(SPARQL_ASK_RESULT_FILES)

oxigraph-run-tests-no-clean: oxigraph-run-ask-tests

.PHONY: _oxigraph-run-tests-no-reload
_oxigraph-run-tests-no-reload: oxigraph-test-clean oxigraph-report-tests

.PHONY: oxigraph-run-tests
oxigraph-run-tests: oxigraph-reload _oxigraph-run-tests-no-reload

#$(info <--- .make/oxigraph-test.mk)

endif # _MK_OXIGRAPH_TEST_MK_
