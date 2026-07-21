#!/usr/bin/env lua

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

return M
