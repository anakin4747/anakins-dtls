#!/usr/bin/env lua

--- {{{ json.lua section
--
-- json.lua
--
-- Copyright (c) 2020 rxi
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy of
-- this software and associated documentation files (the "Software"), to deal in
-- the Software without restriction, including without limitation the rights to
-- use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
-- of the Software, and to permit persons to whom the Software is furnished to do
-- so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
--

local json = { _version = "0.1.2" }

-- Sentinel used to represent the JSON `null` literal, distinguishable from
-- Lua's `nil` so that object keys with a `null` value survive a decode
-- round-trip instead of being silently dropped from the resulting table.
json.NULL = setmetatable({}, {
    __tostring = function()
        return "null"
    end,
})

-------------------------------------------------------------------------------
-- Encode
-------------------------------------------------------------------------------

-- Marker metatable used to disambiguate an empty table that should be
-- encoded as `[]` rather than the default `{}` (see `json.array`).
local array_mt = {}

-- Tag `t` (or a new table if `t` is omitted) so that `json.encode` treats it
-- as an array even when it is empty. This resolves the ambiguity between an
-- empty JSON object and an empty JSON array, since an empty Lua table alone
-- cannot convey that distinction.
function json.array(t)
    return setmetatable(t or {}, array_mt)
end

local encode

local escape_char_map = {
    ["\\"] = "\\",
    ['"'] = '"',
    ["\b"] = "b",
    ["\f"] = "f",
    ["\n"] = "n",
    ["\r"] = "r",
    ["\t"] = "t",
}

local escape_char_map_inv = { ["/"] = "/" }
for k, v in pairs(escape_char_map) do
    escape_char_map_inv[v] = k
end

local function escape_char(c)
    return "\\" .. (escape_char_map[c] or string.format("u%04x", c:byte()))
end

local function encode_nil(_)
    return "null"
end

local function encode_table(val, stack)
    local res = {}
    stack = stack or {}

    -- Circular reference?
    if stack[val] then
        error("circular reference")
    end

    stack[val] = true

    if next(val) == nil then
        -- Ambiguous empty table: default to an empty object, unless it was
        -- explicitly tagged as an array via `json.array`.
        stack[val] = nil
        if getmetatable(val) == array_mt then
            return "[]"
        end
        return "{}"
    elseif rawget(val, 1) ~= nil then
        -- Treat as array -- check keys are valid and it is not sparse
        local n = 0
        for k in pairs(val) do
            if type(k) ~= "number" then
                error("invalid table: mixed or invalid key types")
            end
            n = n + 1
        end
        if n ~= #val then
            error("invalid table: sparse array")
        end
        -- Encode
        for _, v in ipairs(val) do
            table.insert(res, encode(v, stack))
        end
        stack[val] = nil
        return "[" .. table.concat(res, ",") .. "]"
    else
        -- Treat as an object
        for k, v in pairs(val) do
            if type(k) ~= "string" then
                error("invalid table: mixed or invalid key types")
            end
            table.insert(res, encode(k, stack) .. ":" .. encode(v, stack))
        end
        stack[val] = nil
        return "{" .. table.concat(res, ",") .. "}"
    end
end

local function encode_string(val)
    return '"' .. val:gsub('[%z\1-\31\\"]', escape_char) .. '"'
end

local function encode_number(val)
    -- Check for NaN, -inf and inf
    if val ~= val or val <= -math.huge or val >= math.huge then
        error("unexpected number value '" .. tostring(val) .. "'")
    end
    return string.format("%.14g", val)
end

local type_func_map = {
    ["nil"] = encode_nil,
    ["table"] = encode_table,
    ["string"] = encode_string,
    ["number"] = encode_number,
    ["boolean"] = tostring,
}

encode = function(val, stack)
    if val == json.NULL then
        return "null"
    end

    local t = type(val)
    local f = type_func_map[t]
    if f then
        return f(val, stack)
    end
    error("unexpected type '" .. t .. "'")
end

function json.encode(val)
    return (encode(val))
end

-------------------------------------------------------------------------------
-- Decode
-------------------------------------------------------------------------------

local parse

local function create_set(...)
    local res = {}
    for i = 1, select("#", ...) do
        res[select(i, ...)] = true
    end
    return res
end

local space_chars = create_set(" ", "\t", "\r", "\n")
local delim_chars = create_set(" ", "\t", "\r", "\n", "]", "}", ",")
local escape_chars = create_set("\\", "/", '"', "b", "f", "n", "r", "t", "u")
local literals = create_set("true", "false", "null")

local literal_map = {
    ["true"] = true,
    ["false"] = false,
    ["null"] = json.NULL,
}

local function next_char(str, idx, set, negate)
    for i = idx, #str do
        if set[str:sub(i, i)] ~= negate then
            return i
        end
    end
    return #str + 1
end

local function decode_error(str, idx, msg)
    local line_count = 1
    local col_count = 1
    for i = 1, idx - 1 do
        col_count = col_count + 1
        if str:sub(i, i) == "\n" then
            line_count = line_count + 1
            col_count = 1
        end
    end
    error(string.format("%s at line %d col %d", msg, line_count, col_count))
end

local function codepoint_to_utf8(n)
    -- http://scripts.sil.org/cms/scripts/page.php?site_id=nrsi&id=iws-appendixa
    local f = math.floor
    if n <= 0x7f then
        return string.char(n)
    elseif n <= 0x7ff then
        return string.char(f(n / 64) + 192, n % 64 + 128)
    elseif n <= 0xffff then
        return string.char(f(n / 4096) + 224, f(n % 4096 / 64) + 128, n % 64 + 128)
    elseif n <= 0x10ffff then
        return string.char(f(n / 262144) + 240, f(n % 262144 / 4096) + 128, f(n % 4096 / 64) + 128, n % 64 + 128)
    end
    error(string.format("invalid unicode codepoint '%x'", n))
end

local function parse_unicode_escape(s)
    local n1 = tonumber(s:sub(1, 4), 16)
    local n2 = tonumber(s:sub(7, 10), 16)
    -- Surrogate pair?
    if n2 then
        return codepoint_to_utf8((n1 - 0xd800) * 0x400 + (n2 - 0xdc00) + 0x10000)
    else
        return codepoint_to_utf8(n1)
    end
end

local function parse_string(str, i)
    local res = ""
    local j = i + 1
    local k = j

    while j <= #str do
        local x = str:byte(j)

        if x < 32 then
            decode_error(str, j, "control character in string")
        elseif x == 92 then -- `\`: Escape
            res = res .. str:sub(k, j - 1)
            j = j + 1
            local c = str:sub(j, j)
            if c == "u" then
                local hex = str:match("^[dD][89aAbB]%x%x\\u%x%x%x%x", j + 1)
                    or str:match("^%x%x%x%x", j + 1)
                    or decode_error(str, j - 1, "invalid unicode escape in string")
                res = res .. parse_unicode_escape(hex)
                j = j + #hex
            else
                if not escape_chars[c] then
                    decode_error(str, j - 1, "invalid escape char '" .. c .. "' in string")
                end
                res = res .. escape_char_map_inv[c]
            end
            k = j + 1
        elseif x == 34 then -- `"`: End of string
            res = res .. str:sub(k, j - 1)
            return res, j + 1
        end

        j = j + 1
    end

    decode_error(str, i, "expected closing quote for string")
end

local function parse_number(str, i)
    local x = next_char(str, i, delim_chars)
    local s = str:sub(i, x - 1)
    local n = tonumber(s)
    if not n then
        decode_error(str, i, "invalid number '" .. s .. "'")
    end
    return n, x
end

local function parse_literal(str, i)
    local x = next_char(str, i, delim_chars)
    local word = str:sub(i, x - 1)
    if not literals[word] then
        decode_error(str, i, "invalid literal '" .. word .. "'")
    end
    return literal_map[word], x
end

local function parse_array(str, i)
    local res = {}
    local n = 1
    i = i + 1
    while 1 do
        local x
        i = next_char(str, i, space_chars, true)
        -- Empty / end of array?
        if str:sub(i, i) == "]" then
            i = i + 1
            break
        end
        -- Read token
        x, i = parse(str, i)
        res[n] = x
        n = n + 1
        -- Next token
        i = next_char(str, i, space_chars, true)
        local chr = str:sub(i, i)
        i = i + 1
        if chr == "]" then
            break
        end
        if chr ~= "," then
            decode_error(str, i, "expected ']' or ','")
        end
    end
    return res, i
end

local function parse_object(str, i)
    local res = {}
    i = i + 1
    while 1 do
        local key, val
        i = next_char(str, i, space_chars, true)
        -- Empty / end of object?
        if str:sub(i, i) == "}" then
            i = i + 1
            break
        end
        -- Read key
        if str:sub(i, i) ~= '"' then
            decode_error(str, i, "expected string for key")
        end
        key, i = parse(str, i)
        -- Read ':' delimiter
        i = next_char(str, i, space_chars, true)
        if str:sub(i, i) ~= ":" then
            decode_error(str, i, "expected ':' after key")
        end
        i = next_char(str, i + 1, space_chars, true)
        -- Read value
        val, i = parse(str, i)
        -- Set
        res[key] = val
        -- Next token
        i = next_char(str, i, space_chars, true)
        local chr = str:sub(i, i)
        i = i + 1
        if chr == "}" then
            break
        end
        if chr ~= "," then
            decode_error(str, i, "expected '}' or ','")
        end
    end
    return res, i
end

local char_func_map = {
    ['"'] = parse_string,
    ["0"] = parse_number,
    ["1"] = parse_number,
    ["2"] = parse_number,
    ["3"] = parse_number,
    ["4"] = parse_number,
    ["5"] = parse_number,
    ["6"] = parse_number,
    ["7"] = parse_number,
    ["8"] = parse_number,
    ["9"] = parse_number,
    ["-"] = parse_number,
    ["t"] = parse_literal,
    ["f"] = parse_literal,
    ["n"] = parse_literal,
    ["["] = parse_array,
    ["{"] = parse_object,
}

parse = function(str, idx)
    local chr = str:sub(idx, idx)
    local f = char_func_map[chr]
    if f then
        return f(str, idx)
    end
    decode_error(str, idx, "unexpected character '" .. chr .. "'")
end

function json.decode(str)
    if type(str) ~= "string" then
        error("expected argument of type string, got " .. type(str))
    end
    local res, idx = parse(str, next_char(str, 1, space_chars, true))
    idx = next_char(str, idx, space_chars, true)
    if idx <= #str then
        decode_error(str, idx, "trailing garbage")
    end
    return res
end

--- }}} end of json.lua section

local M = {}
M.json = json

function M.dedent(text)
    text = text:gsub("^\n", "")

    local indent
    for line in text:gmatch("[^\n]*") do
        if line:match("%S") then
            local line_indent = line:match("^%s*")
            if indent == nil or #line_indent < #indent then
                indent = line_indent
            end
        end
    end

    if indent and #indent > 0 then
        text = text:gsub("\n" .. indent, "\n")
        text = text:gsub("^" .. indent, "")
    end

    return (text:gsub("%s+$", ""))
end

local type_definitions = {
    empty = [[`<empty>` - Value is empty. Used for conveying true-false information, when the presence or absence of the property itself is sufficiently descriptive.]],
    u32 = M.dedent([[
        `<u32>` - A 32-bit integer in big-endian format.

        Example: the 32-bit value 0x11223344 would be represented in memory as:

        ```
          address  11
        address+1  22
        address+2  33
        address+3  44
        ```]]),
    u64 = M.dedent([[
        `<u64>` - Represents a 64-bit integer in big-endian format. Consists of two `<u32>` values where the first value contains the most significant bits of the integer and the second value contains the least significant bits.

        Example: the 64-bit value 0x1122334455667788 would be represented as two cells as: `<0x11223344 0x55667788>`.

        The value would be represented in memory as:

        ```
          address  11
        address+1  22
        address+2  33
        address+3  44
        address+4  55
        address+5  66
        address+6  77
        address+7  88
        ```]]),
    string = M.dedent([[
        `<string>` - Strings are printable and null-terminated.

        Example: the string "hello" would be represented in memory as:

        ```
          address  68  'h'
        address+1  65  'e'
        address+2  6C  'l'
        address+3  6C  'l'
        address+4  6F  'o'
        address+5  00  '\0'
        ```]]),
    prop_encoded_array = [[`<prop-encoded-array>` - Format is specific to the property. See the property definition.]],
    phandle = [[`<phandle>` - A `<u32>` value. A *phandle* value is a way to reference another node in the devicetree. Any node that can be referenced defines a phandle property with a unique ``<u32>`` value. That number is used for the value of properties with a phandle value type.]],
    stringlist = M.dedent([[
        `<stringlist>` - A list of `<string>` values concatenated together.

        Example: The string list "hello","world" would be represented in memory as:

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
        ```]]),
}

function M.get_type_definition(name)
    return "\n\n## Type Definition:\n\n" .. type_definitions[name]
end

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
                    pending_by_depth[#stack] = {
                        open_row = row,
                        open_col = col,
                        start_col = line:find("%S"),
                    }
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
            if ctx.col >= bounds.start_col and ctx.col <= bounds.open_col then
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

local aliases_node_markdown = [[
# Devicetree Specification:

## `/aliases` node

A devicetree may have an aliases node (`/aliases`) that defines one or more alias properties. The alias node shall be at the root of the devicetree and have the node name `/aliases`.

Each property of the `/aliases` node defines an alias. The property name specifies the alias name. The property value specifies the full path to a node in the devicetree. For example, the property serial0 = `"/simple-bus@fe000000/serial@llc500"` defines the alias `serial0`.

Alias names shall be lowercase text strings of 1 to 31 characters from the following set of characters.

## Valid characters for alias names

| Character | Description |
| --- | --- |
| 0-9 | digit |
| a-z | lowercase letter |
| - | dash |

An alias value is a device path and is encoded as a string. The value represents the full path to a node, but the path does not need to refer to a leaf node.

A client program may use an alias property name to refer to a full device path as all or part of its string value. A client program, when considering a string as a device path, shall detect and use the alias.

## Example

```dts
aliases {
    serial0 = "/simple-bus@fe000000/serial@llc500";
    ethernet0 = "/simple-bus@fe000000/ethernet@31c000";
};
```

Given the alias `serial0`, a client program can look at the `/aliases` node and determine the alias refers to the device path `/simple-bus@fe000000/serial@llc500`.]] -- luacheck: ignore 631

local memory_node_markdown = [[
# Devicetree Specification:

## `/memory` node

A memory device node is required for all devicetrees and describes the physical memory layout for the system. If a system has multiple ranges of memory, multiple memory nodes can be created, or the ranges can be specified in the `reg` property of a single memory node.

The `unit-name` component of the node name shall be `memory`.

The client program may access memory not covered by any memory reservations using any storage attributes it chooses. However, before changing the storage attributes used to access a real page, the client program is responsible for performing actions required by the architecture and implementation, possibly including flushing the real page from the caches. The boot program is responsible for ensuring that, without taking any action associated with a change in storage attributes, the client program can safely access all memory (including memory covered by memory reservations) as WIMG = 0b001x. That is:

- not Write Through Required
- not Caching Inhibited
- Memory Coherence
- Required either not Guarded or Guarded

If the VLE storage attribute is supported, with VLE=0.

## `/memory` node and UEFI

When booting via UEFI, the system memory map is obtained via the GetMemoryMap() UEFI boot time service as defined in the Unified Extensible Firmware Interface Specification, and if present, the OS must ignore any `/memory` nodes.

## `/memory` Examples

Given a 64-bit Power system with the following physical memory layout:

- RAM: starting address 0x0, length 0x80000000 (2 GB)
- RAM: starting address 0x100000000, length 0x100000000 (4 GB)

Memory nodes could be defined as follows, assuming `#address-cells = <2>` and `#size-cells = <2>`.

### Example #1

```dts
memory@0 {
    device_type = "memory";
    reg = <0x000000000 0x00000000 0x00000000 0x80000000
           0x000000001 0x00000000 0x00000001 0x00000000>;
};
```

### Example #2

```dts
memory@0 {
    device_type = "memory";
    reg = <0x000000000 0x00000000 0x00000000 0x80000000>;
};
memory@100000000 {
    device_type = "memory";
    reg = <0x000000001 0x00000000 0x00000001 0x00000000>;
};
```

The `reg` property is used to define the address and size of the two memory ranges. The 2 GB I/O region is skipped. Note that the `#address-cells` and `#size-cells` properties of the root node specify a value of 2, which means that two 32-bit cells are required to define the address and length for the `reg` property of the memory node.]] -- luacheck: ignore 631

local memory_property_markdown = {
    device_type = [[
# Devicetree Specification:

## Property Name: device_type

## Path: /memory/device_type

## Usage: Required

## Definition:

Value shall be "memory"

All other standard properties are allowed but are optional.]] .. M.get_type_definition("string"),
    reg = [[
# Devicetree Specification:

## Property Name: reg

## Path: /memory/reg

## Usage: Required

## Definition:

Consists of an arbitrary number of address and size pairs that specify the physical address and size of the memory ranges.

All other standard properties are allowed but are optional.]] .. M.get_type_definition("prop_encoded_array"),
    ["initial-mapped-area"] = [[
# Devicetree Specification:

## Property Name: initial-mapped-area

## Path: /memory/initial-mapped-area

## Usage: Optional

## Definition:

Specifies the address and size of the Initial Mapped Area

Is a prop-encoded-array consisting of a triplet of (effective address, physical address, size). The effective and physical address shall each be 64-bit (`<u64>` value), and the size shall be 32-bits (`<u32>` value).

All other standard properties are allowed but are optional.]] .. M.get_type_definition("prop_encoded_array"),
    hotpluggable = [[
# Devicetree Specification:

## Property Name: hotpluggable

## Path: /memory/hotpluggable

## Usage: Optional

## Definition:

Specifies an explicit hint to the operating system that this memory may potentially be removed later.

All other standard properties are allowed but are optional.]] .. M.get_type_definition("empty"),
}

local model_property_markdown = [[
# Devicetree Specification:

## Property Name: model

## Path: /model

## Usage: Required

## Definition:

Specifies a string that uniquely identifies the model of the system board. The recommended format is "manufacturer,model-number".]] .. M.get_type_definition(
    "string"
)

local compatible_property_markdown = [[
# Devicetree Specification:

## Property Name: compatible

## Path: /compatible

## Usage: Required

## Definition:

Specifies a list of platform architectures with which this platform is compatible. This property can be used by operating systems in selecting platform specific code. The recommended form of the property value is:

`"manufacturer,model"`

For example:

```dts
compatible = "fsl,mpc8572ds"
```]] .. M.get_type_definition("stringlist")

local address_cells_property_markdown = [[
# Devicetree Specification:

## Property Name: #address-cells

## Path: /#address-cells

## Usage: Required

## Definition:

Specifies the number of `<u32>` cells to represent the address in the `reg` property in children of root.]] .. M.get_type_definition(
    "u32"
)

local size_cells_property_markdown = [[
# Devicetree Specification:

## Property Name: #size-cells

## Path: /#size-cells

## Usage: Required

## Definition:

Specifies the number of `<u32>` cells to represent the size in the `reg` property in children of root.]] .. M.get_type_definition(
    "u32"
)

local serial_number_property_markdown = [[
# Devicetree Specification:

## Property Name: serial-number

## Path: /serial-number

## Usage: Optional

## Definition:

Specifies a string representing the device's serial number.]] .. M.get_type_definition("string")

local chassis_type_property_markdown = [[
# Devicetree Specification:

## Property Name: chassis-type

## Path: /chassis-type

## Usage: Optional but recommended

## Definition:

Specifies a string that identifies the form-factor of the system. The property value can be one of:

- `"desktop"`
- `"laptop"`
- `"convertible"`
- `"server"`
- `"all-in-one"`
- `"tablet"`
- `"handheld"`
- `"handset"`
- `"watch"`
- `"embedded"`
- `"television"`
- `"spectacles"`]] .. M.get_type_definition("string")

local root_property_markdown = {
    ["#address-cells"] = address_cells_property_markdown,
    ["#size-cells"] = size_cells_property_markdown,
    ["chassis-type"] = chassis_type_property_markdown,
    compatible = compatible_property_markdown,
    model = model_property_markdown,
    ["serial-number"] = serial_number_property_markdown,
}

local function property_name_at_cursor(ctx)
    local lines = read_lines(ctx.file)
    local line = lines[ctx.row]
    if not line then
        return nil
    end

    local leading, name = line:match("^(%s*)([%w,._%-#]+)%s*[=;]")
    if not name then
        return nil
    end

    local start_col = #leading + 1
    local end_col = start_col + #name - 1
    if ctx.col < start_col or ctx.col > end_col then
        return nil
    end

    return name
end

local function on_a_property_name(ctx, prop_name)
    return property_name_at_cursor(ctx) == prop_name
end

function M.hover(ctx)
    if M.on_a_root_node(ctx) then
        return root_node_markdown
    end

    if M.on_an_aliases_node(ctx) then
        return aliases_node_markdown
    end

    if M.on_a_memory_node(ctx) then
        return memory_node_markdown
    end

    if M.in_an_aliases_node(ctx) then
        local alias = property_name_at_cursor(ctx)
        if alias then
            return ("# Anakin's Advice\n\nA client program, such as Linux, Zephyr, or U-Boot, can look up the alias `%s` to refer to this node."):format(
                alias
            )
        end
    end

    if M.in_a_memory_node(ctx) then
        local property_name = property_name_at_cursor(ctx)
        return memory_property_markdown[property_name]
    end

    local in_descendant_node = in_node(ctx, function(stack)
        return #stack > 1
    end)
    if M.in_a_root_node(ctx) and not in_descendant_node then
        for property_name, markdown in pairs(root_property_markdown) do
            if on_a_property_name(ctx, property_name) then
                return markdown
            end
        end
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
    send_response(server, msg.id, { capabilities = { textDocumentSync = 1, hoverProvider = true } })
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

default_handlers["textDocument/hover"] = function(server, msg)
    local params = msg.params or {}
    local position = params.position or {}

    local ctx = {
        file = uri_to_path((params.textDocument or {}).uri),
        -- LSP positions are 0-based; the rest of this codebase's row/col
        -- helpers are 1-based (matching Lua's own `file:line:col` errors).
        row = (position.line or 0) + 1,
        col = (position.character or 0) + 1,
    }

    local markdown = M.hover(ctx)
    if markdown then
        send_response(server, msg.id, { contents = { kind = "markdown", value = markdown } })
    else
        send_response(server, msg.id, json.NULL)
    end
end

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
-- the language server over real stdio. Compares `arg[0]` against this
-- chunk's own source rather than matching a hardcoded file name, so this
-- still works when installed under a different name (e.g. by Nix, which
-- installs this file as `bin/anakins-dtls` without the `.lua` suffix).
local function running_as_main_script()
    if arg == nil or arg[0] == nil then
        return false
    end

    return ("@" .. arg[0]) == debug.getinfo(1, "S").source
end

if running_as_main_script() then
    local server = M.new_server(new_stdio_channel())
    M.server_run(server)
    os.exit(server.exit_code or 0)
end

return M
