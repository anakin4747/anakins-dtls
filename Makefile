SHELL_PREFIX :=
ifndef IN_NIX_SHELL
SHELL_PREFIX := nix develop --experimental-features 'nix-command flakes' --command
endif

.PHONY: make
make:
	$(SHELL_PREFIX) make test

.PHONY: test
test:
	cog check
	busted spec

.PHONY: install
install: uninstall
	nix profile add --experimental-features 'nix-command flakes' .

.PHONY: uninstall
uninstall:
	-nix profile remove --experimental-features 'nix-command flakes' dtls-fixtures
