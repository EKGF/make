ifndef _MK_NODEJS_ENV_MK_
_MK_NODEJS_ENV_MK_ := 1

#$(info ---> .make/nodejs-env.mk)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
MK_DIR := $(GIT_ROOT)/.make

include $(MK_DIR)/nodejs.mk
include $(MK_DIR)/sops.mk

NODEJS_ENV_LOCAL := $(GIT_ROOT)/.env.local
NODEJS_ENV_LOCAL_ENCRYPTED := $(SOPS_KEYS_DIR)/env.local

#$(info NODEJS_ENV_LOCAL_ENCRYPTED=$(NODEJS_ENV_LOCAL_ENCRYPTED))

.PHONY: nodejs-env-check
nodejs-env-check: nodejs-check $(NODEJS_ENV_LOCAL)

$(NODEJS_ENV_LOCAL_ENCRYPTED):
	@echo "Creating $@ (encrypted)"
	@echo "EKG_BASE_INTERNAL=http://127.0.0.1:7878" > $@
	@echo "EKG_ID_BASE_INTERNAL=http://127.0.0.1:7878/id" > $@
	@echo "EKG_GRAPH_BASE_INTERNAL=http://127.0.0.1:7878/graph" > $@
	@echo "EKG_ONTOLOGY_BASE_INTERNAL=http://127.0.0.1:7878/ontology" > $@
	@echo "#"
	@echo "EKG_BASE_EXTERNAL=http://localhost:3000" >> $@
	@echo "EKG_ID_BASE_EXTERNAL=http://localhost:3000/id" >> $@
	@echo "EKG_GRAPH_BASE_EXTERNAL=http://localhost:3000/graph" >> $@
	@echo "EKG_ONTOLOGY_BASE_EXTERNAL=http://localhost:3000/ontology" >> $@
	@echo "#"
	@echo "EKG_API_BASE=http://localhost:3000/api" >> $@
	@echo "#"
	@echo "EKG_SPARQL_LOADER_ENDPOINT=http://127.0.0.1:7878/update" >> $@
	@echo "EKG_SPARQL_HEALTH_ENDPOINT=http://127.0.0.1:7878/status" >> $@
	@echo "EKG_SPARQL_QUERY_ENDPOINT=http://127.0.0.1:7878/query" >> $@
	@echo "EKG_SPARQL_UPDATE_ENDPOINT=http://127.0.0.1:7878/update" >> $@
	@echo "#"
	@echo "NODE_OPTIONS=--trace-deprecation --no-deprecation" >> $@
	@cat $@
	@cd $(@D) && $(SOPS_BIN) --in-place --encrypt $@

.PHONY: nodejs-env-encrypt
nodejs-env-encrypt: $(NODEJS_ENV_LOCAL_ENCRYPTED)

$(NODEJS_ENV_LOCAL): $(SOPS_BIN) $(NODEJS_ENV_LOCAL_ENCRYPTED)
	@echo "Decrypting $(NODEJS_ENV_LOCAL_ENCRYPTED) to $@"
	@$(SOPS_BIN) --decrypt $(NODEJS_ENV_LOCAL_ENCRYPTED) > $@

.PHONY: nodejs-env-decrypt
nodejs-env-decrypt: $(NODEJS_ENV_LOCAL)

.PHONY: nodejs-env-edit
nodejs-env-edit: $(SOPS_BIN) $(NODEJS_ENV_LOCAL_ENCRYPTED)
	@echo "Editing $(NODEJS_ENV_LOCAL_ENCRYPTED)"
	@$(SOPS_BIN) $(NODEJS_ENV_LOCAL_ENCRYPTED)

#$(info <--- .make/nodejs-env.mk)

endif # _MK_NODEJS_ENV_MK_
