local busted = require("busted")
local assert = require("luassert")
local describe = busted.describe
local it = busted.it

package.path = "./lua/?.lua;" .. package.path
local dtls = require("anakins-dtls")
local json = dtls.json

local pwd = io.popen("pwd")
local project_root = pwd:read("*l")
pwd:close()

-- Sentinel used in expected-output tables to mean "this field must be
-- present, but its exact value isn't asserted here" (e.g. capabilities).
local ANY = setmetatable({}, {
    __tostring = function()
        return "ANY"
    end,
})

-- Frame a decoded message table as raw `Content-Length: N\r\n\r\n<json>` bytes.
local function frame(msg)
    local body = json.encode(msg)
    return ("Content-Length: %d\r\n\r\n%s"):format(#body, body)
end

-- Parse a stream of one or more framed messages back into decoded tables.
local function parse_output_string(bytes)
    local messages = {}
    local pos = 1

    while pos <= #bytes do
        local header_end = bytes:find("\r\n\r\n", pos, true)
        if not header_end then
            break
        end

        local header = bytes:sub(pos, header_end - 1)
        local length = tonumber(header:match("Content%-Length:%s*(%d+)"))
        if not length then
            break
        end

        local body_start = header_end + 4
        messages[#messages + 1] = json.decode(bytes:sub(body_start, body_start + length - 1))
        pos = body_start + length
    end

    return messages
end

local function parse_output(channel)
    return parse_output_string(channel:take_output())
end

-- Recursively check that every field present in `expected` matches the
-- corresponding field in `actual`, treating `ANY` as a wildcard and ignoring
-- any extra fields `actual` has that `expected` doesn't mention.
local function matches(expected, actual)
    if expected == ANY then
        return actual ~= nil
    end

    if type(expected) == "table" and type(actual) == "table" then
        for k, v in pairs(expected) do
            if not matches(v, actual[k]) then
                return false
            end
        end
        return true
    end

    return expected == actual
end

local function assert_output_matches(expected_list, actual_list)
    assert.are.equal(#expected_list, #actual_list)
    for i, expected in ipairs(expected_list) do
        assert(matches(expected, actual_list[i]), ("output message %d did not match expected shape"):format(i))
    end
end

-- Construct a fresh server and fast-forward it to `state` by feeding it the
-- necessary prior messages, discarding their output along the way.
local function new_server_in_state(state)
    local server = dtls.new_server(dtls.new_memory_channel())
    if state == "uninitialized" then
        return server
    end

    server.channel:push_input(frame({ method = "initialize", id = 0, params = {} }))
    dtls.server_step(server)
    server.channel:take_output()
    if state == "initialized" then
        return server
    end

    server.channel:push_input(frame({ method = "shutdown", id = 0 }))
    dtls.server_step(server)
    server.channel:take_output()
    if state == "shutdown" then
        return server
    end

    error("new_server_in_state: unsupported state '" .. tostring(state) .. "'")
end

-- Force the handler for `method` to throw `message`, without needing to find
-- a real input that triggers a bug.
local function stub_handler_to_throw(server, method, message)
    server.handlers[method] = function()
        error(message)
    end
end

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
            name = "didSave notification while initialized publishes diagnostics",
            starting_state = "initialized",
            input = {
                method = "textDocument/didSave",
                params = { textDocument = { uri = ("file://%s/tests/custom.dts"):format(project_root) } },
            },
            expect_state = "initialized",
            expect_output = {
                {
                    method = "textDocument/publishDiagnostics",
                    params = {
                        uri = ("file://%s/tests/custom.dts"):format(project_root),
                        diagnostics = {},
                    },
                },
            },
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
                { method = "window/showMessage", params = { type = 1 } },
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

            local continues = dtls.server_step(server)

            assert.are.equal(case.expect_state, server.state)
            assert_output_matches(case.expect_output, parse_output(server.channel))
            assert(continues)
        end)
    end
end)

-- separate from the previous cases since all of the previous are expected to
-- continue while these are expected to exit
describe("exit notification", function()
    it("stops the loop and exits 0 after a proper shutdown", function()
        local server = new_server_in_state("shutdown")
        server.channel:push_input(frame({ method = "exit" }))

        local continues = dtls.server_step(server)

        assert.is_false(continues)
        assert.are.equal(0, server.exit_code)
    end)

    it("stops the loop and exits 1 without a prior shutdown", function()
        local server = new_server_in_state("initialized")
        server.channel:push_input(frame({ method = "exit" }))

        local continues = dtls.server_step(server)

        assert.is_false(continues)
        assert.are.equal(1, server.exit_code)
    end)
end)

describe("initialize captures the workspace root", function()
    local cases = {
        {
            name = "from workspaceFolders",
            params = {
                workspaceFolders = {
                    { uri = "file:///some/repo", name = "repo" },
                },
            },
            expect_workspace_root = "/some/repo",
        },
        {
            name = "from rootUri when workspaceFolders is absent",
            params = { rootUri = "file:///some/repo" },
            expect_workspace_root = "/some/repo",
        },
        {
            name = "prefers workspaceFolders over rootUri when both are present",
            params = {
                rootUri = "file:///some/other-repo",
                workspaceFolders = {
                    { uri = "file:///some/repo", name = "repo" },
                },
            },
            expect_workspace_root = "/some/repo",
        },
        {
            name = "is left unset when neither rootUri nor workspaceFolders is given",
            params = {},
            expect_workspace_root = nil,
        },
    }

    for _, case in ipairs(cases) do
        it("sets workspace_root " .. case.name, function()
            local server = dtls.new_server(dtls.new_memory_channel())
            server.channel:push_input(frame({ method = "initialize", id = 1, params = case.params }))

            local continues = dtls.server_step(server)

            assert.are.equal("initialized", server.state)
            assert.are.equal(case.expect_workspace_root, server.workspace_root)
            assert(continues)
        end)
    end
end)

describe("workspace/didChangeWorkspaceFolders notification", function()
    it("updates workspace_root to a newly added folder", function()
        local server = new_server_in_state("initialized")

        server.channel:push_input(frame({
            method = "workspace/didChangeWorkspaceFolders",
            params = {
                event = {
                    added = { { uri = "file:///some/repo", name = "repo" } },
                    removed = {},
                },
            },
        }))

        local continues = dtls.server_step(server)

        assert.are.equal("/some/repo", server.workspace_root)
        assert(continues)
    end)

    it("clears workspace_root when its folder is removed", function()
        local server = dtls.new_server(dtls.new_memory_channel())
        server.channel:push_input(frame({
            method = "initialize",
            id = 1,
            params = { workspaceFolders = { { uri = "file:///some/repo", name = "repo" } } },
        }))
        dtls.server_step(server)
        server.channel:take_output()

        server.channel:push_input(frame({
            method = "workspace/didChangeWorkspaceFolders",
            params = {
                event = {
                    added = {},
                    removed = { { uri = "file:///some/repo", name = "repo" } },
                },
            },
        }))

        dtls.server_step(server)

        assert.is_nil(server.workspace_root)
    end)
end)

it("publishes diagnostics when a document opens", function()
    local server = dtls.new_server(dtls.new_memory_channel())
    server.channel:push_input(frame({
        method = "initialize",
        id = 1,
        params = {
            workspaceFolders = {
                { uri = ("file://%s"):format(project_root), name = "repo" },
            },
        },
    }))
    dtls.server_step(server)
    server.channel:take_output()

    local uri = ("file://%s/tests/missing-closing-delimiters.dts"):format(project_root)
    server.channel:push_input(frame({
        method = "textDocument/didOpen",
        params = { textDocument = { uri = uri } },
    }))

    dtls.server_step(server)

    local output = parse_output(server.channel)
    assert.are.equal(2, #output)
    assert.are.equal("window/showMessage", output[1].method)
    assert.are.equal("textDocument/publishDiagnostics", output[2].method)
    assert.are.equal(uri, output[2].params.uri)
    assert.is_true(#output[2].params.diagnostics > 0)
end)

describe("out-of-tree devicetree with no .anakins-dtls", function()
    it("warns via showMessage on didOpen", function()
        local handle = io.popen("pwd")
        local cwd = handle:read("*l")
        handle:close()

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
        assert.are.equal(2, #output)
        assert.are.equal("window/showMessage", output[1].method)
        assert.are.equal(2, output[1].params.type)
        assert.are.equal(
            "Out-of-tree devicetree detected, but no .anakins-dtls was found.\n\n"
                .. "For Yocto run the following command to generate one:\n"
                .. "bitbake-getvar S -r virtual/kernel > .anakins-dtls\n\n"
                .. "For buildroot run the following command to generate one:\n"
                .. "make -s --no-print-directory printvars VARS=LINUX_DIR > .anakins-dtls\n",
            output[1].params.message
        )
        assert.are.equal("textDocument/publishDiagnostics", output[2].method)
        assert.are.equal(
            ("file://%s/tests/out-of-tree-no-config/one/path/to/devicetree.dts"):format(cwd),
            output[2].params.uri
        )
    end)
end)

it("requests open and save notifications without document content synchronization", function()
    local server = dtls.new_server(dtls.new_memory_channel())
    server.channel:push_input(frame({ method = "initialize", id = 1, params = {} }))

    dtls.server_step(server)

    local output = parse_output(server.channel)
    assert.same({
        openClose = true,
        change = 0,
        save = true,
    }, output[1].result.capabilities.textDocumentSync)
end)

describe("textDocument/hover", function()
    it("advertises hoverProvider in the initialize response capabilities", function()
        local server = dtls.new_server(dtls.new_memory_channel())
        server.channel:push_input(frame({ method = "initialize", id = 1, params = {} }))

        dtls.server_step(server)

        local output = parse_output(server.channel)
        assert.is_true(output[1].result.capabilities.hoverProvider)
    end)

    it("responds with hover markdown for a position on the root node", function()
        local handle = io.popen("pwd")
        local cwd = handle:read("*l")
        handle:close()

        local server = new_server_in_state("initialized")
        server.channel:push_input(frame({
            method = "textDocument/hover",
            id = 2,
            params = {
                textDocument = { uri = ("file://%s/tests/custom.dts"):format(cwd) },
                -- tests/custom.dts:15:1 in 1-based row/col is line 14, character 0
                -- in 0-based LSP position terms.
                position = { line = 14, character = 0 },
            },
        }))

        dtls.server_step(server)

        local output = parse_output(server.channel)
        assert.are.equal(2, output[1].id)
        assert.are.equal("markdown", output[1].result.contents.kind)
        assert.are.equal(
            [[
# Devicetree Specification:

## Path: /

The root node does not have a `node-name` or `unit-address`. It is identified by a forward slash (/).

All devicetrees shall have a root node and the following nodes shall be present at the root of all devicetrees:
-  One `/cpus` node
-  At least one `/memory` node

The devicetree has a single root node of which all other device nodes are descendants. The full path to the root node is `/`.]],
            output[1].result.contents.value
        )
    end)

    it("responds with a null result when there is no hover content for the position", function()
        local handle = io.popen("pwd")
        local cwd = handle:read("*l")
        handle:close()

        local server = new_server_in_state("initialized")
        server.channel:push_input(frame({
            method = "textDocument/hover",
            id = 3,
            params = {
                textDocument = { uri = ("file://%s/tests/custom.dts"):format(cwd) },
                position = { line = 0, character = 0 },
            },
        }))

        dtls.server_step(server)

        local output = parse_output(server.channel)
        assert.are.equal(3, output[1].id)
        assert.same(json.NULL, output[1].result)
    end)
end)

describe("textDocument/definition", function()
    it("advertises definitionProvider in the initialize response capabilities", function()
        local server = dtls.new_server(dtls.new_memory_channel())
        server.channel:push_input(frame({ method = "initialize", id = 1, params = {} }))

        dtls.server_step(server)

        local output = parse_output(server.channel)
        assert.is_true(output[1].result.capabilities.definitionProvider)
    end)

    it("responds with the location of a node label definition", function()
        local handle = io.popen("pwd")
        local cwd = handle:read("*l")
        handle:close()
        local file = ("%s/tests/in-tree/arch/arm64/boot/dts/freescale/custom.dts"):format(cwd)

        local server = new_server_in_state("initialized")
        server.channel:push_input(frame({
            method = "textDocument/definition",
            id = 4,
            params = {
                textDocument = { uri = "file://" .. file },
                position = { line = 75, character = 25 },
            },
        }))

        dtls.server_step(server)

        local output = parse_output(server.channel)
        assert.are.same({
            uri = "file://" .. file,
            range = {
                start = { line = 55, character = 4 },
                ["end"] = { line = 55, character = 13 },
            },
        }, output[1].result)
    end)

    it("responds with a null result outside a node label reference", function()
        local handle = io.popen("pwd")
        local cwd = handle:read("*l")
        handle:close()

        local server = new_server_in_state("initialized")
        server.channel:push_input(frame({
            method = "textDocument/definition",
            id = 5,
            params = {
                textDocument = { uri = ("file://%s/tests/custom.dts"):format(cwd) },
                position = { line = 0, character = 0 },
            },
        }))

        dtls.server_step(server)

        local output = parse_output(server.channel)
        assert.same(json.NULL, output[1].result)
    end)

    it("responds with the location of an included header macro definition", function()
        local handle = io.popen("pwd")
        local cwd = handle:read("*l")
        handle:close()
        local file = ("%s/tests/in-tree/arch/arm64/boot/dts/freescale/custom.dts"):format(cwd)

        local server = new_server_in_state("initialized")
        server.channel:push_input(frame({
            method = "textDocument/definition",
            id = 6,
            params = {
                textDocument = { uri = "file://" .. file },
                position = { line = 496, character = 29 },
            },
        }))

        dtls.server_step(server)

        local output = parse_output(server.channel)
        assert.are.same({
            uri = "file://" .. cwd .. "/tests/in-tree/include/dt-bindings/net/ti-dp83867.h",
            range = {
                start = { line = 51, character = 8 },
                ["end"] = { line = 51, character = 29 },
            },
        }, output[1].result)
    end)
end)

describe("textDocument/implementation", function()
    it("advertises implementationProvider in the initialize response capabilities", function()
        local server = dtls.new_server(dtls.new_memory_channel())
        server.channel:push_input(frame({ method = "initialize", id = 1, params = {} }))

        dtls.server_step(server)

        local output = parse_output(server.channel)
        assert.is_true(output[1].result.capabilities.implementationProvider)
    end)

    it("responds with the matching kernel driver's compatible entry", function()
        local handle = io.popen("pwd")
        local cwd = handle:read("*l")
        handle:close()
        local dts = ("%s/tests/in-tree/arch/arm64/boot/dts/freescale/imx91_93_common.dtsi"):format(cwd)
        local driver = ("%s/tests/in-tree/drivers/soc/imx/imx93-src.c"):format(cwd)

        local server = new_server_in_state("initialized")
        server.channel:push_input(frame({
            method = "textDocument/implementation",
            id = 6,
            params = {
                textDocument = { uri = "file://" .. dts },
                position = { line = 383, character = 24 },
            },
        }))

        dtls.server_step(server)

        local output = parse_output(server.channel)
        assert.are.same({
            uri = "file://" .. driver,
            range = {
                start = { line = 15, character = 18 },
                ["end"] = { line = 15, character = 31 },
            },
        }, output[1].result)
    end)

    it("responds with a null result outside a compatible string", function()
        local handle = io.popen("pwd")
        local cwd = handle:read("*l")
        handle:close()

        local server = new_server_in_state("initialized")
        server.channel:push_input(frame({
            method = "textDocument/implementation",
            id = 7,
            params = {
                textDocument = { uri = ("file://%s/tests/custom.dts"):format(cwd) },
                position = { line = 0, character = 0 },
            },
        }))

        dtls.server_step(server)

        local output = parse_output(server.channel)
        assert.same(json.NULL, output[1].result)
    end)
end)

describe("error handling", function()
    it("catches a Lua error thrown while handling a message and keeps running", function()
        local server = new_server_in_state("initialized")
        stub_handler_to_throw(server, "textDocument/didSave", "boom")

        server.channel:push_input(frame({
            method = "textDocument/didSave",
            params = { textDocument = { uri = "file:///custom.dts" } },
        }))

        local continues = dtls.server_step(server)

        assert(continues)
        assert.are.equal("initialized", server.state)

        local output = parse_output(server.channel)
        assert.are.equal(1, #output)
        assert.are.equal("window/showMessage", output[1].method)
        assert.are.equal(1, output[1].params.type)
        assert.matches("boom", output[1].params.message)
    end)

    it("still serves subsequent valid messages after a handler error", function()
        local server = new_server_in_state("initialized")
        stub_handler_to_throw(server, "textDocument/didSave", "boom")

        server.channel:push_input(frame({
            method = "textDocument/didSave",
            params = { textDocument = { uri = "file:///custom.dts" } },
        }))
        dtls.server_step(server)

        server.channel:push_input(frame({ method = "shutdown", id = 9 }))
        dtls.server_step(server)

        assert.are.equal("shutdown", server.state)
        local output = parse_output(server.channel)
        assert.are.equal(9, output[#output].id)
        assert.same(json.NULL, output[#output].result)
    end)

    it("reports a garbage/unparsable message via showMessage without crashing", function()
        local server = new_server_in_state("initialized")

        server.channel:push_input("not a valid Content-Length frame at all")

        local continues = dtls.server_step(server)

        assert(continues)
        local output = parse_output(server.channel)
        assert.are.equal("window/showMessage", output[1].method)
        assert.are.equal(1, output[1].params.type)
    end)
end)

it("handles a full initialize -> didSave -> shutdown -> exit session", function()
    local server = dtls.new_server(dtls.new_memory_channel())

    server.channel:push_input(frame({ method = "initialize", id = 1, params = {} }))
    server.channel:push_input(frame({ method = "initialized", params = {} }))
    server.channel:push_input(frame({
        method = "textDocument/didSave",
        params = { textDocument = { uri = ("file://%s/tests/custom.dts"):format(project_root) } },
    }))
    server.channel:push_input(frame({ method = "shutdown", id = 2 }))
    server.channel:push_input(frame({ method = "exit" }))

    dtls.server_run(server)

    local output = parse_output(server.channel)
    assert.are.equal(1, output[1].id)
    assert.truthy(output[1].result.capabilities)
    assert.are.equal("textDocument/publishDiagnostics", output[2].method)
    assert.same({}, output[2].params.diagnostics)
    assert.are.equal(2, output[3].id)
    assert.same(json.NULL, output[3].result)
    assert.are.equal(3, #output)
    assert.are.equal(0, server.exit_code)
end)

it("runs the real script end-to-end over real stdio", function()
    local handle = io.popen("pwd")
    local cwd = handle:read("*l")
    handle:close()

    local infile = os.tmpname()
    local outfile = os.tmpname()

    local input = io.open(infile, "w")
    input:write(frame({ method = "initialize", id = 1, params = {} }))
    input:write(frame({ method = "initialized", params = {} }))
    input:write(frame({
        method = "textDocument/didSave",
        params = { textDocument = { uri = ("file://%s/tests/missing-semicolons.dts"):format(cwd) } },
    }))
    input:write(frame({ method = "shutdown", id = 2 }))
    input:write(frame({ method = "exit" }))
    input:close()

    os.execute(("lua lua/anakins-dtls.lua < %q > %q"):format(infile, outfile))

    local output_handle = io.open(outfile, "r")
    local output = parse_output_string(output_handle:read("*a"))
    output_handle:close()
    os.remove(infile)
    os.remove(outfile)

    assert.are.equal(1, output[1].id)
    assert.truthy(output[1].result.capabilities)
    assert.are.equal("textDocument/publishDiagnostics", output[2].method)
    assert.are.equal(("file://%s/tests/missing-semicolons.dts"):format(cwd), output[2].params.uri)
    assert.same({
        range = {
            start = { line = 1, character = 24 },
            ["end"] = { line = 1, character = 24 },
        },
        severity = 1,
        source = "anakins-dtls",
        message = "Missing semicolon",
    }, output[2].params.diagnostics[1])
    assert.are.equal(4, #output[2].params.diagnostics)
    assert.are.equal(2, output[3].id)
    assert.same(json.NULL, output[3].result)
    assert.are.equal(3, #output)
end)

it("runs correctly even when invoked under a different file name, as when installed by Nix", function()
    local infile = os.tmpname()
    local outfile = os.tmpname()
    local renamed_script = os.tmpname()
    os.remove(renamed_script)

    local input = io.open(infile, "w")
    input:write(frame({ method = "initialize", id = 1, params = {} }))
    input:write(frame({ method = "shutdown", id = 2 }))
    input:write(frame({ method = "exit" }))
    input:close()

    os.execute(("cp lua/anakins-dtls.lua %q"):format(renamed_script))
    os.execute(("lua %q < %q > %q"):format(renamed_script, infile, outfile))

    local output_handle = io.open(outfile, "r")
    local output = parse_output_string(output_handle:read("*a"))
    output_handle:close()
    os.remove(infile)
    os.remove(outfile)
    os.remove(renamed_script)

    assert.are.equal(1, output[1].id)
    assert.truthy(output[1].result.capabilities)
    assert.are.equal(2, output[2].id)
    assert.same(json.NULL, output[2].result)
    assert.are.equal(2, #output)
end)

for _, flag in ipairs({ "--version", "-v" }) do
    it("reports the installed tag version and Git revision with " .. flag, function()
        local outfile = os.tmpname()

        os.execute(
            "ANAKINS_DTLS_VERSION=1.2.3 ANAKINS_DTLS_REVISION=abcdef0 "
                .. ("lua lua/anakins-dtls.lua %s > %q"):format(flag, outfile)
        )

        local output_handle = io.open(outfile, "r")
        local output = output_handle:read("*a")
        output_handle:close()
        os.remove(outfile)

        assert.are.equal("having a hoot and a holler\nanakins-dtls 1.2.3 (abcdef0)\n", output)
    end)
end
