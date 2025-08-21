# Makefile for llm-d-modelservice

##@ Development
# Paths that need verification during 'make verify'
PATHS_TO_VERIFY := examples/

.PHONY: verify
verify: generate ## Verify that generated files match current state
	git --no-pager diff --exit-code $(PATHS_TO_VERIFY)
	if git ls-files --exclude-standard --others $(PATHS_TO_VERIFY) | grep -q . ; then exit 1; fi

##@ Automation

.PHONY: generate
generate: ## Generate example output files from Helm chart templates
	hack/generate-example-output.sh
