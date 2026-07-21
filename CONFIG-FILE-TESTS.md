# Testing out-of-tree `.anakins-dtls` config detection

This is a design/planning doc for the tests we intend to write next (red,
before any implementation) for one narrow behavior: when a `.dts`/`.dtsi`
file being edited looks out-of-tree (not inside a recognizable in-tree kernel
layout) and no `.anakins-dtls` config file is present at the root of the
workspace folder, the server should warn the user via `window/showMessage`
and suggest how to generate one.

This builds on, but is decoupled from, the main loop tests in
`tests/main_loop_tests.lua`:

- Workspace root resolution (`rootUri` / `workspaceFolders` /
  `workspace/didChangeWorkspaceFolders`) is already covered there and is
  **not** re-tested here. Tests below pass a workspace root directly rather
  than depending on that plumbing.
- `.anakins-dtls` parsing itself (reading the file's `S="..."` value once one
  is found) is a separate concern for a later doc — this one only covers
  detecting that the file is *missing*.

## Config file location: workspace root only

`.anakins-dtls` is only ever looked for at `<workspace_root>/.anakins-dtls`
— exactly one path, checked once. There is no walking upward from the
edited file's directory searching intermediate levels, and no searching
multiple candidate directories. If `<workspace_root>/.anakins-dtls` doesn't
exist, the config is considered missing, full stop, regardless of where in
the tree the edited file itself lives.

## Scenario being tested

The motivating situation:

- The editor's workspace root is `/some/repo`.
- An out-of-tree devicetree is being edited at
  `/some/repo/one/path/to/devicetree.dts`.
- A real kernel source tree happens to exist at
  `/some/repo/another/path/to/kernel-sources`, but nothing references it.
- There is no `.anakins-dtls` at `/some/repo/.anakins-dtls`.

Expected behavior: on open, the server detects the file looks out-of-tree
(no recognizable in-tree kernel layout above it) and the workspace root has
no `.anakins-dtls`, so it reports this via `window/showMessage` rather than
silently failing or guessing.

This fires on `textDocument/didOpen`, not `didSave`: the client typically
only starts the language server (and sends its first message about a given
document) via `didOpen`, and this check is a one-shot environment/config
check — it depends only on the file's path and whether
`<workspace_root>/.anakins-dtls` exists, not on the file's content — so it
belongs at the start of that document's lifecycle rather than being
re-derived on every save.

## Out-of-tree heuristic

A file is considered **out-of-tree** when walking upward from its directory
does not find a recognizable in-tree kernel layout — i.e. sibling `arch/`,
`include/`, and `Documentation/` directories — within some bounded number of
parent directories. This matches the shape already implied by the existing
`tests/in-tree/` and `tests/out-of-tree/` fixtures.

This heuristic is only about whether the *file itself* looks out-of-tree —
it is unrelated to, and does not affect, where `.anakins-dtls` is looked
for (always exactly `<workspace_root>/.anakins-dtls`, per above).

## Fixture: `tests/out-of-tree-no-config/`

A new fixture sibling to the existing `tests/in-tree/` and
`tests/out-of-tree/`, deliberately omitting `.anakins-dtls`:

```
tests/out-of-tree-no-config/
  one/path/to/devicetree.dts        -- symlink -> ../../../../custom.dts (reuse the shared fixture)
  another/path/to/kernel-sources/   -- symlink -> ../../../../in-tree (reuse the existing kernel-tree fixture, unconnected via any config)
```

No `.anakins-dtls` exists at the fixture root
(`tests/out-of-tree-no-config/.anakins-dtls`). `another/path/to/kernel-sources`
exists only to prove the tool doesn't accidentally discover it through some
other means — it must not be consulted, since nothing points to it.

## 1. Unit-level test — pure detection function

A new pure function, `M.out_of_tree_without_config(ctx)`, tested the same
way as `M.in_a_root_node`, `M.hover`, etc. in `tests/anakins-dtls_tests.lua`:
takes `ctx = { file = ..., workspace_root = ... }` and returns a boolean,
with no channel/server/JSON-RPC involved. It checks only
`ctx.workspace_root .. "/.anakins-dtls"` for existence — it does not walk
upward from `ctx.file`'s directory.

```lua
describe("out_of_tree_without_config()", function()
    it("returns true for an out-of-tree file with no .anakins-dtls at the workspace root", function()
        local ctx = {
            file = ("%s/tests/out-of-tree-no-config/one/path/to/devicetree.dts"):format(cwd),
            workspace_root = ("%s/tests/out-of-tree-no-config"):format(cwd),
        }
        assert(dtls.out_of_tree_without_config(ctx))
    end)

    it("returns false when .anakins-dtls is present at the workspace root", function()
        local ctx = {
            file = ("%s/tests/out-of-tree/custom.dts"):format(cwd),
            workspace_root = ("%s/tests/out-of-tree"):format(cwd),
        }
        assert(not dtls.out_of_tree_without_config(ctx))
    end)

    it("returns false for an in-tree file (recognizable kernel layout)", function()
        local ctx = {
            file = ("%s/tests/in-tree/arch/arm64/boot/dts/freescale/custom.dts"):format(cwd),
            workspace_root = ("%s/tests/in-tree"):format(cwd),
        }
        assert(not dtls.out_of_tree_without_config(ctx))
    end)
end)
```

Following the existing "missing file" convention in
`tests/anakins-dtls_tests.lua`, `out_of_tree_without_config` should also be
added to that describe block's `function_names` list, so it's covered by
the existing "errors if `ctx.file` does not exist" test.

## 2. End-to-end main-loop test — `didOpen` triggers `showMessage`

Added as a new `describe` block in `tests/main_loop_tests.lua`, reusing its
existing `frame`/`parse_output`/harness helpers. Drives a full
`initialize -> initialized -> didOpen` sequence with a workspace root and a
`textDocument/didOpen` for the out-of-tree-no-config fixture file, and
asserts on the exact `window/showMessage` produced. This is `didOpen`-only —
there is no additional re-check on `didSave` for a document already known to
be open.

```lua
describe("out-of-tree devicetree with no .anakins-dtls", function()
    it("warns via showMessage on didOpen", function()
        local server = dtls.new_server(dtls.new_memory_channel())

        server.channel:push_input(frame({
            method = "initialize",
            id = 1,
            params = {
                workspaceFolders = {
                    { uri = ("file://%s/tests/out-of-tree-no-config"):format(cwd), name = "repo" },
                },
            },
        }))
        dtls.server_step(server)
        server.channel:take_output()

        server.channel:push_input(frame({ method = "initialized", params = {} }))
        dtls.server_step(server)
        server.channel:take_output()

        server.channel:push_input(frame({
            method = "textDocument/didOpen",
            params = {
                textDocument = {
                    uri = ("file://%s/tests/out-of-tree-no-config/one/path/to/devicetree.dts"):format(cwd),
                },
            },
        }))

        local continues = dtls.server_step(server)

        assert(continues)
        assert.are.equal("initialized", server.state)

        local output = parse_output(server.channel)
        assert.are.equal(1, #output)
        assert.are.equal("window/showMessage", output[1].method)
        assert.are.equal(2, output[1].params.type) -- Warning
        assert.are.equal(
            "Out-of-tree devicetree detected, but no .anakins-dtls was found. "
                .. "Generate one with: bitbake-getvar S -r virtual/kernel > .anakins-dtls",
            output[1].params.message
        )
    end)
end)
```

## Exact `showMessage` text (pinned, not partial-matched)

- `type = 2` (Warning — advisory, not blocking; editing still works without a
  config file).
- `message`:

  <markdown>
  Out-of-tree devicetree detected, but no .anakins-dtls was found.
  In a Yocto project you can generate one with:
  ```sh
  bitbake-getvar S -r virtual/kernel > .anakins-dtls
  ```
  </markdown>

This is pinned exactly (rather than the partial/substring matching used
elsewhere in `tests/main_loop_tests.lua`) per explicit decision, since the
message's wording — including the suggested command — is itself part of the
behavior being specified.

## Explicitly out of scope for these tests

- Parsing `rootUri`/`workspaceFolders` in the real `initialize` handler is
  covered separately in `tests/main_loop_tests.lua`
  ("initialize captures the workspace root"); these tests pass workspace
  root data directly and don't re-verify that plumbing.
- Searching anywhere other than exactly `<workspace_root>/.anakins-dtls`
  (e.g. walking up from the file, or checking multiple workspace folders) —
  not supported behavior, so not tested.
- Actually parsing a *present* `.anakins-dtls` file's `S="..."` value (once
  found) is a separate future doc/feature, not covered here.
- Any diagnostics/behavior once a config file's kernel root has been
  resolved (e.g. resolving includes from it) — out of scope; this doc is
  only about detecting and reporting the *missing* case.

## Order of implementation

1. `tests/out-of-tree-no-config/` fixture (no test yet, just fixture files).
2. `out_of_tree_without_config()` unit test + "missing file" list entry.
3. End-to-end `didOpen` -> `showMessage` test.
