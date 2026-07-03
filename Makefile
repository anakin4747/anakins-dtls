
PYTHON := python3
ifndef IN_NIX_SHELL
PYTHON := nix develop --command python3
endif

.PHONY: dtspec
dtspec:
	$(PYTHON) \
		-m pytest tests/test_dtspec.py \
		--gherkin-terminal-reporter \
		-v

.PHONY: test
test:
	$(PYTHON) \
		-m pytest tests/ \
		--gherkin-terminal-reporter \
		-v
