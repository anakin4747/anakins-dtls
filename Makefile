SHELL_PREFIX :=
ifndef IN_NIX_SHELL
SHELL_PREFIX := nix develop --experimental-features 'nix-command flakes' --command
endif

.PHONY: make
make:
	$(SHELL_PREFIX) make test lint

.PHONY: test
test:
	busted spec

.PHONY: lint
lint:
	cog check
	luacheck lua spec

.PHONY: install
install: uninstall
	nix profile add --experimental-features 'nix-command flakes' .

.PHONY: uninstall
uninstall:
	-nix profile remove --experimental-features 'nix-command flakes' dtls-fixtures
