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

-- Check whether `stack` (an array of node names, from outermost to
-- innermost) exactly matches `path`.
local function path_matches(stack, path)
    if #stack ~= #path then
        return false
    end

    for i, name in ipairs(path) do
        if stack[i] ~= name then
            return false
        end
    end

    return true
end

-- Find the row/column bounds of the opening and closing braces of the node
-- addressed by `path` (an array of node names, e.g. { "/", "aliases" }), by
-- walking the file and tracking node depth via a name stack.
local function find_node_bounds(file, path)
    local lines = read_lines(file)
    local stack = {}
    local pending

    for row, line in ipairs(lines) do
        local col = 1
        while col <= #line do
            local char = line:sub(col, col)
            if char == "{" then
                local name = node_name_before_brace(line, col)
                stack[#stack + 1] = name
                if not pending and path_matches(stack, path) then
                    pending = { open_row = row, open_col = col, depth = #stack }
                end
            elseif char == "}" then
                if pending and #stack == pending.depth then
                    pending.close_row = row
                    pending.close_col = col
                    return pending
                end
                stack[#stack] = nil
            end
            col = col + 1
        end
    end

    return nil
end

local function in_node(ctx, path)
    local bounds = find_node_bounds(ctx.file, path)
    if not bounds then
        return false
    end

    return ctx.row > bounds.open_row and ctx.row < bounds.close_row
end

local function on_node(ctx, path)
    local bounds = find_node_bounds(ctx.file, path)
    if not bounds then
        return false
    end

    if ctx.row == bounds.open_row then
        return ctx.col >= 1 and ctx.col <= bounds.open_col
    end

    if ctx.row == bounds.close_row then
        return ctx.col >= bounds.close_col and ctx.col <= bounds.close_col + 1
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

return M
