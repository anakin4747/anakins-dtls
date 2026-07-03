
SHELL_PREFIX :=
ifndef IN_NIX_SHELL
SHELL_PREFIX := nix develop --command
endif

.PHONY: test
test:
	$(SHELL_PREFIX) \
		python3 \
			-m pytest tests/features/step_definitions/test_standard_properties.py \
			--gherkin-terminal-reporter \
			-v
