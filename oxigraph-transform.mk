#
# Some basic SPARQL statements generating all sorts of transforms or metrics for the OxiGraph database in this project.
#
ifndef _MK_OXIGRAPH_TRANSFORM_MK_
_MK_OXIGRAPH_TRANSFORM_MK_ := 1

#$(info ---> .make/oxigraph-transform.mk)

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

OXIGRAPH_SPARQL_TRANSFORM_ROOT := $(GIT_ROOT)/sparql/transform

SPARQL_TRANSFORM_TESTS := $(wildcard $(OXIGRAPH_SPARQL_TRANSFORM_ROOT)/transform-*.rq)
SPARQL_TRANSFORM_RESULT_FILES := $(SPARQL_TRANSFORM_TESTS:.rq=.tmp.csv)

OXIGRAPH_TRANSFORM_REPORT := $(TEST_TMP)/report-transforms.tmp.csv

transform-%.tmp.csv: transform-%.rq
	@rm -f $@ >/dev/null 2>&1 || true
	@file="$$(echo $? | sed 's@$(GIT_ROOT)/@@g')" ; printf "Transforming: $(green)$${file}$(normal)\n"
	@ulimit -n 10240 && $(OXIGRAPH_BIN) update --location $(OXIGRAPH_LOCATION) --update-file $?
	@touch $@

.PHONY: oxigraph-transform-clean
oxigraph-transform-clean:
	@echo "Cleaning up transform flag files"
	-@rm -f $(OXIGRAPH_SPARQL_TRANSFORM_ROOT)/*.tmp.csv >/dev/null 2>&1

.PHONY: _oxigraph-run-transforms-no-report
_oxigraph-run-transforms-no-report: oxigraph-transform-clean $(SPARQL_TRANSFORM_RESULT_FILES)

#.INTERMEDIATE: $(OXIGRAPH_SPARQL_TRANSFORM_ROOT)/report-transforms.tmp.csv
$(OXIGRAPH_TRANSFORM_REPORT): $(TEST_TMP) $(SPARQL_TRANSFORM_RESULT_FILES)
	#@echo "Generating report: $@"
	@rm -f $@ >/dev/null 2>&1 || true
	@for result_file in $(SPARQL_TRANSFORM_RESULT_FILES) ; do \
		file_name="$$(basename $${result_file})" ; \
		file_name="$${file_name/.tmp.csv/}" ; \
		if [[ -f "$${result_file}" ]] ; then \
			printf "$(bold)%-50s$(normal) = $(green)$(bold)done$(normal)\n" "$${file_name}"  >> $@ ; \
		else \
			printf "$(bold)%-50s$(normal) = $(red)$(bold)fail$(normal)\n" "$${file_name}" >> $@ ; \
		fi ; \
	done

.PHONY: oxigraph-report-transforms
oxigraph-report-transforms: $(OXIGRAPH_TRANSFORM_REPORT)
	@echo "Report of all SPARQL SELECT statements that perform a transformation:"
	@cat $?

.PHONY: _oxigraph-run-transforms-no-reload
_oxigraph-run-transforms-no-reload: oxigraph-transform-clean oxigraph-report-transforms

.PHONY: oxigraph-run-transforms
oxigraph-run-transforms: oxigraph-reload _oxigraph-run-transforms-no-reload


#$(info <--- .make/oxigraph-transform.mk)

endif # _MK_OXIGRAPH_TRANSFORM_MK_
