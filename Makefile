.PHONY: all test lint

all:
	nix --extra-experimental-features 'nix-command flakes' develop --command make test lint

lint:
	shellcheck --external-sources --shell=bash anakins-dtls tests/*_tests.bats

test:
	bats --formatter $(CURDIR)/tests/lsts/lsts-format-pretty tests/*_tests.bats
