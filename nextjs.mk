ifndef _MK_NEXTJS_MK_
_MK_NEXTJS_MK_ := 1

#$(info ---> .make/nextjs.mk)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
ifndef MK_DIR
MK_DIR := $(GIT_ROOT)/.make
endif

NEXT_VERSION := "canary"
SHADCN_VERSION := "canary"
TAILWINDCSS_VERSION := "latest"

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
	@echo "Then, upgrade all local packages"
	@$(PNPM_BIN) update --dir $(GIT_ROOT) --latest
	@echo "Then, run install to sync node_modules dir with package.json"
	@$(PNPM_BIN) install --dir $(GIT_ROOT)
	@echo "Then, upgrade react"
	@$(PNPM_BIN) add --dir $(GIT_ROOT) --workspace-root --save-prod react@latest react-dom@latest
	@echo "Then, upgrade --dir $(GIT_ROOT) react-email"
	@$(PNPM_BIN) add --dir $(GIT_ROOT) --workspace-root --save-prod react-email@latest
	@echo "Then, upgrade playwright"
	@$(PNPM_BIN) add --dir $(GIT_ROOT) --workspace-root --save-prod @playwright/test@latest
	@$(PNPM_BIN) exec playwright install
	@echo "Then, run install to sync node_modules dir with package.json"
	@$(PNPM_BIN) install --dir $(GIT_ROOT)
	@echo "Then, upgrade Next.js"
	@$(PNPM_BIN) add --dir $(GIT_ROOT) --workspace-root --save-prod next@${NEXT_VERSION} 
	@$(PNPM_BIN) add --dir $(GIT_ROOT) --workspace-root --save-prod eslint-config-next@${NEXT_VERSION}
	@$(PNPM_BIN) add --dir $(GIT_ROOT) --workspace-root --save-prod shadcn@${SHADCN_VERSION}
	@$(PNPM_BIN) add --dir $(GIT_ROOT) --workspace-root --save-dev @next/codemod@${NEXT_VERSION}
	@echo "Then, upgrade OpenNext"
	@$(PNPM_BIN) add --dir $(GIT_ROOT) --workspace-root --save-prod open-next@latest
	@echo "Then, upgrade everything else"
	@$(PNPM_BIN) upgrade --dir $(GIT_ROOT) --recursive


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
	rm -rf $(GIT_ROOT)/src/components/ui || true
	mkdir -p $(GIT_ROOT)/src/components/ui || true
	$(PNPM_BIN) update --dir $(GIT_ROOT) "@radix-ui/*" cmdk lucide-react recharts tailwind-merge clsx --latest
	$(PNPM_BIN) dlx shadcn@${SHADCN_VERSION} add --yes --overwrite --cwd $(GIT_ROOT) --all

.PHONY: tailwindcss-install
tailwindcss-install: pnpm-check
	@echo "Installing Tailwind CSS packages (for a NextJS project)"
	$(PNPM_BIN) add tailwindcss@${TAILWINDCSS_VERSION} @tailwindcss/postcss@${TAILWINDCSS_VERSION} postcss@latest

shadcn-init: tailwindcss-install pnpm-check
	@echo "Initializing the shadcn-ui project"
	rm -rf $(GIT_ROOT)/src/components/ui || true
	mkdir -p $(GIT_ROOT)/src/components/ui || true
	touch src/styles/globals.css
	$(PNPM_BIN) update --dir $(GIT_ROOT) "@radix-ui/*" cmdk lucide-react recharts tailwind-merge clsx --latest
	$(PNPM_BIN) dlx shadcn@${SHADCN_VERSION} init --base-color slate --yes --force  --cwd $(GIT_ROOT) --src-dir 

shadcn-add-all-components: pnpm-check
	@echo "Add all shadcn-ui components"
	rm -rf $(GIT_ROOT)/src/components/ui || true
	rm -f $(GIT_ROOT)/src/hooks/use-mobile.ts || true
	# For some reason the --overwrite flag doesn't work when adding all components with --all
	$(PNPM_BIN) dlx shadcn@${SHADCN_VERSION} add --all --yes --cwd $(GIT_ROOT) --src-dir --overwrite --path src/components/ui

#$(info <--- .make/nextjs.mk)

endif # _MK_NEXTJS_MK_
