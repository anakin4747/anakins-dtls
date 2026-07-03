
SHELL_PREFIX :=
ifndef IN_NIX_SHELL
SHELL_PREFIX := nix develop --command
endif

.PHONY: test
test: generate-docs
	$(SHELL_PREFIX) cog check
	$(SHELL_PREFIX) python3 -m pytest tests/

.PHONY: dtspec
dtspec: generate-docs
	$(SHELL_PREFIX) cog check
	$(SHELL_PREFIX) python3 -m pytest tests/test_generate_docs.py

.PHONY: generate-docs
generate-docs:
	$(SHELL_PREFIX) env PYTHONPATH=tools python -c "from generate_docs import write_hover_docs; write_hover_docs()"
