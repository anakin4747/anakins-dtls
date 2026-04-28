.PHONY: all test lint submodules

all: submodules
	nix --extra-experimental-features 'nix-command flakes' develop --command make test lint

submodules:
	git submodule update --init --recursive

lint:
	shellcheck --external-sources --shell=bash --severity=warning anakins-dtls tests/*_tests.bats

test:
	bats --formatter $(CURDIR)/tests/lsts/lsts-format-pretty tests/*_tests.bats
