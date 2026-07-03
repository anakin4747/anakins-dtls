
SHELL_PREFIX :=
ifndef IN_NIX_SHELL
SHELL_PREFIX := nix develop --command
endif

.PHONY: test
test:
	$(SHELL_PREFIX) python3 -m pytest tests/
	$(SHELL_PREFIX) cog check

.PHONY: dtspec
dtspec:
	$(SHELL_PREFIX) python3 -m pytest tests/test_dtspec.py
	$(SHELL_PREFIX) cog check
