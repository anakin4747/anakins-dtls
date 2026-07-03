
PYTHON := python3
ifndef IN_NIX_SHELL
PYTHON := nix develop --command python3
endif

.PHONY: test
test:
	$(PYTHON) -m pytest tests/

.PHONY: dtspec
dtspec:
	$(PYTHON) -m pytest tests/test_dtspec.py
