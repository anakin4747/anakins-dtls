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

-- Find the row/column bounds of the opening and closing braces of every node
-- addressed by `path` (an array of exact names and/or predicates, e.g.
-- { "/", "aliases" }), by walking the file and tracking node depth via a
-- name stack.
local function find_all_node_bounds(file, path)
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
                if path_matches(stack, path) then
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

local function in_node(ctx, path)
    for _, bounds in ipairs(find_all_node_bounds(ctx.file, path)) do
        if ctx.row > bounds.open_row and ctx.row < bounds.close_row then
            return true
        end
    end

    return false
end

local function on_node(ctx, path)
    for _, bounds in ipairs(find_all_node_bounds(ctx.file, path)) do
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

return M
