SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

TEST_RESULTS_DIR := test-results
MEGALINTER_IMAGE ?= docker.io/oxsecurity/megalinter-ci_light:v10.1.0

.PHONY: clean integration-test test validate

test:
	rm -rf "$(TEST_RESULTS_DIR)"
	mkdir -p "$(TEST_RESULTS_DIR)/unit"
	bats \
		--formatter tap \
		--report-formatter junit \
		--output "$(TEST_RESULTS_DIR)/unit" \
		tests/fmlint.bats

validate:
	MEGALINTER_IMAGE="$(MEGALINTER_IMAGE)" tests/validate.bash

integration-test:
	MEGALINTER_IMAGE="$(MEGALINTER_IMAGE)" tests/megalinter.bash

clean:
	rm -rf "$(TEST_RESULTS_DIR)"
