
SHELL_PREFIX :=
ifndef IN_NIX_SHELL
SHELL_PREFIX := nix develop --command
endif

.PHONY: test
test:
	$(SHELL_PREFIX) cog check
	$(SHELL_PREFIX) python3 -m pytest tests/

.PHONY: dtspec
dtspec:
	$(SHELL_PREFIX) cog check
	$(SHELL_PREFIX) python3 -m pytest tests/test_dtspec.py
