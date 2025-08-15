# Makefile for llm-d-modelservice

PATHS_TO_VERIFY := examples/
.PHONY: verify
verify: generate-example-output
	git --no-pager diff --exit-code $(PATHS_TO_VERIFY)
	if git ls-files --exclude-standard --others $(PATHS_TO_VERIFY) | grep -q . ; then exit 1; fi

.PHONY: generate-example-output
generate-example-output:
	hack/generate-example-output.sh
