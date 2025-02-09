ifndef _MK_NEXTJS_MK_
_MK_NEXTJS_MK_ := 1

#$(info ---> .make/nextjs.mk)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
ifndef MK_DIR
MK_DIR := $(GIT_ROOT)/.make
endif

include $(MK_DIR)/os.mk
include $(MK_DIR)/pnpm.mk

.PHONY: nextjs-run
nextjs-run: pnpm-check
	cd $(GIT_ROOT) && $(PNPM_BIN) run dev

.PHONY: nextjs-clean
nextjs-clean: pnpm-clean
	@echo "Cleaning NextJS (and OpenNext)"
	@rm -rf $(GIT_ROOT)/.next
	@rm -rf $(GIT_ROOT)/.open-next

.PHONY: nextjs-upgrade
nextjs-upgrade: pnpm-check os-tools-install
	@echo "Upgrading NextJS (and OpenNext)"
	@echo "First, upgrade all global packages"
	@$(PNPM_BIN) upgrade --dir $(GIT_ROOT) --global
	@$(PNPM_BIN) add --global shadcn-ui@latest
	@echo "Then, upgrade react"
	@$(PNPM_BIN) add --dir $(GIT_ROOT) --save-prod react@latest react-dom@latest
	@echo "Then, upgrade react-email"
	@$(PNPM_BIN) add --dir $(GIT_ROOT) --save-prod react-email@latest
	@echo "Then, upgrade playwright"
	@$(PNPM_BIN) add --dir $(GIT_ROOT) --save-prod @playwright/test@latest
	@$(PNPM_BIN) exec playwright install
	@echo "Then, upgrade nextjs"
	@$(PNPM_BIN) add --dir $(GIT_ROOT) --save-prod next@latest
	@echo "Then, upgrade OpenNext"
	@$(PNPM_BIN) add --dir $(GIT_ROOT) --save-prod open-next@latest
	@echo "Then, upgrade eslint"
	@$(PNPM_BIN) add --dir $(GIT_ROOT) --save-prod eslint-config-next@latest
	@echo "Then, upgrade everything else"
	@$(PNPM_BIN) upgrade --dir $(GIT_ROOT) --recursive

shadcn-cli-install:
	@echo "Installing shadcn-cli"
	#@$(PNPM_BIN) add --global shadcn-ui@latest
	# See https://github.com/shadcn-ui/ui/issues/648#issuecomment-2315604382
	# because of this, we need to use npm here because pnpm sometimes failes
	# to install the shadcn-cli.
	@$(NPM_BIN) install --global shadcn-cli

#
# The UI heavily relies on the shadcn-ui components.
# See https://ui.shadcn.com/.
# The "problem" with shadcn-ui is that it provides these components as code, not
# as npm packages. So, we need to install a copy of that code into the src/components/ui
# directory. shadcn provides a CLI to do that which is what we're using here.
# Run `make shadcn-update` from time to time.
#
shadcn-update: pnpm-check
	@echo "Updating all shadcn-ui components"
	#@$(PNPM_BIN) dlx shadcn-ui@latest add --yes --overwrite --cwd $(GIT_ROOT) --all
	$(NPX_BIN) --force shadcn@latest add --yes --overwrite --cwd $(GIT_ROOT) --all

#$(info <--- .make/nextjs.mk)

endif # _MK_NEXTJS_MK_
