ifndef _MK_CADDY_MK_
_MK_CADDY_MK_ := 1

#$(info ---> .make/caddy.mk)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
ifndef MK_DIR
MK_DIR := $(GIT_ROOT)/.make
endif

include $(MK_DIR)/os.mk
include $(MK_DIR)/brew.mk
include $(MK_DIR)/curl.mk

CADDY_BIN := $(call where-is-binary,caddy)

ifdef CADDY_BIN
CADDY_VERSION := $(shell $(CADDY_BIN) version 2>/dev/null | head -n1 | cut -d\  -f1 | sed 's/^v//')
endif
# keep the line below in sync with version published at https://formulae.brew.sh/formula/caddy
CADDY_VERSION_EXPECTED := 2.9.1

ifeq ($(CADDY_VERSION),$(CADDY_VERSION_EXPECTED))
CADDY_CHECKED := 1
else
CADDY_CHECKED := 0
ifdef CADDY_BIN
$(info Caddy version $(CADDY_VERSION) does not match expected version $(CADDY_VERSION_EXPECTED))
else
$(info Caddy $(CADDY_VERSION_EXPECTED) has not been installed)
endif
endif

.PHONY: caddy-check
ifdef CADDY_BIN
ifeq ($(CADDY_CHECKED),1)
caddy-check:
	@echo "Using Caddy $(CADDY_VERSION)"
else
caddy-check: caddy-install
endif
else
caddy-check: caddy-install
endif

.PHONY: caddy-install
ifeq ($(UNAME_S),Darwin)
caddy-install: brew-check
	@printf "$(bold)Installing Caddy via brew$(normal)\n"
	$(BREW_BIN) install caddy
else ifeq ($(IS_LINUX_WITH_APT),1)
caddy-install: curl-check
	@printf "$(bold)Installing Caddy via apt$(normal)\n"
	sudo apt-get install -y debian-keyring debian-archive-keyring apt-transport-https
	curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor --yes -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
	curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
	sudo apt-get update
	sudo apt-get install -y caddy
else ifeq ($(IS_LINUX_WITH_YUM),1)
caddy-install: curl-check
	@printf "$(bold)Installing Caddy via yum$(normal)\n"
	sudo yum install -y yum-plugin-copr
	sudo yum copr enable -y @caddy/caddy
	sudo yum install -y caddy
else
caddy-install: brew-check
	@printf "$(bold)Installing Caddy via brew$(normal)\n"
	$(BREW_BIN) install caddy
endif

.PHONY: caddy-serve
caddy-serve: caddy-check
	@printf "$(bold)Starting Caddy$(normal)\n"
	$(CADDY_BIN) run

.PHONY: caddy-stop
caddy-stop: caddy-check
	@printf "$(bold)Stopping Caddy$(normal)\n"
	$(CADDY_BIN) stop

.PHONY: caddy-reload
caddy-reload: caddy-check
	@printf "$(bold)Reloading Caddy configuration$(normal)\n"
	$(CADDY_BIN) reload

#$(info <--- .make/caddy.mk)

endif # _MK_CADDY_MK_
