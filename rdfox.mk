ifndef _MK_RDFOX_MK_
_MK_RDFOX_MK_ := 1

#$(info ---> .make/rdfox.mk)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
ifndef MK_DIR
MK_DIR := $(GIT_ROOT)/.make
endif

include $(MK_DIR)/os.mk
include $(MK_DIR)/curl.mk
include $(MK_DIR)/rdf-files.mk

download_for_azure_linux ?= 0

RDFOX_META_LOCATION ?= $(shell mkdir -p $(RDF_LOCAL_DATABASES_DIR)/rdfox 2>/dev/null ; cd $(RDF_LOCAL_DATABASES_DIR)/rdfox ; pwd )
META_STATIC_DATASETS_LOCATION ?= $(shell mkdir -p $(RDF_STATIC_DATASET_DIR) 2>/dev/null ; cd $(RDF_STATIC_DATASET_DIR) ; pwd )
RDFOX_VERSION_EXPECTED := 7.0a
RDFOX_LOAD_ALL_TO_DEFAULT_GRAPH := 0
RDFOX_DOWNLOAD_HOST := https://rdfox-distribution.s3.eu-west-2.amazonaws.com/release
ifeq ($(UNAME_S),Windows)
RDFOX_OS_NAME := win64
endif
ifeq ($(UNAME_S),Linux)
RDFOX_OS_NAME := linux
endif
ifeq ($(UNAME_S),Darwin)
RDFOX_OS_NAME := macOS
endif
ifeq ($(download_for_azure_linux),1)
#$(info working on the azure version)
RDFOX_OS_NAME := linux
endif

ifeq ($(GIT_ROOT),)
$(error Cannot work without GIT_ROOT)
endif

RDFOX_DOWNLOAD_URL  := $(RDFOX_DOWNLOAD_HOST)/v$(RDFOX_VERSION_EXPECTED)/RDFox-$(RDFOX_OS_NAME)-$(UNAME_M)-$(RDFOX_VERSION_EXPECTED).zip
RDFOX_DOWNLOAD_FILE := $(TMP_DIR)/rdfox/RDFox-$(RDFOX_OS_NAME)-$(UNAME_M)-$(RDFOX_VERSION_EXPECTED).zip
ifeq ($(download_for_azure_linux),1)
RDFOX_DIR := bin
else
RDFOX_DIR := $(RDF_LOCAL_DATABASE_SERVERS_DIR)/rdfox/RDFox-$(RDFOX_OS_NAME)-$(UNAME_M)-$(RDFOX_VERSION_EXPECTED)
endif
RDFOX_BIN := $(RDFOX_DIR)/RDFox$(BIN_SUFFIX)
ifneq ("$(wildcard $(RDFOX_BIN))","")
RDFOX_BIN_EXISTS := 1
else
RDFOX_BIN_EXISTS :=
endif
#$(info RDFOX_BIN_EXISTS=$(RDFOX_BIN_EXISTS))

#RDFOX_LICENSE_FILE = $(RDFOX_DIR)/RDFox.lic
RDFOX_LICENSE_FILE = $(HOME)/.RDFox/RDFox.lic
RDFOX_CMD = unset RDFOX_LICENSE_CONTENT RDFOX_LICENSE_FILE && $(RDFOX_BIN) -license-file $(RDFOX_LICENSE_FILE)
RDFOX_ROLE := admin
RDFOX_PASSWORD := admin
RDFOX_PORT := 12110
RDFOX_META_CMD = $(RDFOX_CMD) -port $(RDFOX_PORT) -server-directory $(RDFOX_META_LOCATION) -channel unsecure -channel-timeout 5s -connection-keep-alive-time 10
RDFOX_META_CMD_AS_ADMIN = $(RDFOX_META_CMD) -role $(RDFOX_ROLE) -password $(RDFOX_PASSWORD) -persistence file \

#$(info RDFOX_DOWNLOAD_URL=$(RDFOX_DOWNLOAD_URL))
#$(info RDFOX_DOWNLOAD_FILE=$(RDFOX_DOWNLOAD_FILE))
#$(info RDFOX_LICENSE_FILE=$(RDFOX_LICENSE_FILE))
ifndef RDFOX_LICENSE_FILE
$(error RDFOX_LICENSE_FILE has no value)
endif

ifeq ($(download_for_azure_linux),0)
ifdef RDFOX_BIN_EXISTS
ifdef RDFOX_BIN
RDFOX_VERSION := $(shell $(RDFOX_CMD) sandbox . serverinfo quit | grep "RDFox Version" | cut -d: -f2 | xargs)
endif
ifeq ($(RDFOX_VERSION),$(RDFOX_VERSION_EXPECTED))
RDFOX_CHECKED := 1
else
RDFOX_CHECKED := 0
endif
else
$(info RDFox has not been installed)
endif
endif

#$(info B RDFOX_BIN=$(RDFOX_BIN))
#$(info RDFOX_META_LOCATION=$(RDFOX_META_LOCATION))
#$(error META_STATIC_DATASETS_LOCATION=$(META_STATIC_DATASETS_LOCATION))
#$(info RDFOX_VERSION=$(RDFOX_VERSION))

.PHONY: rdfox-check
ifeq ($(RDFOX_CHECKED),1)
rdfox-check:
	@echo "Using RDFox $(RDFOX_VERSION)"
else
rdfox-check: rdfox-install
	@RDFOX_VERSION=$$($(RDFOX_CMD) sandbox . serverinfo quit | grep "RDFox Version" | cut -d: -f2 | xargs) ;\
	echo "Using RDFox $(RDFOX_VERSION)"
endif

.PHONY: rdfox-install-info
rdfox-install-info:
	@echo RDFOX_BIN=$(RDFOX_BIN)

.PHONY: rdfox-install
rdfox-install: curl-check sops-check rdfox-install-info $(RDFOX_BIN) $(RDFOX_LICENSE_FILE)

$(RDFOX_DOWNLOAD_FILE):
	@mkdir -p "$(@D)"
	@curl --silent --remote-time --url "$(RDFOX_DOWNLOAD_URL)" --output "$@"

$(RDFOX_BIN): $(RDFOX_DOWNLOAD_FILE)
	@#unzip -oqq $(RDFOX_DOWNLOAD_FILE) -d $(RDF_LOCAL_DATABASE_SERVERS_DIR)/rdfox
	mkdir -p $(@D) || true
	cd $(@D) && $(BSDTAR) --strip-components=1 -xvzf $(RDFOX_DOWNLOAD_FILE)
	@touch $@

$(RDFOX_LICENSE_FILE): $(SOPS_KEYS_FILE)
	@echo "Generating RDFox license file"
	@$(SOPS_BIN) -d --extract '["RDFOX_LICENSE_CONTENT"]' $(SOPS_KEYS_FILE) > $@
	@echo "" >> $@


.INTERMEDIATE: define-lubm-example-prefixes.rdfox
define-lubm-example-prefixes.rdfox:
	@echo "dstore create lubm" >> $@
	@echo "active lubm" >> $@
	@echo "prefixes clear" >> $@
	@echo "prefixes restore-defaults" >> $@
	@echo "base <http://swat.cse.lehigh.edu/onto/univ-bench.owl>" >> $@
	@echo "prefix : <http://swat.cse.lehigh.edu/onto/univ-bench.owl#>" >> $@
	@echo "prefix owl: <http://www.w3.org/2002/07/owl#>" >> $@
	@echo "prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>" >> $@
	@echo "prefix xml: <http://www.w3.org/XML/1998/namespace>" >> $@
	@echo "prefix xsd: <http://www.w3.org/2001/XMLSchema#>" >> $@
	@echo "prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#>" >> $@


.INTERMEDIATE: load-lubm-example.rdfox
load-lubm-example.rdfox:
	@echo "active lubm" >> $@
    # Materialization should only be used inside transactions
	@echo "begin" >> $@
	# For the sample database, data, ontology and rules go to the default graph.
	@for file in $(ALL_RDFOX_EXAMPLE_FILES) ; do echo "import $${file}" ; done >> $@
	@echo "importaxioms" >> $@
	# Full materialization
	@echo "mat" >> $@
	@echo "commit" >> $@
    # Do a full update of statistics after intial load
	@echo "stats update" >> $@


.INTERMEDIATE: define-prefixes.rdfox
define-prefixes.rdfox:
	@echo "dstore create metadata" >> $@
	@echo "active metadata" >> $@
	@echo "prefixes clear" >> $@
	@echo "prefixes restore-defaults" >> $@
	@echo "base <https://placeholder.kg/id/>" >> $@
	@echo "prefix auth:                 <https://ekgf.org/ontology/authorization/>" >> $@
	@echo "prefix concept:              <https://ekgf.org/ontology/concept/>" >> $@
	@echo "prefix cs: 					<http://purl.org/vocab/changeset/schema#>" >> $@
	@echo "prefix data-mig:             <https://ekgf.org/ontology/data-migration/>" >> $@
	@echo "prefix dataset:              <https://ekgf.org/ontology/dataset/>" >> $@
	@echo "prefix dc:                   <http://purl.org/dc/elements/1.1/>" >> $@
	@echo "prefix dcat:                 <http://www.w3.org/ns/dcat#>" >> $@
	@echo "prefix dct:                  <http://purl.org/dc/terms/>" >> $@
	@echo "prefix dctype:               <http://purl.org/dc/dcmitype/>" >> $@
	@echo "prefix document:             <https://ekgf.org/ontology/document/>" >> $@
	@echo "prefix employment:           <https://ekgf.org/ontology/employment/>" >> $@
	@echo "prefix id:    				<https://placeholder.kg/id/>" >> $@
	@echo "prefix ent:                  <http://www.w3.org/ns/entailment/>" >> $@
	@echo "prefix enum:                 <https://ekgf.org/ontology/enum/>" >> $@
	@echo "prefix event:                <https://ekgf.org/ontology/event/>" >> $@
	@echo "prefix fibo-fnd-acc-cur:     <https://spec.edmcouncil.org/fibo/ontology/FND/Accounting/CurrencyAmount/>" >> $@
	@echo "prefix fibo-fnd-plc-loc:     <https://spec.edmcouncil.org/fibo/ontology/FND/Places/Locations/>" >> $@
	@echo "prefix fibo-fbc-fct-bci:  	<https://spec.edmcouncil.org/fibo/ontology/FBC/FunctionalEntities/BusinessCentersIndividuals/>" >> $@
	@echo "prefix fibo-fnd-acc-4217: 	<https://spec.edmcouncil.org/fibo/ontology/FND/Accounting/ISO4217-CurrencyCodes/>" >> $@
	@echo "prefix fibo-fnd-utl-av: 		<https://spec.edmcouncil.org/fibo/ontology/FND/Utilities/AnnotationVocabulary/>" >> $@
	@echo "prefix file:                 <https://ekgf.org/ontology/file/>" >> $@
	@echo "prefix fin-reg:              <https://ekgf.org/ontology/financial-regulation/>" >> $@
	@echo "prefix foaf:                 <http://xmlns.com/foaf/0.1/>" >> $@
	@echo "prefix gleif-base:           <https://www.gleif.org/ontology/Base/>" >> $@
	@echo "prefix gleif-elf:            <https://www.gleif.org/ontology/EntityLegalForm/>" >> $@
	@echo "prefix gleif-RA-data:     	<https://rdf.gleif.org/RegistrationAuthority/>" >> $@
	@echo "prefix hist:      			<https://ekgf.org/ontology/history/>" >> $@
	@echo "prefix ident:                <https://ekgf.org/ontology/identifier/>" >> $@
	@echo "prefix jira: 				<https://ekgf.org/ontology/jira/>" >> $@
	@echo "prefix kggraph:              <https://placeholder.kg/graph/>" >> $@
	@echo "prefix lcc-3166-1:           <https://www.omg.org/spec/LCC/Countries/ISO3166-1-CountryCodes/>" >> $@
	@echo "prefix lcc-3166-1:       	<https://www.omg.org/spec/LCC/Countries/ISO3166-1-CountryCodes/>" >> $@
	@echo "prefix lcc-3166-2-us:    	<https://www.omg.org/spec/LCC/Countries/Regions/ISO3166-2-SubdivisionCodes-US/>" >> $@
	@echo "prefix lcc-3166-2-ae:    	<https://www.omg.org/spec/LCC/Countries/Regions/ISO3166-2-SubdivisionCodes-AE/>" >> $@
	@echo "prefix lcc-3166-2-es:    	<https://www.omg.org/spec/LCC/Countries/Regions/ISO3166-2-SubdivisionCodes-ES/>" >> $@
	@echo "prefix lcc-cr:               <https://www.omg.org/spec/LCC/Countries/CountryRepresentation/>" >> $@
	@echo "prefix lcc-lr: 				<https://www.omg.org/spec/LCC/Languages/LanguageRepresentation/>" >> $@
	@echo "prefix legal-entity:         <https://ekgf.org/ontology/legal-entity/>" >> $@
	@echo "prefix lem-example:          <https://placeholder.kg/ontology/legal-entity-management-example/>" >> $@
	@echo "prefix lem-wf:   		    <https://placeholder.kg/ontology/workflow/lem/>" >> $@
	@echo "prefix locn:                 <http://www.w3.org/ns/locn#>" >> $@
	@echo "prefix odrl:                 <http://www.w3.org/ns/odrl/2/>" >> $@
	@echo "prefix organization:         <https://ekgf.org/ontology/organization/>" >> $@
	@echo "prefix owl:                  <http://www.w3.org/2002/07/owl#>" >> $@
	@echo "prefix persona:  			<https://ekgf.org/ontology/persona/>" >> $@
	@echo "prefix prof:                 <http://www.w3.org/ns/owl-profile/>" >> $@
	@echo "prefix prov:                 <http://www.w3.org/ns/prov#>" >> $@
	@echo "prefix raw:                  <https://ekgf.org/ontology/raw/>" >> $@
	@echo "prefix rdf:                  <http://www.w3.org/1999/02/22-rdf-syntax-ns#>" >> $@
	@echo "prefix rdfs:                 <http://www.w3.org/2000/01/rdf-schema#>" >> $@
	@echo "prefix sbe:                  <https://ekgf.org/ontology/specification-by-example/>" >> $@
	@echo "prefix sd:                   <http://www.w3.org/ns/sparql-service-description#>" >> $@
	@echo "prefix sdlc:         		<https://ekgf.org/ontology/software-development-life-cycle/>" >> $@
	@echo "prefix sdo: 					<http://schema.org/>" >> $@
	@echo "prefix skos:                 <http://www.w3.org/2004/02/skos/core#>" >> $@
	@echo "prefix sm: 					<http://www.omg.org/techprocess/ab/SpecificationMetadata/>" >> $@
	@echo "prefix spdx:                 <http://spdx.org/rdf/terms#>" >> $@
	@echo "prefix story:            	<https://ekgf.org/ontology/story/>" >> $@
	@echo "prefix story:                <https://ekgf.org/ontology/story/>" >> $@
	@echo "prefix temporality:          <https://ekgf.org/ontology/temporality/>" >> $@
	@echo "prefix time:                 <http://www.w3.org/2006/time#>" >> $@
	@echo "prefix use-case:             <https://ekgf.org/ontology/use-case/>" >> $@
	@echo "prefix user-account:         <https://ekgf.org/ontology/user-account/>" >> $@
	@echo "prefix vcard:                <http://www.w3.org/2006/vcard/ns#>" >> $@
	@echo "prefix void:                 <http://rdfs.org/ns/void#>" >> $@
	@echo "prefix vs:   				<http://www.w3.org/2003/06/sw-vocab-status/ns#>" >> $@
	@echo "prefix wfi:                  <https://ekgf.org/ontology/workflow-instance/>" >> $@
	@echo "prefix wot:  				<http://xmlns.com/wot/0.1/>" >> $@
	@echo "prefix xsd:                  <http://www.w3.org/2001/XMLSchema#>" >> $@


.INTERMEDIATE: load-all-static-datasets.rdfox
ifeq ($(RDFOX_LOAD_ALL_TO_DEFAULT_GRAPH),1)
load-all-static-datasets.rdfox:
	@echo "active metadata" >> $@
	@echo "begin" >> $@
	@for ttl in $(OMG_STATIC_DATASET_TTL_FILES) ; do echo "import $${ttl}" ; done >> $@
	@for ttl in $(EDMCOUNCIL_STATIC_DATASET_TTL_FILES) ; do echo "import $${ttl}" ; done >> $@
	@for ttl in $(GLEIF_STATIC_DATASET_TTL_FILES) ; do echo "import $${ttl}" ; done >> $@
	@echo "commit" >> $@
else
load-all-static-datasets.rdfox:
	@echo "active metadata" >> $@
	@echo "begin" >> $@
	@for ttl in $(OMG_STATIC_DATASET_TTL_FILES) ; do echo "import > kggraph:omg $${ttl}" ; done >> $@
	@for ttl in $(EDMCOUNCIL_STATIC_DATASET_TTL_FILES) ; do echo "import > kggraph:edmcouncil $${ttl}" ; done >> $@
	@for ttl in $(GLEIF_STATIC_DATASET_TTL_FILES) ; do echo "import > kggraph:gleif $${ttl}" ; done >> $@
	@echo "importaxioms kggraph:ontologies > kggraph:omg">> $@
	@echo "importaxioms kggraph:ontologies > kggraph:edmcouncil">> $@
	@echo "importaxioms kggraph:ontologies > kggraph:gleif">> $@
	@echo "mat" >> $@
	@echo "stats update" >> $@
	@echo "commit" >> $@
endif

.INTERMEDIATE: load-all-test-datasets.rdfox
ifeq ($(RDFOX_LOAD_ALL_TO_DEFAULT_GRAPH),1)
load-all-test-datasets.rdfox:
	@echo "active metadata" >> $@
	@for ttl in $(ALL_TEST_DATASETS_TTL_FILES) ; do echo "import $${ttl}" ; done >> $@
else
load-all-test-datasets.rdfox:
	@echo "active metadata" >> $@
	# test-datesets (omg, edmcouncil, and gleif) all go to one single named graph called test-datasets
	@for ttl in $(ALL_TEST_DATASETS_TTL_FILES) ; do echo "import > kggraph:test-datasets $${ttl}" ; done >> $@
	@echo "importaxioms kggraph:ontologies > kggraph:test-datasets">> $@
	@echo "mat" >> $@
	@echo "stats update" >> $@
endif

.INTERMEDIATE: load-all-metadata.rdfox
ifeq ($(RDFOX_LOAD_ALL_TO_DEFAULT_GRAPH),1)
load-all-metadata.rdfox:
	# To maximise performance, execute the commands in the following order: import ontologies, import data, importaxioms, stats update, mat, and finally commit the transaction.
	@echo "active metadata" >> $@
    # Materialization should only be used inside transactions
	@echo "begin" >> $@
	@for ttl in $(ALL_ONTOLOGY_TTL_FILES) ; do echo "import $${ttl}" ; done >> $@
	@for ttl in $(ALL_METADATA_TTL_FILES) ; do echo "import $${ttl}" ; done >> $@
	@echo "importaxioms">> $@
	# Full materialization
	@echo "mat" >> $@
    # Do a full update of statistics after initial load
	@echo "stats update" >> $@
	# Include data import, mat and stats update in the same transaction
	@echo "commit" >> $@
else
load-all-metadata.rdfox:
	@echo "load-all-metadata"
	@echo $(ALL_ONTOLOGY_TTL_FILES)
	# To maximise performance, execute the commands in the following order: import ontologies, import data, importaxioms, stats update, mat, and finally commit the transaction.
	@echo "active metadata" >> $@
    # Materialization should only be used inside transactions
	@echo "begin" >> $@
	@for ttl in $(ALL_ONTOLOGY_TTL_FILES) ; do echo "import > kggraph:ontologies $${ttl}" ; done >> $@
	@for ttl in $(ALL_METADATA_TTL_FILES) ; do echo "import > kggraph:metadata $${ttl}" ; done >> $@
	# Ontology only applies to the graph where they are imported to, in this case to the metadata graph, where the data lives.
	@echo "importaxioms kggraph:ontologies > kggraph:metadata">> $@
	# Full materialization
	@echo "mat" >> $@
    # Do a full update of statistics after initial load
	@echo "stats update" >> $@
	# Include data import, mat and stats update in the same transaction
	@echo "commit" >> $@
endif

.INTERMEDIATE: ttl-export.rdfox
ifeq ($(RDFOX_LOAD_ALL_TO_DEFAULT_GRAPH),1)
ttl-export.rdfox:
	@echo "active metadata" >> $@
	@echo "export $(RESOURCE_DIRECTORY)/export/metadata-all-facts.ttl text/turtle fact-domain all" >> $@
	@echo "export $(RESOURCE_DIRECTORY)/export/metadata-explicit-facts.ttl text/turtle fact-domain explicit" >> $@
	@echo "export $(RESOURCE_DIRECTORY)/export/metadata-derived-facts.ttl text/turtle fact-domain derived " >> $@
	@echo "export $(RESOURCE_DIRECTORY)/export/owl2-axioms.fss text/owl-functional" >> $@
	@echo "export $(RESOURCE_DIRECTORY)/export/rules.dlog application/x.datalog" >> $@
else
ttl-export.rdfox:
	@echo "active metadata" >> $@

	@echo "set query.fact-domain all" >> $@
	@echo "set output $(RESOURCE_DIRECTORY)/export/metadata-all-facts.ttl" >> $@
	@echo "CONSTRUCT {?s ?p ?o} FROM <https://placeholder.kg/graph/metadata> WHERE {?s ?p ?o}" >> $@

	@echo "set query.fact-domain explicit" >> $@
	@echo "set output $(RESOURCE_DIRECTORY)/export/metadata-explicit-facts.ttl" >> $@
	@echo "CONSTRUCT {?s ?p ?o} FROM <https://placeholder.kg/graph/metadata> WHERE {?s ?p ?o}" >> $@

	@echo "set query.fact-domain derived" >> $@
	@echo "set output $(RESOURCE_DIRECTORY)/export/metadata-derived-facts.ttl" >> $@
	@echo "CONSTRUCT {?s ?p ?o} FROM <https://placeholder.kg/graph/metadata> WHERE {?s ?p ?o}" >> $@

	# test-datesets (omg, edmcouncil, and gleif) all go to one single named graph called test-datasets
	@echo "set query.fact-domain all" >> $@
	@echo "set output $(RESOURCE_DIRECTORY)/export/test-datasets-all-facts.ttl" >> $@
	@echo "CONSTRUCT {?s ?p ?o} FROM <https://placeholder.kg/graph/test-datasets> WHERE {?s ?p ?o}" >> $@

	@echo "set query.fact-domain explicit" >> $@
	@echo "set output $(RESOURCE_DIRECTORY)/export/test-datasets-explicit-facts.ttl" >> $@
	@echo "CONSTRUCT {?s ?p ?o} FROM <https://placeholder.kg/graph/test-datasets> WHERE {?s ?p ?o}" >> $@

	@echo "set query.fact-domain derived" >> $@
	@echo "set output $(RESOURCE_DIRECTORY)/export/test-datasets-derived-facts.ttl" >> $@
	@echo "CONSTRUCT {?s ?p ?o} FROM <https://placeholder.kg/graph/test-datasets> WHERE {?s ?p ?o}" >> $@

	@echo "set query.fact-domain all" >> $@
	@echo "set output $(RESOURCE_DIRECTORY)/export/omg-all-facts.ttl" >> $@
	@echo "CONSTRUCT {?s ?p ?o} FROM <https://placeholder.kg/graph/omg> WHERE {?s ?p ?o}" >> $@

	@echo "set query.fact-domain explicit" >> $@
	@echo "set output $(RESOURCE_DIRECTORY)/export/omg-explicit-facts.ttl" >> $@
	@echo "CONSTRUCT {?s ?p ?o} FROM <https://placeholder.kg/graph/omg> WHERE {?s ?p ?o}" >> $@

	@echo "set query.fact-domain derived" >> $@
	@echo "set output $(RESOURCE_DIRECTORY)/export/omg-derived-facts.ttl" >> $@
	@echo "CONSTRUCT {?s ?p ?o} FROM <https://placeholder.kg/graph/omg> WHERE {?s ?p ?o}" >> $@

	@echo "set query.fact-domain all" >> $@
	@echo "set output $(RESOURCE_DIRECTORY)/export/edmcouncil-all-facts.ttl" >> $@
	@echo "CONSTRUCT {?s ?p ?o} FROM <https://placeholder.kg/graph/edmcouncil> WHERE {?s ?p ?o}" >> $@

	@echo "set query.fact-domain explicit" >> $@
	@echo "set output $(RESOURCE_DIRECTORY)/export/edmcouncil-explicit-facts.ttl" >> $@
	@echo "CONSTRUCT {?s ?p ?o} FROM <https://placeholder.kg/graph/edmcouncil> WHERE {?s ?p ?o}" >> $@

	@echo "set query.fact-domain derived" >> $@
	@echo "set output $(RESOURCE_DIRECTORY)/export/edmcouncil-derived-facts.ttl" >> $@
	@echo "CONSTRUCT {?s ?p ?o} FROM <https://placeholder.kg/graph/edmcouncil> WHERE {?s ?p ?o}" >> $@


	@echo "set query.fact-domain all" >> $@
	@echo "set output $(RESOURCE_DIRECTORY)/export/gleif-all-facts.ttl" >> $@
	@echo "CONSTRUCT {?s ?p ?o} FROM <https://placeholder.kg/graph/gleif> WHERE {?s ?p ?o}" >> $@

	@echo "set query.fact-domain explicit" >> $@
	@echo "set output $(RESOURCE_DIRECTORY)/export/gleif-explicit-facts.ttl" >> $@
	@echo "CONSTRUCT {?s ?p ?o} FROM <https://placeholder.kg/graph/gleif> WHERE {?s ?p ?o}" >> $@

	@echo "set query.fact-domain derived" >> $@
	@echo "set output $(RESOURCE_DIRECTORY)/export/gleif-derived-facts.ttl" >> $@
	@echo "CONSTRUCT {?s ?p ?o} FROM <https://placeholder.kg/graph/gleif> WHERE {?s ?p ?o}" >> $@

	@echo "set query.fact-domain all" >> $@
	@echo "set output $(RESOURCE_DIRECTORY)/export/ontologies.ttl" >> $@
	@echo "CONSTRUCT {?s ?p ?o} FROM <https://placeholder.kg/graph/ontologies> WHERE {?s ?p ?o}" >> $@

	@echo "export $(RESOURCE_DIRECTORY)/export/rules.dlog application/x.datalog" >> $@
endif

.INTERMEDIATE: create-admin-role.rdfox
create-admin-role.rdfox:
	echo "endpoint start" > $@
	echo "endpoint start" > $@

.INTERMEDIATE: endpoint-start.rdfox
endpoint-start.rdfox:
	echo "endpoint start" > $@

.PHONY: rdfox-clean
rdfox-clean:
	rm -rf $(RDFOX_META_LOCATION)/*
	find $(RESOURCE_DIRECTORY)/export -type f -not -name '*.md' -delete

.PHONY: rdfox-create-admin-role
rdfox-create-admin-role: rdfox-check create-admin-role.rdfox
	unset RDFOX_ROLE && unset RDFOX_PASSWORD && $(RDFOX_META_CMD) -temp-role shell . create-admin-role

.PHONY: rdfox-meta-sandbox-load-and-export
rdfox-meta-sandbox-load-and-export: rdfox-check define-prefixes.rdfox load-all-static-datasets.rdfox load-all-test-datasets.rdfox load-all-metadata.rdfox ttl-export.rdfox
	$(RDFOX_META_CMD) sandbox .  define-prefixes load-all-static-datasets load-all-test-datasets load-all-metadata ttl-export quit

.PHONY: rdfox-lubm-load
rdfox-lubm-load: rdfox-check define-lubm-example-prefixes.rdfox load-lubm-example.rdfox
	$(RDFOX_META_CMD_AS_ADMIN) shell . define-lubm-example-prefixes load-lubm-example quit

.PHONY: rdfox-meta-load
rdfox-meta-load: rdfox-check define-prefixes.rdfox load-all-static-datasets.rdfox load-all-test-datasets.rdfox load-all-metadata.rdfox
	$(RDFOX_META_CMD_AS_ADMIN) shell . define-prefixes load-all-static-datasets load-all-test-datasets load-all-metadata quit

.PHONY: rdfox-meta-start-fg
rdfox-meta-start-fg: rdfox-check define-prefixes.rdfox endpoint-start.rdfox
	$(RDFOX_META_CMD_AS_ADMIN) shell . define-prefixes

.PHONY: rdfox-serve
rdfox-serve: rdfox-check endpoint-start.rdfox
	@echo "Serving database in directory $(RDFOX_META_LOCATION)"
	$(RDFOX_META_CMD_AS_ADMIN) daemon

.PHONY: rdfox-init
rdfox-init: rdfox-lubm-load rdfox-meta-load rdfox-serve

.PHONY: rdfox-meta-shell
rdfox-meta-shell:
	$(RDFOX_BIN) -role $(RDFOX_ROLE) -password $(RDFOX_PASSWORD) remote http://localhost:$(RDFOX_PORT)

.PHONY: rdfox-meta-dstore-list
rdfox-meta-dstore-list: rdfox-check define-prefixes.rdfox endpoint-start.rdfox
	$(RDFOX_META_CMD_AS_ADMIN) shell . 'dstore list' quit
	
#$(info <--- .make/rdfox.mk)

endif # _MK_RDFOX_MK_
