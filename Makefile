SHELL_PREFIX :=
ifndef IN_NIX_SHELL
SHELL_PREFIX := nix develop --experimental-features 'nix-command flakes' --command
endif

.PHONY: make
make:
	$(SHELL_PREFIX) make luarc test lint fmt-check

.PHONY: luarc
luarc:
	./scripts/generate-luarc

.PHONY: test
test:
	busted --pattern="_tests%.lua$$" tests

.PHONY: lint
lint:
	cog check
	luacheck lua tests

.PHONY: fmt-check
fmt-check:
	stylua --check lua tests

.PHONY: install
install: uninstall
	nix profile add --experimental-features 'nix-command flakes' .

.PHONY: uninstall
uninstall:
	-nix profile remove --experimental-features 'nix-command flakes' dtls-fixtures
