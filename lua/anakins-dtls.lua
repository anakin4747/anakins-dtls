#!/usr/bin/env lua

package.path = "./lua/?.lua;" .. package.path
local json = require("json")

local M = {}

local function read_lines(file)
    local handle, err = io.open(file, "r")
    if not handle then
        error(err)
    end

    local lines = {}
    for line in handle:lines() do
        lines[#lines + 1] = line
    end
    handle:close()

    return lines
end

-- Determine the node name that precedes a '{' found at `open_col` on `line`.
local function node_name_before_brace(line, open_col)
    local before = line:sub(1, open_col - 1):match("^%s*(.-)%s*$")
    local last_token = before:match("(%S+)%s*$") or before
    local after_colon = last_token:match(":([^:]+)$")
    return after_colon or last_token
end

-- Check whether `name` satisfies `matcher`, which is either an exact node
-- name or a predicate function that receives the name and returns a boolean.
local function name_matches(name, matcher)
    if type(matcher) == "function" then
        return matcher(name)
    end

    return name == matcher
end

-- Check whether `stack` (an array of node names, from outermost to
-- innermost) matches `path` (an array of exact names and/or predicates).
local function path_matches(stack, path)
    if #stack ~= #path then
        return false
    end

    for i, matcher in ipairs(path) do
        if not name_matches(stack[i], matcher) then
            return false
        end
    end

    return true
end

-- Build a stack-matching function that matches a node found anywhere in the
-- file (regardless of depth or ancestry) whose own name satisfies `matcher`.
local function any_depth(matcher)
    return function(stack)
        return name_matches(stack[#stack], matcher)
    end
end

-- Find the row/column bounds of the opening and closing braces of every node
-- matched by `criteria`: either a path (an array of exact names and/or
-- predicates, e.g. { "/", "aliases" }) or a stack-matching function (see
-- `any_depth`), by walking the file and tracking node depth via a name
-- stack.
local function find_all_node_bounds(file, criteria)
    local matches = criteria
    if type(criteria) == "table" then
        matches = function(stack)
            return path_matches(stack, criteria)
        end
    end

    local lines = read_lines(file)
    local stack = {}
    local pending_by_depth = {}
    local results = {}

    for row, line in ipairs(lines) do
        local col = 1
        while col <= #line do
            local char = line:sub(col, col)
            if char == "{" then
                local name = node_name_before_brace(line, col)
                stack[#stack + 1] = name
                if matches(stack) then
                    pending_by_depth[#stack] = { open_row = row, open_col = col }
                end
            elseif char == "}" then
                local depth = #stack
                local pending = pending_by_depth[depth]
                if pending then
                    pending.close_row = row
                    pending.close_col = col
                    results[#results + 1] = pending
                    pending_by_depth[depth] = nil
                end
                stack[#stack] = nil
            end
            col = col + 1
        end
    end

    return results
end

local function in_node(ctx, criteria)
    for _, bounds in ipairs(find_all_node_bounds(ctx.file, criteria)) do
        if ctx.row > bounds.open_row and ctx.row < bounds.close_row then
            return true
        end
    end

    return false
end

local function on_node(ctx, criteria)
    for _, bounds in ipairs(find_all_node_bounds(ctx.file, criteria)) do
        if ctx.row == bounds.open_row then
            if ctx.col >= 1 and ctx.col <= bounds.open_col then
                return true
            end
        elseif ctx.row == bounds.close_row then
            if ctx.col >= bounds.close_col and ctx.col <= bounds.close_col + 1 then
                return true
            end
        end
    end

    return false
end

function M.in_a_root_node(ctx)
    return in_node(ctx, { "/" })
end

function M.on_a_root_node(ctx)
    return on_node(ctx, { "/" })
end

function M.in_an_aliases_node(ctx)
    return in_node(ctx, { "/", "aliases" })
end

function M.on_an_aliases_node(ctx)
    return on_node(ctx, { "/", "aliases" })
end

local function is_memory_name(name)
    return name == "memory" or name:match("^memory@") ~= nil
end

function M.in_a_memory_node(ctx)
    return in_node(ctx, { "/", is_memory_name })
end

function M.on_a_memory_node(ctx)
    return on_node(ctx, { "/", is_memory_name })
end

function M.in_a_chosen_node(ctx)
    return in_node(ctx, { "/", "chosen" })
end

function M.on_a_chosen_node(ctx)
    return on_node(ctx, { "/", "chosen" })
end

function M.in_a_cpus_node(ctx)
    return in_node(ctx, { "/", "cpus" })
end

function M.on_a_cpus_node(ctx)
    return on_node(ctx, { "/", "cpus" })
end

local function is_cpu_name(name)
    return name == "cpu" or name:match("^cpu@") ~= nil
end

function M.in_a_cpu_node(ctx)
    return in_node(ctx, { "/", "cpus", is_cpu_name })
end

function M.on_a_cpu_node(ctx)
    return on_node(ctx, { "/", "cpus", is_cpu_name })
end

local function is_cache_name(name)
    return name:match("cache") ~= nil
end

function M.in_a_cache_node(ctx)
    return in_node(ctx, any_depth(is_cache_name))
end

function M.on_a_cache_node(ctx)
    return on_node(ctx, any_depth(is_cache_name))
end

function M.in_a_reserved_memory_node(ctx)
    return in_node(ctx, { "/", "reserved-memory" })
end

function M.on_a_reserved_memory_node(ctx)
    return on_node(ctx, { "/", "reserved-memory" })
end

local function any_name()
    return true
end

function M.in_a_reserved_memory_region_node(ctx)
    return in_node(ctx, { "/", "reserved-memory", any_name })
end

function M.on_a_reserved_memory_region_node(ctx)
    return on_node(ctx, { "/", "reserved-memory", any_name })
end

local function is_top_level_stack(stack)
    return #stack == 1
end

function M.in_top_level(ctx)
    return not in_node(ctx, is_top_level_stack)
end

function M.on_a_label_definition(ctx)
    local lines = read_lines(ctx.file)
    local line = lines[ctx.row]
    if not line then
        return false
    end

    local leading, label = line:match("^(%s*)([%w_]+):")
    if not label then
        return false
    end

    local start_col = #leading + 1
    local colon_col = start_col + #label

    return ctx.col >= start_col and ctx.col <= colon_col
end

function M.on_a_label_reference(ctx)
    local lines = read_lines(ctx.file)
    local line = lines[ctx.row]
    if not line then
        return false
    end

    local search_from = 1
    while true do
        local amp_col = line:find("&", search_from)
        if not amp_col then
            return false
        end

        local end_col = amp_col
        while end_col + 1 <= #line and line:sub(end_col + 1, end_col + 1):match("[%w_]") do
            end_col = end_col + 1
        end

        if ctx.col >= amp_col and ctx.col <= end_col then
            return true
        end

        search_from = amp_col + 1
    end
end

local root_node_markdown = [[
# Devicetree Specification:

The root node does not have a `node-name` or `unit-address`. It is identified by a forward slash (/).

All devicetrees shall have a root node and the following nodes shall be present at the root of all devicetrees:
-  One `/cpus` node
-  At least one `/memory` node

The devicetree has a single root node of which all other device nodes are descendants. The full path to the root node is `/`.]] -- luacheck: ignore 631

local model_property_markdown = [[
# Devicetree Specification:

## Property Name: model

## Path: /model

## Usage: Required

## Value Type: `<string>`

## Definition:

Specifies a string that uniquely identifies the model of the system board. The recommended format is "manufacturer,model-number".

## Type Definition:

`<string>` - Strings are printable and null-terminated.

Example: the string `"hello"` would be represented in memory as:

```
  address  68  'h'
address+1  65  'e'
address+2  6C  'l'
address+3  6C  'l'
address+4  6F  'o'
address+5  00  '\0'
```]] -- luacheck: ignore 631

local compatible_property_markdown = [[
# Devicetree Specification:

## Property Name: compatible

## Path: /compatible

## Usage: Required

## Value Type: `<stringlist>`

## Definition:

Specifies a list of platform architectures with which this platform is compatible. This property can be used by operating systems in selecting platform specific code. The recommended form of the property value is:

`"manufacturer,model"`

For example:

```dts
compatible = "fsl,mpc8572ds"
```

## Type Definition:

`<stringlist>` - A list of `<string>` values concatenated together.

Example: The string list `"hello", "world"` would be represented in memory as:

```
   address  68  'h'
 address+1  65  'e'
 address+2  6C  'l'
 address+3  6C  'l'
 address+4  6F  'o'
 address+5  00  '\0'
 address+6  77  'w'
 address+7  6f  'o'
 address+8  72  'r'
 address+9  6C  'l'
address+10  64  'd'
address+11  00  '\0'
```]] -- luacheck: ignore 631

local function on_a_property_name(ctx, prop_name)
    local lines = read_lines(ctx.file)
    local line = lines[ctx.row]
    if not line then
        return false
    end

    local leading, name = line:match("^(%s*)([%w,._%-#]+)%s*=")
    if name ~= prop_name then
        return false
    end

    local start_col = #leading + 1
    local end_col = start_col + #name - 1

    return ctx.col >= start_col and ctx.col <= end_col
end

function M.hover(ctx)
    if M.on_a_root_node(ctx) then
        return root_node_markdown
    end

    if M.in_a_root_node(ctx) and on_a_property_name(ctx, "model") then
        return model_property_markdown
    end

    if M.in_a_root_node(ctx) and on_a_property_name(ctx, "compatible") then
        return compatible_property_markdown
    end
end

-------------------------------------------------------------------------------
-- Main loop / JSON-RPC transport
-------------------------------------------------------------------------------

-- An in-memory transport used by tests: `push_input` feeds raw bytes as if
-- they had arrived over stdio, `take_output` drains and clears whatever has
-- been written so far, and `read_message`/`write_message` implement the
-- `Content-Length` framing used by both this and the real stdio transport.
function M.new_memory_channel()
    local channel = { input = "", output = "" }

    function channel:push_input(bytes)
        self.input = self.input .. bytes
    end

    function channel:take_output()
        local out = self.output
        self.output = ""
        return out
    end

    function channel:read_message()
        if #self.input == 0 then
            return nil, "eof"
        end

        local header_end = self.input:find("\r\n\r\n", 1, true)
        if not header_end then
            self.input = ""
            return nil, "malformed message: missing header terminator"
        end

        local header = self.input:sub(1, header_end - 1)
        local length = tonumber(header:match("Content%-Length:%s*(%d+)"))
        if not length then
            self.input = self.input:sub(header_end + 4)
            return nil, "malformed message: missing Content-Length header"
        end

        local body_start = header_end + 4
        local body = self.input:sub(body_start, body_start + length - 1)
        self.input = self.input:sub(body_start + length)
        return body
    end

    function channel:write_message(body)
        self.output = self.output .. ("Content-Length: %d\r\n\r\n%s"):format(#body, body)
    end

    return channel
end

-- The real transport used when this file is run as the language server
-- itself: reads framed messages from stdin and writes framed responses to
-- stdout.
local function new_stdio_channel()
    local channel = {}

    function channel:read_message() -- luacheck: ignore 212
        local length
        local header = io.read("*l")
        if not header then
            return nil, "eof"
        end
        header = header:gsub("\r$", "")

        while header and header ~= "" do
            local candidate = tonumber(header:match("Content%-Length:%s*(%d+)"))
            if candidate then
                length = candidate
            end
            header = io.read("*l")
            if header then
                header = header:gsub("\r$", "")
            end
        end

        if not length then
            return nil, "malformed message: missing Content-Length header"
        end

        local body = io.read(length)
        if not body then
            return nil, "eof"
        end

        return body
    end

    function channel:write_message(body) -- luacheck: ignore 212
        io.write(("Content-Length: %d\r\n\r\n%s"):format(#body, body))
        io.flush()
    end

    return channel
end

local function send_response(server, id, result)
    server.channel:write_message(json.encode({ jsonrpc = "2.0", id = id, result = result }))
end

local function send_error(server, id, code, message)
    server.channel:write_message(json.encode({
        jsonrpc = "2.0",
        id = id,
        error = { code = code, message = message },
    }))
end

local function send_notification(server, method, params)
    server.channel:write_message(json.encode({ jsonrpc = "2.0", method = method, params = params }))
end

-- Strip the `file://` scheme off a URI, leaving a plain filesystem path.
local function uri_to_path(uri)
    return uri and uri:match("^file://(.*)$")
end

-- Determine the workspace root from `initialize` params, preferring
-- `workspaceFolders` over `rootUri` when both are present.
local function workspace_root_from_params(params)
    local folders = params.workspaceFolders
    if folders and folders[1] then
        return uri_to_path(folders[1].uri)
    end

    if params.rootUri then
        return uri_to_path(params.rootUri)
    end

    return nil
end

-- Default request/notification handlers, copied into each new server so
-- that tests can stub individual entries per-instance without affecting
-- other servers.
local default_handlers = {}

default_handlers["initialize"] = function(server, msg)
    if server.state ~= "uninitialized" then
        send_error(server, msg.id, -32002, "Server is already initialized")
        return
    end

    local params = msg.params or {}
    server.workspace_root = workspace_root_from_params(params)
    server.state = "initialized"
    send_response(server, msg.id, { capabilities = { textDocumentSync = 1 } })
end

default_handlers["initialized"] = function(_, _) end

default_handlers["shutdown"] = function(server, msg)
    if server.state ~= "initialized" then
        send_error(server, msg.id, -32600, "Cannot shut down: server is not initialized")
        return
    end

    server.state = "shutdown"
    send_response(server, msg.id, json.NULL)
end

default_handlers["textDocument/didSave"] = function(_, _) end

default_handlers["workspace/didChangeWorkspaceFolders"] = function(server, msg)
    local event = (msg.params or {}).event or {}

    for _, folder in ipairs(event.added or {}) do
        server.workspace_root = uri_to_path(folder.uri)
    end

    for _, folder in ipairs(event.removed or {}) do
        if server.workspace_root == uri_to_path(folder.uri) then
            server.workspace_root = nil
        end
    end
end

-- Create a fresh, uninitialized server bound to `channel`. `handlers` is a
-- shallow per-instance copy of `default_handlers` so tests can stub out
-- individual method handlers without disturbing other server instances.
function M.new_server(channel)
    local handlers = {}
    for method, handler in pairs(default_handlers) do
        handlers[method] = handler
    end

    return {
        channel = channel,
        state = "uninitialized",
        handlers = handlers,
        workspace_root = nil,
        exit_code = nil,
    }
end

-- Read and handle exactly one message from `server.channel`. Returns
-- `true` if the main loop should keep running, or `false` once an `exit`
-- notification has been processed (with `server.exit_code` set).
function M.server_step(server)
    local body, read_err = server.channel:read_message()
    if not body then
        if read_err == "eof" then
            server.exit_code = server.exit_code or 0
            return false
        end

        send_notification(server, "window/showMessage", {
            type = 1,
            message = "Failed to read message: " .. tostring(read_err),
        })
        return true
    end

    local ok, msg = pcall(json.decode, body)
    if not ok then
        send_notification(server, "window/showMessage", {
            type = 1,
            message = "Failed to parse message: " .. tostring(msg),
        })
        return true
    end

    if msg.method == "exit" then
        server.exit_code = (server.state == "shutdown") and 0 or 1
        return false
    end

    if server.state == "uninitialized" and msg.method ~= "initialize" then
        if msg.id ~= nil then
            send_error(server, msg.id, -32002, "Server is not initialized")
        else
            send_notification(server, "window/showMessage", {
                type = 1,
                message = "Server is not initialized; ignoring notification '" .. tostring(msg.method) .. "'",
            })
        end
        return true
    end

    local handler = server.handlers[msg.method]
    if not handler then
        if msg.id ~= nil then
            send_error(server, msg.id, -32601, "Method not found: " .. tostring(msg.method))
        end
        return true
    end

    local success, handler_err = pcall(handler, server, msg)
    if not success then
        send_notification(server, "window/showMessage", {
            type = 1,
            message = "Error handling '" .. tostring(msg.method) .. "': " .. tostring(handler_err),
        })
    end

    return true
end

-- Run `server_step` in a loop until an `exit` notification stops it.
function M.server_run(server)
    while M.server_step(server) do
    end
end

-- When invoked directly as a script (rather than `require`d by tests), run
-- the language server over real stdio.
local function running_as_main_script()
    return arg ~= nil and arg[0] ~= nil and arg[0]:match("anakins%-dtls%.lua$") ~= nil
end

if running_as_main_script() then
    local server = M.new_server(new_stdio_channel())
    M.server_run(server)
    os.exit(server.exit_code or 0)
end

return M
