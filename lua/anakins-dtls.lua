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

return M
