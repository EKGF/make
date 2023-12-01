#
# All the poetry related stuff
#
ifndef _MK_POETRY_MK_
_MK_POETRY_MK_ := 1

#$(info ---> .make/poetry.mk)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
MK_DIR := $(GIT_ROOT)/.make

include $(MK_DIR)/os.mk
include $(MK_DIR)/curl.mk
include $(MK_DIR)/brew.mk
include $(MK_DIR)/pip.mk
include $(MK_DIR)/pipx.mk
include $(MK_DIR)/python.mk

POETRY_BIN := $(call where-is-binary,poetry)

ifdef POETRY_BIN
expr_poetry := s/.*version \(.*\))/\1/g
POETRY_VERSION := $(shell $(POETRY_BIN) --version 2>&1 | sed "$(expr_poetry)")
endif
POETRY_VERSION_EXPECTED := 1.8.0.dev0
ifeq ($(POETRY_VERSION),$(POETRY_VERSION_EXPECTED))
POETRY_CHECKED := 1
else
POETRY_CHECKED := 0
$(info poetry version $(POETRY_VERSION) does not match expected version $(POETRY_VERSION_EXPECTED))
endif

.PHONY: poetry-check
ifdef POETRY_BIN
ifeq ($(POETRY_CHECKED),1)
poetry-check: pip-check
	@#echo "Using poetry $(POETRY_VERSION)"
else
poetry-check: poetry-install-itself
endif
else
poetry-check: poetry-install-itself
endif

.PHONY: poetry-install-itself
poetry-install-itself: brew-check pipx-check
	@printf "Installing $(bold)poetry$(normal) via pipx:\n"
	@$(BREW_BIN) remove poetry >/dev/null 2>&1 || true
	@rm -rf $(HOME)/.local/pipx/venvs/poetry >/dev/null 2>&1 || true
	$(PIPX_BIN) install --python $(PYTHON_BIN) --force git+https://github.com/python-poetry/poetry.git@master
	$(PIPX_BIN) inject poetry poetry-plugin-dotenv

.PHONY: poetry-clean
poetry-clean:
	rm -rf $(GIT_ROOT)/.venv

.PHONY: poetry-lock-no-update
poetry-lock-no-update: poetry-check
	$(POETRY_BIN) lock --no-update

.PHONY: poetry-config-update
poetry-config-update: poetry-check
	$(POETRY_BIN) config experimental.new-installer true
	$(POETRY_BIN) config --local installer.no-binary :all:

.PHONY: poetry-config-list
poetry-config-list: poetry-check
	@$(POETRY_BIN) config --list

.PHONY: poetry-install
poetry-install: poetry-check pipx-check $(TMP_DIR)/python3
	@printf "Installing python packages with poetry:\n"
	@PATH=$(TMP_DIR):$${PATH} $(POETRY_BIN) add --group dev pytest@latest || true
	@PATH=.venv/bin:$(TMP_DIR):$${PATH} $(POETRY_BIN) install || true
	@printf "Python packages have been installed with poetry\n"

.PHONY: poetry-update
poetry-update: poetry-check
	@$(POETRY_BIN) update || true

#$(info <--- .make/poetry.mk)

endif # _MK_POETRY_MK_
