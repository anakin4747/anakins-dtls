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

-- Find the row/column bounds of the root ("/") node's opening and closing
-- braces by walking the file and tracking node depth via a brace stack.
local function find_root_bounds(file)
    local lines = read_lines(file)
    local stack = {}

    for row, line in ipairs(lines) do
        local col = 1
        while col <= #line do
            local char = line:sub(col, col)
            if char == "{" then
                local name = node_name_before_brace(line, col)
                stack[#stack + 1] = { name = name, open_row = row, open_col = col }
            elseif char == "}" then
                local entry = stack[#stack]
                stack[#stack] = nil
                if entry and entry.name == "/" then
                    return {
                        open_row = entry.open_row,
                        open_col = entry.open_col,
                        close_row = row,
                        close_col = col,
                    }
                end
            end
            col = col + 1
        end
    end

    return nil
end

function M.in_a_root_node(ctx)
    local bounds = find_root_bounds(ctx.file)
    if not bounds then
        return false
    end

    return ctx.row > bounds.open_row and ctx.row < bounds.close_row
end

function M.on_a_root_node(ctx)
    local bounds = find_root_bounds(ctx.file)
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

return M
