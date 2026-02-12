.PHONY: help bootstrap discover map maintain maintain-all maintain-dry status test lint

help: ## Show available commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

bootstrap: ## First-time setup (scan GitHub, map repos, check status)
	./scripts/bootstrap.sh

discover: ## Scan GitHub account for all repos
	./scripts/discover.sh

map: ## Analyze repos with Claude and populate manifest
	./scripts/map-purposes.sh

maintain: ## Maintain a single repo (usage: make maintain REPO=name)
	@if [ -z "$(REPO)" ]; then \
		echo "Usage: make maintain REPO=<repo-name>"; \
		echo "       make maintain-all"; \
		echo "       make maintain-dry"; \
		exit 1; \
	fi
	./scripts/maintain.sh $(REPO)

maintain-all: ## Maintain all repos in the manifest
	./scripts/maintain.sh --all

maintain-dry: ## Dry-run maintenance on all repos (report only)
	./scripts/maintain.sh --all --dry-run

status: ## Check for drift, staleness, and orphaned repos
	./scripts/self-update.sh

test: ## Run bats tests
	@command -v bats >/dev/null 2>&1 || { echo "bats not found. Install: npm i -g bats or brew install bats-core"; exit 1; }
	bats test/

lint: ## Run shellcheck on all scripts
	@command -v shellcheck >/dev/null 2>&1 || { echo "shellcheck not found. Install: apt install shellcheck or brew install shellcheck"; exit 1; }
	shellcheck scripts/*.sh
