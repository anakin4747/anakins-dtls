.PHONY: test
test:
	nix develop --command \
		python3 -m pytest tests/features/step_definitions/test_standard_properties.py
