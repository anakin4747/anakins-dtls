SHELL_PREFIX :=
ifndef IN_NIX_SHELL
SHELL_PREFIX := nix develop --experimental-features 'nix-command flakes' --command
endif

PREFIX ?= /usr/local
VERSION := $(shell git describe --tags --abbrev=0)
REVISION := $(shell git rev-parse HEAD)

.PHONY: make
make:
	@grep -Fq 'version = "'$$(git describe --tags --abbrev=0)'";' flake.nix
	$(SHELL_PREFIX) make test lint fmt-check

.luarc.json:
	./scripts/generate-luarc

.PHONY: test
test: .luarc.json
	busted --output=gtest --pattern="_tests%.lua$$" tests

.PHONY: lint
lint:
	cog check
	luacheck lua tests

.PHONY: fmt-check
fmt-check:
	stylua --check lua

.PHONY: install
install: uninstall
	nix profile add --experimental-features 'nix-command flakes' .

.PHONY: uninstall
uninstall:
	-nix profile remove --experimental-features 'nix-command flakes' dtls-fixtures

.PHONY: manual-install
manual-install:
	install -Dm755 lua/anakins-dtls.lua "$(DESTDIR)$(PREFIX)/bin/anakins-dtls"
	sed -i \
		-e '/ANAKINS_DTLS_VERSION/s/or "unknown"/or "$(VERSION)"/' \
		-e '/ANAKINS_DTLS_REVISION/s/or "unknown"/or "$(REVISION)"/' \
		"$(DESTDIR)$(PREFIX)/bin/anakins-dtls"

.PHONY: manual-uninstall
manual-uninstall:
	rm -f "$(DESTDIR)$(PREFIX)/bin/anakins-dtls"
