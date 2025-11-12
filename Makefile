# Makefile for llm-d-modelservice
PROJECT_DIR := $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))

# Add local bin directory to PATH for all commands
export PATH := $(PROJECT_DIR)/bin:$(PATH)

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Development

.PHONY: pre-helm
pre-helm: tools ## Set up Helm dependency repositories
	bin/helm repo add bitnami https://charts.bitnami.com/bitnami

.PHONY: lint
lint: pre-helm ## Run lint checks using helm-lint
	bin/ct lint --config ct.yaml $(if $(TARGET_BRANCH),--target-branch $(TARGET_BRANCH))

# Paths that need verification during 'make verify'
PATHS_TO_VERIFY := examples/

.PHONY: verify
verify: generate ## Verify that generated files match current state
	git --no-pager diff --exit-code $(PATHS_TO_VERIFY)
	if git ls-files --exclude-standard --others $(PATHS_TO_VERIFY) | grep -q . ; then exit 1; fi

##@ Automation

.PHONY: generate
generate: tools ## Generate example output files from Helm chart templates
	hack/generate-example-output.sh

.PHONY: bump-chart-version-%
bump-chart-version-%: tools ## Bump chart version by type (patch, major, minor) e.g., make bump-chart-version-patch
	@printf "\033[33;1m==== Running bump chart version ====\033[0m\n"
	hack/increment-chart-version.sh $*
	## Regenerate example output after version bump
	hack/generate-example-output.sh

##@ Tools

.PHONY: tools
tools: ## Install all required tools (helm, ct, pre-commit)
	hack/install-tools.sh

##@ Pre-commit

.PHONY: pre-commit-install
pre-commit-install: tools ## Install pre-commit hooks
	bin/pre-commit install

.PHONY: pre-commit-run
pre-commit-run: tools ## Run pre-commit hooks on all files
	bin/pre-commit run --all-files

.PHONY: pre-commit-update
pre-commit-update: tools ## Update pre-commit hooks to latest versions
	bin/pre-commit autoupdate
