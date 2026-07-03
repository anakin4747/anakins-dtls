
PYTHON := python3
ifndef IN_NIX_SHELL
PYTHON := nix develop --command python3
endif

.PHONY: test
test:
	$(PYTHON) -m pytest tests/
	cog check

.PHONY: dtspec
dtspec:
	$(PYTHON) -m pytest tests/test_dtspec.py
	cog check
