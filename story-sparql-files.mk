#
# Some basic SPARQL file handling routines, primarily to discover the SPARQL files related
# to "stories" in this repo.
#
ifndef _MK_STORY_SPARQL_FILES_MK_
_MK_STORY_SPARQL_FILES_MK_ := 1

#$(info ---> .make/story-sparql-files.mk)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
ifndef MK_DIR
MK_DIR := $(GIT_ROOT)/.make
endif

include $(MK_DIR)/os.mk

ifndef STORY_SPARQL_USE_CASE_DIR
STORY_SPARQL_USE_CASE_DIR := $(GIT_ROOT)/use-case
endif

STORY_SPARQL_FILES := $(shell find -L $(STORY_SPARQL_USE_CASE_DIR) -mindepth 1 -a -name '*.sparql' -a \! -path "./.git*" -print 2>/dev/null | sort)
STORY_SPARQL_TTL_FILES := $(STORY_SPARQL_FILES:=.ttl)

.INTERMEDIATE: $(STORY_SPARQL_TTL_FILES)
$(STORY_SPARQL_TTL_FILES): %.ttl: %
	@#echo "Converting $< to $@"
	@basename=$$(basename $<) && \
	dirname=$$(dirname $<) && \
	story_file=$${dirname}/story.ttl && \
	if [ ! -f $${story_file} ]; then \
		echo "ERROR: story.ttl file not found for $<" ; \
		exit 1 ; \
	fi && \
	story_refers_to2_sparql_file=$$(grep -q "$${basename}" "$${story_file}" && echo 1 || echo 0) && \
	if [ $$? -ne 0 ]; then \
		echo "ERROR: $${story_file} does not refer to $${basename}" ; \
		exit 0 ; \
	fi && \
	#echo "Found $${story_file} refers to $${basename}" && \
	sparql_relative_file=$$(echo $< | sed 's@$(GIT_ROOT)/@@g') && \
	impl_uuid=$$(uuidgen --namespace @url --sha1 --name "$${sparql_relative_file}") && \
	story_key=$$(basename "$${dirname}") && \
	#echo "Story key is $${story_key}" && \
	use_case_key=$$(cd $${dirname}/../.. ; basename "$$(pwd)") && \
	#echo "Use case key is $${use_case_key}" && \
	first_line=$$($(GREP_BIN) -E -v '^[[:space:]]*#|^BASE|^PREFIX|^$$' $< | head -n 1) && \
	first_word=$$(echo -n $${first_line^^} | awk '{print $$1}') && \
#	echo "First word is $${first_word}" && \
	echo "# This file is generated, do not save in git!" > $@ && \
	echo "@prefix rdf:          <http://www.w3.org/1999/02/22-rdf-syntax-ns#> ." > $@ && \
	echo "@prefix rdfs:         <http://www.w3.org/2000/01/rdf-schema#> ." >> $@ && \
	echo "@prefix story:        <https://ekgf.org/ontology/story#> ." >> $@ && \
	echo "@prefix sparql-story: <https://ekgf.org/ontology/story-impl-sparql#> ." >> $@ && \
	echo "" >> $@ && \
	echo "# use-case-$${use_case_key}-story-$${story_key}-sparql-impl" >> $@ && \
	echo "<urn:uuid:$${impl_uuid}>" >> $@ && \
	echo "  a sparql-story:StoryImplementation ;" >> $@ && \
	echo "  a sparql-story:StorySPARQLImplementation ;" >> $@ && \
	echo "  a sparql-story:$${first_word} ;" >> $@ && \
	echo "  sparql-story:flavor sparql-story:SPARQL11 ;" >> $@ && \
	echo "  sparql-story:fileName \"$${sparql_relative_file}\" ;" >> $@ && \
	echo "  rdfs:label \"SPARQL Implementation for Story $${story_key} of Use Case $${use_case_key}\" ;" >> $@ && \
	echo "  story:implements <use-case-$${use_case_key}-story-$${story_key}> ;" >> $@ && \
	echo "  sparql-story:sparql \"\"\"" >> $@ && \
	cat $< >> $@ && \
	echo "\"\"\" ." >> $@ && \
	echo "" >> $@ && \
	echo "<use-case-$${use_case_key}-story-$${story_key}>" >> $@ && \
	echo "  a story:Story ;" >> $@ && \
	echo "  story:implementedBy <urn:uuid:$${impl_uuid}> ." >> $@

.PHONY: generate-story-sparql-ttl-files
generate-story-sparql-ttl-files: $(STORY_SPARQL_TTL_FILES)

.PHONY: delete-story-sparql-ttl-files
delete-story-sparql-ttl-files: $(STORY_SPARQL_TTL_FILES)
	@rm -f $?

$(TEST_TMP)/story-sparql-files-to-load.txt: $(STORY_SPARQL_FILES)
	@echo $? | tr ' ' '\n' | sort > $@
	@printf "Found %s Story SPARQL files\n" $$(cat $@ | wc -l)

# List the RDF files in this repo
.PHONY: story-sparql-files-to-load
story-sparql-files-to-load: $(TEST_TMP)/story-sparql-files-to-load.txt
	@cat -n $? | sed 's@$(GIT_ROOT)/@@g'

#$(info <--- .make/story-sparql-files.mk)

endif # _MK_STORY_SPARQL_FILES_MK_
