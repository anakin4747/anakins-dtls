#!/usr/bin/env lua

local M = {}

function M.greet()
    return "hello world"
end

--- Determine the directory this module lives in, and from there the
--- project's `tests` directory (used to resolve fixture files by
--- `ctx.cwd` / `ctx.file`).
local function tests_dir()
    local source = debug.getinfo(1, "S").source
    local script_path = source:match("^@(.*)$") or source
    local lua_dir = script_path:match("^(.*)/[^/]+$") or "."
    return lua_dir .. "/../tests"
end

--- Resolve the fixture file referenced by a context table into an
--- absolute-ish path that can be opened from disk.
local function resolve_path(ctx)
    return tests_dir() .. "/" .. ctx.cwd .. "/" .. ctx.file
end

--- Read all lines of the file referenced by `ctx` into an array.
local function read_lines(ctx)
    local lines = {}
    local path = resolve_path(ctx)
    local f = io.open(path, "r")
    if not f then
        return lines
    end
    for line in f:lines() do
        table.insert(lines, line)
    end
    f:close()
    return lines
end

--- Extract the node name from a line that opens a node, e.g.
--- "/ {" -> "/", "label: name {" -> "name", "name@addr {" -> "name".
local function node_name(line)
    local body = line:match("^%s*(.-)%s*{%s*$")
    if not body then
        return nil
    end

    local label_body = body:match(":%s*(.+)$")
    if label_body then
        body = label_body
    end

    local base = body:match("^([^@]+)@")
    if base then
        body = base
    end

    return body
end

--- Returns true if `line` opens a node (ends with an opening brace).
local function opens_node(line)
    return line:match("{%s*$") ~= nil
end

--- Returns true if `line` closes a node (e.g. "};").
local function closes_node(line)
    return line:match("^%s*};") ~= nil
end

--- Build a table mapping each line number to the stack of ancestor node
--- names that are active for that line (i.e. the node path a cursor on
--- that line would be nested inside, before that line itself is
--- processed).
local function build_node_stacks(lines)
    local stacks = {}
    local stack = {}

    for i, line in ipairs(lines) do
        local snapshot = {}
        for j, name in ipairs(stack) do
            snapshot[j] = name
        end
        stacks[i] = snapshot

        if closes_node(line) then
            table.remove(stack)
        elseif opens_node(line) then
            table.insert(stack, node_name(line))
        end
    end

    return stacks
end

local function stack_at(ctx)
    local lines = read_lines(ctx)
    local stacks = build_node_stacks(lines)
    return stacks[ctx.row] or {}
end

--- Returns true if the given context's row/col is somewhere inside the
--- devicetree root node ("/ { ... };").
function M.in_a_root_node(ctx)
    local stack = stack_at(ctx)
    return #stack >= 1 and stack[1] == "/"
end

--- Returns true if the given context's row/col sits directly on a
--- node's opening or closing brace (including adjacent whitespace or a
--- trailing semicolon).
function M.on_a_root_node(ctx)
    local lines = read_lines(ctx)
    local line = lines[ctx.row]
    if not line then
        return false
    end

    local col = ctx.col
    if col < 1 or col > #line then
        return false
    end

    local ch = line:sub(col, col)
    if ch == "{" or ch == "}" then
        return true
    end

    if ch == " " and line:sub(col + 1, col + 1) == "{" then
        return true
    end

    if ch == ";" and line:sub(col - 1, col - 1) == "}" then
        return true
    end

    return false
end

--- Returns true if the given context's row/col is inside an /aliases
--- node that is a direct child of the devicetree root node.
function M.in_an_aliases_node(ctx)
    local stack = stack_at(ctx)
    return #stack == 2 and stack[1] == "/" and stack[2] == "aliases"
end

if ... == nil then
    print(M.greet())
else
    return M
end
