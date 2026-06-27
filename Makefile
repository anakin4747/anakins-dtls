.PHONY: all test lint submodules install install-manual uninstall-manual

PREFIX ?= /usr/local

all: submodules
	nix --extra-experimental-features 'nix-command flakes' develop --command make test lint

submodules:
	git submodule update --init --recursive

lint:
	shellcheck --external-sources --shell=bash --severity=warning anakins-dtls tests/*_tests.bats
	awk -f scripts/find-multiline-non-bash.awk anakins-dtls

test:
	bats --formatter $(CURDIR)/tests/lsts-format-pretty tests/*_tests.bats

install-manual:
	install -m 755 anakins-dtls $(PREFIX)/bin/anakins-dtls

uninstall-manual:
	rm -f $(PREFIX)/bin/anakins-dtls
