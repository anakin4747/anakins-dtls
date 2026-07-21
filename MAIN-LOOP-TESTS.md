# Testing the main loop

This is a design/planning doc for the tests that will exercise the LSP main
loop's high-level **state management** — not its handlers' internal logic
(hover, diagnostics, etc., which have their own tests elsewhere). None of the
loop itself is implemented yet; this doc describes the tests we intend to
write first (red), before any implementation (green).

## What is (and isn't) covered

Covered, as observable behavior only:

- Lifecycle state transitions: `uninitialized -> initialized -> shutdown ->
  exited`.
- What gets written to the channel (message shape: method/id/result/error),
  not how it's built internally.
- Whether a Lua error thrown while handling one message crashes the loop, or
  is caught and reported so the loop keeps serving subsequent messages.

Not covered here (tested elsewhere / out of scope for this doc):

- JSON encode/decode correctness (`tests/json_tests.lua`).
- Actual diagnostics or hover content produced by a handler.

## Harness

Tests drive the loop via an in-memory channel (`M.new_memory_channel()`):

- `channel:push_input(bytes)` queues raw, already-framed
  (`Content-Length: N\r\n\r\n<json>`) request/notification bytes as input.
- `channel:take_output()` returns the raw bytes the loop wrote, which tests
  parse back into a list of decoded messages for assertion.

Two ways to drive the loop:

- `server_step(server)` — process exactly one input message, return whether
  the loop should continue. Used for the state-transition table below.
- `server_run(server)` — loop until natural termination (EOF or `exit`
  handled). Used for the end-to-end scenario tests.

## 1. State-transition table

One `describe` block table-driving inputs against expected outcomes, rather
than a bespoke test per case:

```lua
describe("server_step() state transitions", function()
    local cases = {
        {
            name = "initialize while uninitialized succeeds",
            starting_state = "uninitialized",
            input = { method = "initialize", id = 1, params = {} },
            expect_state = "initialized",
            expect_output = {
                { id = 1, result = { capabilities = ANY } },
            },
        },
        {
            name = "initialize while already initialized is rejected",
            starting_state = "initialized",
            input = { method = "initialize", id = 2, params = {} },
            expect_state = "initialized",
            expect_output = {
                { id = 2, error = { code = -32002 } },
            },
        },
        {
            name = "a request other than initialize before initialize is rejected",
            starting_state = "uninitialized",
            input = { method = "shutdown", id = 3 },
            expect_state = "uninitialized",
            expect_output = {
                { id = 3, error = { code = -32002 } },
            },
        },
        {
            name = "didSave notification while initialized is accepted silently",
            starting_state = "initialized",
            input = {
                method = "textDocument/didSave",
                params = { textDocument = { uri = "file:///custom.dts" } },
            },
            expect_state = "initialized",
            expect_output = {}, -- no response for a notification
        },
        {
            name = "didSave notification before initialize reports an error via showMessage",
            starting_state = "uninitialized",
            input = {
                method = "textDocument/didSave",
                params = { textDocument = { uri = "file:///custom.dts" } },
            },
            expect_state = "uninitialized",
            expect_output = {
                { method = "window/showMessage", params = { type = 1 } }, -- Error
            },
        },
        {
            name = "shutdown while initialized succeeds",
            starting_state = "initialized",
            input = { method = "shutdown", id = 4 },
            expect_state = "shutdown",
            expect_output = {
                { id = 4, result = json.NULL },
            },
        },
        {
            name = "shutdown while already shutdown is rejected",
            starting_state = "shutdown",
            input = { method = "shutdown", id = 5 },
            expect_state = "shutdown",
            expect_output = {
                { id = 5, error = { code = ANY } },
            },
        },
    }

    for _, case in ipairs(cases) do
        it(case.name, function()
            local server = new_server_in_state(case.starting_state)
            server.channel:push_input(frame(case.input))

            local continues = server_step(server)

            assert.are.equal(case.expect_state, server.state)
            assert.same(case.expect_output, parse_output(server.channel))
            assert(continues) -- none of these terminate the loop
        end)
    end
end)
```

`new_server_in_state(state)` is a small test helper that constructs a server
and fast-forwards it to the given state (e.g. by feeding it the necessary
prior messages), so each case only has to assert on the transition under
test.

## 2. `exit` termination behavior

Separate from the table above since it's about whether the loop *stops*, and
with what `exit_code`, rather than what gets written:

```lua
describe("exit notification", function()
    it("stops the loop and exits 0 after a proper shutdown", function()
        local server = new_server_in_state("shutdown")
        server.channel:push_input(frame({ method = "exit" }))

        local continues = server_step(server)

        assert.is_false(continues)
        assert.are.equal(0, server.exit_code)
    end)

    it("stops the loop and exits 1 without a prior shutdown", function()
        local server = new_server_in_state("initialized")
        server.channel:push_input(frame({ method = "exit" }))

        local continues = server_step(server)

        assert.is_false(continues)
        assert.are.equal(1, server.exit_code)
    end)
end)
```

## 3. Error resilience — a handler throwing must not crash the loop

This is the key robustness property of a long-running main loop: one bad
message must not take the whole server down.

```lua
describe("error handling", function()
    it("catches a Lua error thrown while handling a message and keeps running", function()
        local server = new_server_in_state("initialized")

        -- Force the handler for a known method to throw, without needing to
        -- find a real input that triggers a bug. This isolates the test to
        -- the loop's error handling, not any one handler's correctness.
        stub_handler_to_throw(server, "textDocument/didSave", "boom")

        server.channel:push_input(frame({
            method = "textDocument/didSave",
            params = { textDocument = { uri = "file:///custom.dts" } },
        }))

        local continues = server_step(server)

        assert(continues) -- the loop itself did not stop
        assert.are.equal("initialized", server.state) -- state unaffected

        local output = parse_output(server.channel)
        assert.are.equal(1, #output)
        assert.are.equal("window/showMessage", output[1].method)
        assert.are.equal(1, output[1].params.type) -- Error
        assert.matches("boom", output[1].params.message)
    end)

    it("still serves subsequent valid messages after a handler error", function()
        local server = new_server_in_state("initialized")
        stub_handler_to_throw(server, "textDocument/didSave", "boom")

        server.channel:push_input(frame({
            method = "textDocument/didSave",
            params = { textDocument = { uri = "file:///custom.dts" } },
        }))
        server_step(server) -- the failing message

        server.channel:push_input(frame({ method = "shutdown", id = 9 }))
        server_step(server) -- a subsequent, valid message

        assert.are.equal("shutdown", server.state)
        local output = parse_output(server.channel)
        assert.are.equal(9, output[#output].id)
        assert.same(json.NULL, output[#output].result)
    end)

    it("reports a garbage/unparsable message via showMessage without crashing", function()
        local server = new_server_in_state("initialized")

        server.channel:push_input("not a valid Content-Length frame at all")

        local continues = server_step(server)

        assert(continues)
        local output = parse_output(server.channel)
        assert.are.equal("window/showMessage", output[1].method)
        assert.are.equal(1, output[1].params.type)
    end)
end)
```

The implementation implication (not yet built): the dispatch call inside
`server_step` must be wrapped in `pcall`, and any error — whether raised by a
handler or by parsing/framing — must be converted into a
`window/showMessage` (type = Error) notification plus a log line on the
channel's stderr side, rather than propagating and killing `server_run`'s
`while` loop.

## 4. End-to-end scenario (the "smart", full-loop test)

One black-box test pushing a whole realistic session's raw bytes in one go
and running `server_run` to completion, asserting on the full output
transcript and final `exit_code`:

```lua
it("handles a full initialize -> didSave -> shutdown -> exit session", function()
    local server = new_server(new_memory_channel())

    server.channel:push_input(frame({ method = "initialize", id = 1, params = {} }))
    server.channel:push_input(frame({ method = "initialized", params = {} }))
    server.channel:push_input(frame({
        method = "textDocument/didSave",
        params = { textDocument = { uri = "file:///custom.dts" } },
    }))
    server.channel:push_input(frame({ method = "shutdown", id = 2 }))
    server.channel:push_input(frame({ method = "exit" }))

    server_run(server)

    local output = parse_output(server.channel)
    assert.are.equal(1, output[1].id)
    assert.truthy(output[1].result.capabilities)
    assert.are.equal(2, output[2].id)
    assert.same(json.NULL, output[2].result)
    assert.are.equal(2, #output) -- didSave produced no message; initialized none either
    assert.are.equal(0, server.exit_code)
end)
```

## Order of implementation (red -> green per step)

1. `frame()` / `parse_output()` test helpers + channel push/take — exercised
   indirectly by every test above; build alongside the first test.
2. `initialize` transition (uninitialized -> initialized), capabilities
   shape.
3. Rejecting requests before `initialize` (`-32002`).
4. `didSave` accepted while initialized / rejected (via `showMessage`) while
   uninitialized.
5. `shutdown` transition + rejection when already shut down.
6. `exit` termination + `exit_code` (0 vs 1).
7. Error resilience: handler throws -> `showMessage`, loop continues, state
   unaffected, subsequent messages still served.
8. Garbage/unparsable input -> `showMessage`, loop continues.
9. Full end-to-end scenario test.

Each numbered step gets its own red -> green -> refactor cycle and its own
commit, per `AGENTS.md`.
