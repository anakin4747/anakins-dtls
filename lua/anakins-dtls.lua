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

local function diagnostic(line, character, message, severity)
    return {
        range = {
            start = { line = line, character = character },
            ["end"] = { line = line, character = character },
        },
        severity = severity or 1,
        source = "anakins-dtls",
        message = message,
    }
end

local function cell_value_diagnostics(lines)
    local diagnostics = {}
    local angle_depth = 0
    local in_block_comment = false
    local in_string = false
    local escaped = false

    for row, line in ipairs(lines) do
        local col = 1
        while col <= #line do
            local char = line:sub(col, col)
            local following_char = line:sub(col + 1, col + 1)

            if in_block_comment then
                if char == "*" and following_char == "/" then
                    in_block_comment = false
                    col = col + 1
                end
            elseif in_string then
                if escaped then
                    escaped = false
                elseif char == "\\" then
                    escaped = true
                elseif char == '"' then
                    in_string = false
                end
            elseif char == "/" and following_char == "*" then
                in_block_comment = true
                col = col + 1
            elseif char == "/" and following_char == "/" then
                break
            elseif char == '"' then
                in_string = true
            elseif char == "<" then
                angle_depth = angle_depth + 1
            elseif char == ">" and angle_depth > 0 then
                angle_depth = angle_depth - 1
            elseif angle_depth > 0 and char:match("%d") then
                local start_col = col
                local value
                local maximum
                if char == "0" and following_char:match("[xX]") then
                    value = line:match("^0[xX]([%da-fA-F]+)", col)
                    maximum = "ffffffff"
                    col = col + 2 + #(value or "") - 1
                else
                    value = line:match("^(%d+)", col)
                    maximum = "4294967295"
                    col = col + #(value or "") - 1
                end

                value = (value or ""):gsub("^0+", "")
                if #value > #maximum or (#value == #maximum and value:lower() > maximum) then
                    diagnostics[#diagnostics + 1] = diagnostic(
                        row - 1,
                        start_col - 1,
                        "Cell value exceeds 0xFFFFFFFF; represent a <u64> as two cells"
                    )
                    diagnostics[#diagnostics].range["end"].character = col
                end
            end
            col = col + 1
        end
    end

    return diagnostics
end

local function indentation_diagnostics(lines)
    local diagnostics = {}
    local depth = 0
    local indentation_style
    local indent_width
    local in_block_comment = false
    local in_assignment = false

    for row, line in ipairs(lines) do
        local code = {}
        local in_string = false
        local escaped = false
        local col = 1
        while col <= #line do
            local char = line:sub(col, col)
            local following_char = line:sub(col + 1, col + 1)

            if in_block_comment then
                if char == "*" and following_char == "/" then
                    in_block_comment = false
                    col = col + 1
                end
            elseif in_string then
                if escaped then
                    escaped = false
                elseif char == "\\" then
                    escaped = true
                elseif char == '"' then
                    in_string = false
                end
            elseif char == "/" and following_char == "*" then
                in_block_comment = true
                col = col + 1
            elseif char == "/" and following_char == "/" then
                break
            else
                code[#code + 1] = char
                if char == '"' then
                    in_string = true
                end
            end
            col = col + 1
        end

        code = table.concat(code)
        local content = code:match("^%s*(.-)%s*$")
        local malformed_closer = content == ";" and depth > 1
        if content ~= "" and not content:match("^#%s*include") and not malformed_closer then
            local indentation = line:match("^[ \t]*")
            local line_depth = content:sub(1, 1) == "}" and math.max(depth - 1, 0) or depth
            local style = indentation:find("\t", 1, true) and "tabs" or "spaces"

            if line_depth > 0 and #indentation > 0 and not indentation_style then
                indentation_style = style
            end

            if not in_assignment then
                if
                    indentation:find("\t", 1, true) and indentation:find(" ", 1, true)
                    or indentation_style and #indentation > 0 and style ~= indentation_style
                then
                    diagnostics[#diagnostics + 1] =
                        diagnostic(row - 1, 0, "Do not mix tabs and spaces for indentation", 4)
                else
                    local width = #indentation
                    if indentation_style == "tabs" then
                        indent_width = 1
                    end
                    if indent_width then
                        local expected = line_depth * indent_width
                        if width ~= expected then
                            diagnostics[#diagnostics + 1] = diagnostic(
                                row - 1,
                                width,
                                ("Inconsistent indentation: expected %d %s, found %d"):format(
                                    expected,
                                    indentation_style,
                                    width
                                ),
                                4
                            )
                        end
                    elseif line_depth > 0 and width % line_depth == 0 then
                        indent_width = width / line_depth
                    end
                end
            end
        end

        if malformed_closer then
            depth = depth - 1
        else
            local _, openings = code:gsub("{", "")
            local _, closings = code:gsub("}", "")
            depth = math.max(depth + openings - closings, 0)
        end

        if in_assignment then
            in_assignment = not code:find(";", 1, true)
        elseif code:find("=", 1, true) and not code:find(";", 1, true) then
            in_assignment = true
        end
    end

    return diagnostics
end

local function closing_delimiter_diagnostics(lines)
    local diagnostics = {}
    local braces = {}
    local angle_depth = 0

    for row, line in ipairs(lines) do
        local in_string = false
        local escaped = false
        local col = 1
        while col <= #line do
            local char = line:sub(col, col)
            local following_char = line:sub(col + 1, col + 1)

            if not in_string and char == "/" and following_char == "/" then
                break
            elseif in_string then
                if escaped then
                    escaped = false
                elseif char == "\\" then
                    escaped = true
                elseif char == '"' then
                    in_string = false
                end
            elseif char == '"' then
                in_string = true
            elseif char == "<" then
                angle_depth = angle_depth + 1
            elseif char == ">" and angle_depth > 0 then
                angle_depth = angle_depth - 1
            elseif char == "{" then
                braces[#braces + 1] = true
            elseif char == "}" and #braces > 0 then
                braces[#braces] = nil
            elseif char == ";" and angle_depth > 0 then
                diagnostics[#diagnostics + 1] = diagnostic(row - 1, col - 1, "Missing closing >")
                diagnostics[#diagnostics].range["end"].character = col
                angle_depth = 0
            end
            col = col + 1
        end

        if in_string then
            diagnostics[#diagnostics + 1] = diagnostic(row - 1, #line - 1, "Missing closing double quote")
            diagnostics[#diagnostics].range["end"].character = #line
        end

        if line:match("^%s*;%s*$") and #braces > 1 then
            diagnostics[#diagnostics + 1] =
                diagnostic(row - 1, (line:find(";", 1, true) or 1) - 1, "Missing closing brace")
            braces[#braces] = nil
        end
    end

    table.sort(diagnostics, function(left, right)
        local left_start = left.range.start
        local right_start = right.range.start
        return left_start.line < right_start.line
            or (left_start.line == right_start.line and left_start.character < right_start.character)
    end)
    return diagnostics
end

local function semicolon_diagnostics(lines)
    local diagnostics = {}
    local assignment
    local angle_depth = 0

    for row, line in ipairs(lines) do
        local content = line:gsub("//.*$", ""):gsub("%s+$", "")
        if assignment then
            for char in content:gmatch("[<>]") do
                angle_depth = angle_depth + (char == "<" and 1 or -1)
            end

            if content:find(";", 1, true) then
                assignment = nil
                angle_depth = 0
            elseif angle_depth == 0 and not content:match("[,=]%s*$") and content ~= "" then
                diagnostics[#diagnostics + 1] = diagnostic(row - 1, #content, "Missing semicolon")
                assignment = nil
            end
        elseif content:match("^%s*[%w#?,._+%-]+%s*=") then
            assignment = true
            for char in content:gmatch("[<>]") do
                angle_depth = angle_depth + (char == "<" and 1 or -1)
            end

            if content:find(";", 1, true) then
                assignment = nil
                angle_depth = 0
            elseif angle_depth == 0 and not content:match("[,=]%s*$") then
                diagnostics[#diagnostics + 1] = diagnostic(row - 1, #content, "Missing semicolon")
                assignment = nil
            end
        elseif content:match("^%s*[%w#?,._+%-]+%s*$") then
            diagnostics[#diagnostics + 1] = diagnostic(row - 1, #content, "Missing semicolon")
        elseif content:match("^%s*}%s*$") then
            diagnostics[#diagnostics + 1] = diagnostic(row - 1, #content, "Missing semicolon")
        end
    end

    return diagnostics
end

function M.get_diagnostics(file)
    if file:sub(1, 1) ~= "/" then
        error("get_diagnostics: file path must be absolute")
    end

    local lines = read_lines(file)
    local diagnostics = closing_delimiter_diagnostics(lines)
    for _, item in ipairs(semicolon_diagnostics(lines)) do
        diagnostics[#diagnostics + 1] = item
    end
    for _, item in ipairs(cell_value_diagnostics(lines)) do
        diagnostics[#diagnostics + 1] = item
    end
    for _, item in ipairs(indentation_diagnostics(lines)) do
        diagnostics[#diagnostics + 1] = item
    end
    table.sort(diagnostics, function(left, right)
        return left.range.start.line < right.range.start.line
    end)
    return diagnostics
end

local function path_exists(path)
    return os.rename(path, path) ~= nil
end

local function parent_directory(path)
    local parent = path:match("^(.*)/[^/]+/*$")
    if parent == "" then
        return "/"
    end
    return parent
end

local function shell_quote(value)
    return "'" .. value:gsub("'", "'\\''") .. "'"
end

local function find_file(root, name)
    local command = ("find %s -type f -name %s -print -quit"):format(shell_quote(root), shell_quote(name))
    local handle = io.popen(command)
    local file = handle:read("*l")
    handle:close()
    return file
end

local function default_kernel_root(directory)
    local root = shell_quote(directory)
    local command = (
        "for directory in %s %s; do "
        .. 'if [ -d "$directory" ]; then printf \'%%s\\n\' "$directory"; break; fi; '
        .. "done"
    ):format(root .. "/build*/tmp/work-shared/*/kernel-sources", root .. "/output/build/linux-*")
    local handle = io.popen(command)
    local source = handle:read("*l")
    handle:close()
    return source
end

function M.kernel_root(file)
    local directory = parent_directory(file)
    local fallback
    while directory do
        if
            path_exists(directory .. "/arch")
            and path_exists(directory .. "/include")
            and path_exists(directory .. "/Documentation")
        then
            return directory
        end

        local config = io.open(directory .. "/.anakins-dtls", "r")
        if config then
            for line in config:lines() do
                local source = line:match('^%s*S%s*=%s*"([^"]+)"') or line:match("^%s*LINUX_DIR%s*=%s*(.-)%s*$")
                if source then
                    config:close()
                    if source:sub(1, 1) == "/" then
                        return source
                    end
                    return directory .. "/" .. source:gsub("^%./", "")
                end
            end
            config:close()
        end

        fallback = fallback or default_kernel_root(directory)

        local parent = parent_directory(directory)
        if not parent or parent == directory then
            break
        end
        directory = parent
    end

    return fallback
end

function M.out_of_tree_without_config(ctx)
    local file = io.open(ctx.file, "r")
    if not file then
        error("cannot open " .. ctx.file)
    end
    file:close()

    local directory = parent_directory(ctx.file)
    for _ = 1, 10 do
        if
            path_exists(directory .. "/arch")
            and path_exists(directory .. "/include")
            and path_exists(directory .. "/Documentation")
        then
            return false
        end

        local parent = parent_directory(directory)
        if not parent or parent == directory then
            break
        end
        directory = parent
    end

    if M.kernel_root(ctx.file) then
        return false
    end

    return not path_exists(ctx.workspace_root .. "/.anakins-dtls")
end

-- Determine the node name that precedes a '{' found at `open_col` on `line`.
local function node_name_before_brace(line, open_col)
    local before = line:sub(1, open_col - 1):match("^%s*(.-)%s*$")
    local last_token = before:match("(%S+)%s*$") or before
    local after_colon = last_token:match(":([^:]+)$")
    return after_colon or last_token
end

local function node_label_before_brace(line, open_col)
    return line:sub(1, open_col - 1):match("^%s*([%w_]+)%s*:")
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

local function stack_path(stack)
    local path = ""
    for _, name in ipairs(stack) do
        if name ~= "/" then
            path = path .. "/" .. name
        end
    end
    return path ~= "" and path or "/"
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
                        name = name,
                        label = node_label_before_brace(line, col),
                        path = stack_path(stack),
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

local function containing_node(file, row)
    for _, bounds in
        ipairs(find_all_node_bounds(file, function()
            return true
        end))
    do
        if row >= bounds.open_row and row <= bounds.close_row then
            return bounds
        end
    end
end

local function properties_in_bounds(file, bounds)
    local lines = read_lines(file)
    local properties = {}
    local values = {}
    local depth = 0

    for row = bounds.open_row + 1, bounds.close_row - 1 do
        local line = lines[row]
        if depth == 0 then
            local property, value = line:match("^%s*([%w#?,._+%-]+)%s*=%s*(.-)%s*;")
            property = property or line:match("^%s*([%w#?,._+%-]+)%s*;")
            if property then
                properties[#properties + 1] = property
                if value then
                    values[property] = values[property] or {}
                    values[property][#values[property] + 1] = value
                end
            end
        end

        for char in line:gmatch("[{}]") do
            depth = depth + (char == "{" and 1 or -1)
        end
    end

    return properties, values
end

local function included_files(file, root, seen, results)
    seen = seen or {}
    results = results or {}
    if seen[file] then
        return results
    end
    seen[file] = true
    results[#results + 1] = file

    for _, line in ipairs(read_lines(file)) do
        local include = line:match('^%s*#include%s+"([^"]+)"')
        if include then
            local included = parent_directory(file) .. "/" .. include
            if not path_exists(included) and root then
                included = find_file(root, include:match("([^/]+)$"))
            end
            if included then
                included_files(included, root, seen, results)
            end
        end
    end

    return results
end

function M.list_node_properties(ctx)
    local bounds = containing_node(ctx.file, ctx.row)
    if not bounds then
        return {}
    end

    local properties, values = properties_in_bounds(ctx.file, bounds)
    local label = bounds.name:match("^&([%w_]+)$")
    if not label then
        return properties, values
    end

    local root = M.kernel_root(ctx.file)
    for _, file in ipairs(included_files(ctx.file, root)) do
        for _, candidate in
            ipairs(find_all_node_bounds(file, function()
                return true
            end))
        do
            if candidate.label == label then
                local inherited_properties, inherited_values = properties_in_bounds(file, candidate)
                for _, property in ipairs(inherited_properties) do
                    properties[#properties + 1] = property
                end
                for property, property_values in pairs(inherited_values) do
                    values[property] = values[property] or {}
                    for _, value in ipairs(property_values) do
                        values[property][#values[property] + 1] = value
                    end
                end
                return properties, values
            end
        end
    end

    return properties, values
end

local function compatible_strings(ctx)
    local _, values = M.list_node_properties(ctx)
    return values.compatible or {}
end

local function is_serial_device_node(ctx)
    for _, values in ipairs(compatible_strings(ctx)) do
        for compatible in values:gmatch('"([^"]+)"') do
            if compatible == "ns8250" or compatible:match("%-hdlc$") then
                return true
            end
        end
    end

    return false
end

function M.in_a_serial_device_node(ctx)
    local bounds = containing_node(ctx.file, ctx.row)
    if not bounds or ctx.row <= bounds.open_row or ctx.row >= bounds.close_row then
        return false
    end

    return is_serial_device_node(ctx)
end

function M.on_a_serial_device_node(ctx)
    if M.on_a_label_definition(ctx) then
        return false
    end

    for _, bounds in
        ipairs(find_all_node_bounds(ctx.file, function()
            return true
        end))
    do
        local on_opening = ctx.row == bounds.open_row and ctx.col >= bounds.start_col and ctx.col <= bounds.open_col
        local on_closing = ctx.row == bounds.close_row
            and ctx.col >= bounds.close_col
            and ctx.col <= bounds.close_col + 1
        if (on_opening or on_closing) and is_serial_device_node({ file = ctx.file, row = bounds.open_row }) then
            return true
        end
    end

    return false
end

local function is_ns16550_node(ctx)
    for _, values in ipairs(compatible_strings(ctx)) do
        for compatible in values:gmatch('"([^"]+)"') do
            if compatible == "ns16550" then
                return true
            end
        end
    end

    return false
end

function M.in_a_ns16550_node(ctx)
    local bounds = containing_node(ctx.file, ctx.row)
    if not bounds or ctx.row <= bounds.open_row or ctx.row >= bounds.close_row then
        return false
    end

    return is_ns16550_node(ctx)
end

function M.on_a_ns16550_node(ctx)
    if M.on_a_label_definition(ctx) then
        return false
    end

    for _, bounds in
        ipairs(find_all_node_bounds(ctx.file, function()
            return true
        end))
    do
        local on_opening = ctx.row == bounds.open_row and ctx.col >= bounds.start_col and ctx.col <= bounds.open_col
        local on_closing = ctx.row == bounds.close_row
            and ctx.col >= bounds.close_col
            and ctx.col <= bounds.close_col + 1
        if (on_opening or on_closing) and is_ns16550_node({ file = ctx.file, row = bounds.open_row }) then
            return true
        end
    end

    return false
end

local network_properties = {
    ["address-bits"] = true,
    ["local-mac-address"] = true,
    ["mac-address"] = true,
    ["max-frame-size"] = true,
    ["max-speed"] = true,
    ["phy-connection-type"] = true,
    ["phy-handle"] = true,
}

local function is_network_device_node(ctx)
    local properties = M.list_node_properties(ctx)
    for _, property in ipairs(properties) do
        if network_properties[property] then
            return true
        end
    end

    return false
end

function M.in_a_network_device_node(ctx)
    local bounds = containing_node(ctx.file, ctx.row)
    if not bounds or ctx.row <= bounds.open_row or ctx.row >= bounds.close_row then
        return false
    end

    return is_network_device_node(ctx)
end

function M.on_a_network_device_node(ctx)
    if M.on_a_label_definition(ctx) then
        return false
    end

    for _, bounds in
        ipairs(find_all_node_bounds(ctx.file, function()
            return true
        end))
    do
        local on_opening = ctx.row == bounds.open_row and ctx.col >= bounds.start_col and ctx.col <= bounds.open_col
        local on_closing = ctx.row == bounds.close_row
            and ctx.col >= bounds.close_col
            and ctx.col <= bounds.close_col + 1
        if (on_opening or on_closing) and is_network_device_node({ file = ctx.file, row = bounds.open_row }) then
            return true
        end
    end

    return false
end

local function is_open_pic_node(ctx)
    for _, values in ipairs(compatible_strings(ctx)) do
        for compatible in values:gmatch('"([^"]+)"') do
            if compatible == "open-pic" then
                return true
            end
        end
    end

    return false
end

function M.in_an_open_pic_node(ctx)
    local bounds = containing_node(ctx.file, ctx.row)
    if not bounds or ctx.row <= bounds.open_row or ctx.row >= bounds.close_row then
        return false
    end

    return is_open_pic_node(ctx)
end

function M.on_an_open_pic_node(ctx)
    if M.on_a_label_definition(ctx) then
        return false
    end

    for _, bounds in
        ipairs(find_all_node_bounds(ctx.file, function()
            return true
        end))
    do
        local on_opening = ctx.row == bounds.open_row and ctx.col >= bounds.start_col and ctx.col <= bounds.open_col
        local on_closing = ctx.row == bounds.close_row
            and ctx.col >= bounds.close_col
            and ctx.col <= bounds.close_col + 1
        if (on_opening or on_closing) and is_open_pic_node({ file = ctx.file, row = bounds.open_row }) then
            return true
        end
    end

    return false
end

local function is_simple_bus_node(ctx)
    for _, values in ipairs(compatible_strings(ctx)) do
        for compatible in values:gmatch('"([^"]+)"') do
            if compatible == "simple-bus" then
                return true
            end
        end
    end

    return false
end

function M.in_a_simple_bus_node(ctx)
    local bounds = containing_node(ctx.file, ctx.row)
    if not bounds or ctx.row <= bounds.open_row or ctx.row >= bounds.close_row then
        return false
    end

    return is_simple_bus_node(ctx)
end

function M.on_a_simple_bus_node(ctx)
    if M.on_a_label_definition(ctx) then
        return false
    end

    for _, bounds in
        ipairs(find_all_node_bounds(ctx.file, function()
            return true
        end))
    do
        local on_opening = ctx.row == bounds.open_row and ctx.col >= bounds.start_col and ctx.col <= bounds.open_col
        local on_closing = ctx.row == bounds.close_row
            and ctx.col >= bounds.close_col
            and ctx.col <= bounds.close_col + 1
        if (on_opening or on_closing) and is_simple_bus_node({ file = ctx.file, row = bounds.open_row }) then
            return true
        end
    end

    return false
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
    if M.on_a_label_definition(ctx) then
        return false
    end

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

local function cache_node_path(ctx)
    local bounds = containing_node(ctx.file, ctx.row)
    return bounds and bounds.path
end

local function property_path(ctx, property_name)
    local bounds = containing_node(ctx.file, ctx.row)
    return bounds and bounds.path .. (bounds.path == "/" and "" or "/") .. property_name
end

local function with_path(markdown, path)
    return markdown:gsub("(## Property [^\n]+\n)", "%1\n## Path: " .. path .. "\n", 1)
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

local function is_possible_memory_region_consumer(stack)
    return #stack > 1 and stack[2] ~= "reserved-memory"
end

function M.in_possible_memory_region_consumer(ctx)
    return in_node(ctx, is_possible_memory_region_consumer)
end

local function possible_memory_region_consumer_path(ctx)
    for _, bounds in ipairs(find_all_node_bounds(ctx.file, is_possible_memory_region_consumer)) do
        if ctx.row > bounds.open_row and ctx.row < bounds.close_row then
            return bounds.path
        end
    end
end

local function reserved_memory_region_path(ctx)
    for _, bounds in ipairs(find_all_node_bounds(ctx.file, { "/", "reserved-memory", any_name })) do
        if ctx.row >= bounds.open_row and ctx.row <= bounds.close_row then
            return "/reserved-memory/" .. bounds.name
        end
    end
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

local function label_definition_at_cursor(ctx)
    local line = read_lines(ctx.file)[ctx.row]
    if not line then
        return nil
    end

    local leading, label = line:match("^(%s*)([%w_]+):")
    if label and ctx.col >= #leading + 1 and ctx.col <= #leading + #label + 1 then
        return label
    end
end

local function label_reference_at_cursor(ctx)
    local lines = read_lines(ctx.file)
    local line = lines[ctx.row]
    if not line then
        return nil
    end

    local search_from = 1
    while true do
        local amp_col = line:find("&", search_from)
        if not amp_col then
            return nil
        end

        local end_col = amp_col
        while end_col + 1 <= #line and line:sub(end_col + 1, end_col + 1):match("[%w_]") do
            end_col = end_col + 1
        end

        if ctx.col >= amp_col and ctx.col <= end_col then
            return line:sub(amp_col + 1, end_col)
        end

        search_from = amp_col + 1
    end
end

function M.on_a_label_reference(ctx)
    return label_reference_at_cursor(ctx) ~= nil
end

local function find_node_label_bounds(ctx, label)
    local root = M.kernel_root(ctx.file)
    for _, file in ipairs(included_files(ctx.file, root)) do
        for _, bounds in
            ipairs(find_all_node_bounds(file, function()
                return true
            end))
        do
            if bounds.label == label then
                return bounds
            end
        end
    end
end

function M.find_node_label_definition(ctx)
    local label = label_reference_at_cursor(ctx)
    if not label then
        return nil
    end

    local root = M.kernel_root(ctx.file)
    for _, file in ipairs(included_files(ctx.file, root)) do
        for _, bounds in
            ipairs(find_all_node_bounds(file, function()
                return true
            end))
        do
            if bounds.label == label then
                return {
                    file = file,
                    row = bounds.open_row,
                    start_col = bounds.start_col,
                    end_col = bounds.start_col + #label - 1,
                }
            end
        end
    end
end

function M.goto_definition(ctx)
    if M.on_a_label_reference(ctx) then
        return M.find_node_label_definition(ctx)
    end
end

local function compatible_string_at_cursor(ctx)
    local lines = read_lines(ctx.file)
    local line = lines[ctx.row]
    if not line then
        return nil
    end

    for start_col, compatible, end_col in line:gmatch('()"([^"]+)"()') do
        if ctx.col >= start_col and ctx.col < end_col then
            if line:match("^%s*compatible%s*=") then
                return compatible
            end
            if line:find("=") or line:find("[{}]") then
                return nil
            end

            for row = ctx.row - 1, 1, -1 do
                local property_line = lines[row]
                if property_line:match("^%s*compatible%s*=") then
                    return compatible
                end
                if property_line:find("=") or property_line:find("[;{}]") then
                    return nil
                end
            end
        end
    end
end

function M.goto_implementation(ctx)
    local compatible = compatible_string_at_cursor(ctx)
    local root = compatible and M.kernel_root(ctx.file)
    if not root then
        return nil
    end

    local quoted = '"' .. compatible .. '"'
    local command = ("rg --line-number --column --only-matching --fixed-strings --glob '*.{c,h}' %s %s"):format(
        shell_quote(quoted),
        shell_quote(root)
    )
    local handle = io.popen(command)
    local match = handle:read("*l")
    handle:close()
    if not match then
        return nil
    end

    local file, row, quote_col = match:match("^(.-):(%d+):(%d+):")
    if not file then
        return nil
    end

    return {
        file = file,
        row = tonumber(row),
        start_col = tonumber(quote_col) + 1,
        end_col = tonumber(quote_col) + #compatible,
    }
end

local dts_v1_markdown = [[# Devicetree Specification: `/dts-v1/`

## Definition:

`/dts-v1/;` shall be present to identify the file as a version 1 DTS (dts files without this tag will be treated by dtc as being in the obsolete version 0, which uses a different format for integers in addition to other small but incompatible changes).]]

local memreserve_markdown = [[# Devicetree Specification: `/memreserve/`

## Definition:

Memory reservations are represented by lines in the form:

```
/memreserve/ <address> <length>;
```

Where `<address>` and `<length>` are 64-bit C-style integers, e.g.:

```dts
/* Reserve memory region 0x10000000..0x10003fff */
/memreserve/ 0x10000000 0x4000;
```

## Purpose:

The `memory reservation block` provides the client program with a list of areas in physical memory which are `reserved`; that is, which shall not be used for general memory allocations. It is used to protect vital data structures from being overwritten by the client program. For example, on some systems with an IOMMU, the TCE (translation control entry) tables initialized by a DTSpec boot program would need to be protected in this manner. Likewise, any boot program code or data used during the client program’s runtime would need to be reserved (e.g., RTAS on Open Firmware platforms). DTSpec does not require the boot program to provide any such runtime components, but it does not prohibit implementations from doing so as an extension.

More specifically, a client program shall not access memory in a reserved region unless other information provided by the boot program explicitly indicates that it shall do so. The client program may then access the indicated section of the reserved memory in the indicated manner. Methods by which the boot program can indicate to the client program specific uses for reserved memory may appear in this document, in optional extensions to it, or in platform-specific documentation.

The reserved regions supplied by a boot program may, but are not required to, encompass the devicetree blob itself. The client program shall ensure that it does not overwrite this data structure before it is used, whether or not it is in the reserved areas.

Any memory that is declared in a memory node and is accessed by the boot program or caused to be accessed by the boot program after client entry must be reserved. Examples of this type of access include (e.g., speculative memory reads through a non-guarded virtual page).

This requirement is necessary because any memory that is not reserved may be accessed by the client program with arbitrary storage attributes.

Any accesses to reserved memory by or caused by the boot program must be done as not Caching Inhibited and Memory Coherence Required (i.e., WIMG = 0bx01x), and additionally for Book III-S implementations as not Write Through Required (i.e., WIMG = 0b001x). Further, if the VLE storage attribute is supported, all accesses to reserved memory must be done as VLE=0.

This requirement is necessary because the client program is permitted to map memory with storage attributes specified as not Write Through Required, not Caching Inhibited, and Memory Coherence Required (i.e., WIMG = 0b001x), and VLE=0 where supported. The client program may use large virtual pages that contain reserved memory. However, the client program may not modify reserved memory, so the boot program may perform accesses to reserved memory as Write Through Required where conflicting values for this storage attribute are architecturally permissible.]] -- luacheck: ignore 631

local label_markdown = [[# Devicetree Specification: Label %s

## Label: %s

## Path: %s

## Definition:

The source format allows labels to be attached to any node or property value in the devicetree. Phandle and path references can be automatically generated by referencing a label instead of explicitly specifying a phandle value or the full path to a node. Labels are only used in the devicetree source format and are not encoded into the DTB binary.

A label shall be between 1 to 31 characters in length, be composed only of the characters in the below set, and must not start with a number.

Labels are created by appending a colon (':') to the label name. References are created by prefixing the label name with an ampersand ('&').

## Valid characters for DTS labels

| Character | Description |
| --- | --- |
| 0-9 | digit |
| a-z | lowercase letter |
| A-Z | uppercase letter |
| _ | underscore |]]

local root_node_markdown = [[
# Devicetree Specification:

## Path: /

The root node does not have a `node-name` or `unit-address`. It is identified by a forward slash (/).

All devicetrees shall have a root node and the following nodes shall be present at the root of all devicetrees:
-  One `/cpus` node
-  At least one `/memory` node

The devicetree has a single root node of which all other device nodes are descendants. The full path to the root node is `/`.]] -- luacheck: ignore 631

local aliases_node_markdown = [[
# Devicetree Specification:

## `/aliases` node

## Path: /aliases

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

local cpus_node_markdown = [[
# Devicetree Specification:

## `/cpus` node

## Path: /cpus

A `/cpus` node is required for all devicetrees. It does not represent a real device in the system, but acts as a container for child `cpu` nodes which represent the systems CPUs.

The `/cpus` node may contain properties that are common across `cpu` nodes.

## Example

Here is an example of a `/cpus` node with one child cpu node:

```dts
cpus {
    #address-cells = <1>;
    #size-cells = <0>;
    cpu@0 {
        device_type = "cpu";
        reg = <0>;
        d-cache-block-size = <32>; // L1 - 32 bytes
        i-cache-block-size = <32>; // L1 - 32 bytes
        d-cache-size = <0x8000>; // L1, 32K
        i-cache-size = <0x8000>; // L1, 32K
        timebase-frequency = <82500000>; // 82.5 MHz
        clock-frequency = <825000000>; // 825 MHz
    };
};
```]]

local cpu_node_markdown = [[
# Devicetree Specification:

## `/cpus/cpu@0` node

## Path: /cpus/cpu@0

A `cpu` node represents a hardware execution block that is sufficiently independent that it is capable of running an operating system without interfering with other CPUs possibly running other operating systems.

Hardware threads that share an MMU would generally be represented under one `cpu` node. If other more complex CPU topographies are designed, the binding for the CPU must describe the topography (e.g. threads that don’t share an MMU).

CPUs and threads are numbered through a unified number-space that should match as closely as possible the interrupt controller’s numbering of CPUs/threads.

Properties that have identical values across `cpu` nodes may be placed in the `/cpus` node instead. A client program must first examine a specific `cpu` node, but if an expected property is not found then it should look at the parent `/cpus` node. This results in a less verbose representation of properties which are identical across all CPUs.

The node name for every CPU node should be `cpu`.]]

local cache_node_markdown = [[
# Devicetree Specification:

## `%s` node

## Path: %s

Processors and systems may implement additional levels of cache hierarchy. For example, second-level (L2) or third-level (L3) caches. These caches can potentially be tightly integrated to the CPU or possibly shared between multiple CPUs.

A device node with a compatible value of `"cache"` describes these types of caches.

The cache node shall define a phandle property, and all cpu nodes or cache nodes that are associated with or share the cache each shall contain a next-level-cache property that specifies the phandle to the cache node.

A cache node may be represented under a CPU node or any other appropriate location in the devicetree.

## Example

See the following example of a devicetree representation of two CPUs, each with their own on-chip L2 and a shared L3.

```dts
cpus {
    #address-cells = <1>;
    #size-cells = <0>;
    cpu@0 {
        device_type = "cpu";
        reg = <0>;
        cache-unified;
        cache-size = <0x8000>; // L1, 32 KB
        cache-block-size = <32>;
        timebase-frequency = <82500000>; // 82.5 MHz
        next-level-cache = <&L2_0>; // phandle to L2

        L2_0:l2-cache {
            compatible = "cache";
            cache-unified;
            cache-size = <0x40000>; // 256 KB

            cache-sets = <1024>;
            cache-block-size = <32>;
            cache-level = <2>;
            next-level-cache = <&L3>; // phandle to L3

            L3:l3-cache {
                compatible = "cache";
                cache-unified;
                cache-size = <0x40000>; // 256 KB
                cache-sets = <0x400>; // 1024
                cache-block-size = <32>;
                cache-level = <3>;
            };
        };
    };

    cpu@1 {
        device_type = "cpu";
        reg = <1>;
        cache-unified;
        cache-block-size = <32>;
        cache-size = <0x8000>; // L1, 32 KB
        timebase-frequency = <82500000>; // 82.5 MHz
        clock-frequency = <825000000>; // 825 MHz
        next-level-cache = <&L2_1>; // phandle to L2
        L2_1:l2-cache {
            compatible = "cache";
            cache-unified;
            cache-level = <2>;
            cache-size = <0x40000>; // 256 KB
            cache-sets = <0x400>; // 1024
            cache-line-size = <32>; // 32 bytes
            next-level-cache = <&L3>; // phandle to L3
        };
    };
};
```]] -- luacheck: ignore 631

local memory_node_markdown = [[
# Devicetree Specification:

## `/memory` node

## Path: %s

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

local chosen_node_markdown = [[
# Devicetree Specification:

## `/chosen` node

## Path: /chosen

The `/chosen` node does not represent a real device in the system but describes parameters chosen or specified by the system firmware at run time. It shall be a child of the root node.

## Example

```dts
chosen {
    bootargs = "root=/dev/nfs rw nfsroot=192.168.1.1 console=ttyS0,115200";
};
```

Older versions of devicetrees may be encountered that contain a deprecated form of the `stdout-path` property called `linux,stdout-path`. For compatibility, a client program might want to support `linux,stdout-path` if a `stdout-path` property is not present. The meaning and use of the two properties is identical.]] -- luacheck: ignore 631

local reserved_memory_node_markdown = [[
# Devicetree Specification:

## `/reserved-memory` node

## Path: /reserved-memory

Reserved memory is specified as a node under the `/reserved-memory` node. The operating system shall exclude reserved memory from normal usage. One can create child nodes describing particular reserved (excluded from normal use) memory regions. Such memory regions are usually designed for the special usage by various device drivers.

## Device node references to reserved memory

Regions in the `/reserved-memory` node may be referenced by other device nodes by adding a `memory-region` property to the device node.

## `/reserved-memory/` and UEFI

When booting via UEFI, static `/reserved-memory` regions must also be listed in the system memory map obtained via the GetMemoryMap() UEFI boot time service as defined in the Unified Extensible Firmware Interface Specification. The reserved memory regions need to be included in the UEFI memory map to protect against allocations by UEFI applications.

Reserved regions with the `no-map` property must be listed in the memory map with type `EfiReservedMemoryType`. All other reserved regions must be listed with type `EfiBootServicesData`.

Dynamic reserved memory regions must not be listed in the UEFI memory map because they are allocated by the OS after exiting firmware boot services.

## `/reserved-memory` Example

This example defines 3 contiguous regions are defined for Linux kernel: one default of all device drivers (named `linux,cma` and 64MiB in size), one dedicated to the framebuffer device (named `framebuffer@78000000`, 8MiB), and one for multimedia processing (named `multimedia@77000000`, 64MiB).

```dts
/ {
    #address-cells = <1>;
    #size-cells = <1>;

    memory {
        reg = <0x40000000 0x40000000>;
    };

    reserved-memory {
        #address-cells = <1>;
        #size-cells = <1>;
        ranges;

        /* global autoconfigured region for contiguous allocations */
        linux,cma {
            compatible = "shared-dma-pool";
            reusable;
            size = <0x4000000>;
            alignment = <0x2000>;
            linux,cma-default;
        };

        display_reserved: framebuffer@78000000 {
            reg = <0x78000000 0x800000>;
        };

        multimedia_reserved: multimedia@77000000 {
            compatible = "acme,multimedia-memory";
            reg = <0x77000000 0x4000000>;
        };
    };

    /* ... */

    fb0: video@12300000 {
        memory-region = <&display_reserved>;
        /* ... */
    };

    scaler: scaler@12500000 {
        memory-region = <&multimedia_reserved>;
        /* ... */
    };

    codec: codec@12600000 {
        memory-region = <&multimedia_reserved>;
        /* ... */
    };
};
```]] -- luacheck: ignore 631

local reserved_memory_region_node_markdown = M.dedent([[
    # Devicetree Specification:

    ## `/reserved-memory/` child node

    ## Path: %s

    Each child of the reserved-memory node specifies one or more regions of reserved memory. Each child node may either use a `reg` property to specify a specific range of reserved memory, or a `size` property with optional constraints to request a dynamically allocated block of memory.

    Following the generic-names recommended practice, node names should reflect the purpose of the node (ie. "`framebuffer`" or "`dma-pool`"). Unit address (`@<address>`) should be appended to the name if the node is a static allocation.

    A reserved memory node requires either a `reg` property for static allocations, or a `size` property for dynamics allocations. Dynamic allocations may use `alignment` and `alloc-ranges` properties to constrain where the memory is allocated from. If both `reg` and `size` are present, then the region is treated as a static allocation with the `reg` property taking precedence and `size` is ignored.

    The `no-map` and `reusable` properties are mutually exclusive and both must not be used together in the same node.

    Linux implementation notes:
    - If a `linux,cma-default` property is present, then Linux will use the region for the default pool of the contiguous memory allocator.
    - If a `linux,dma-default` property is present, then Linux will use the region for the default pool of the consistent DMA allocator.

    ## Device node references to reserved memory

    Regions in the `/reserved-memory` node may be referenced by other device nodes by adding a `memory-region` property to the device node.

    ## `/reserved-memory/` and UEFI

    When booting via UEFI, static `/reserved-memory` regions must also be listed in the system memory map obtained via the GetMemoryMap() UEFI boot time service as defined in the Unified Extensible Firmware Interface Specification. The reserved memory regions need to be included in the UEFI memory map to protect against allocations by UEFI applications.

    Reserved regions with the `no-map` property must be listed in the memory map with type `EfiReservedMemoryType`. All other reserved regions must be listed with type `EfiBootServicesData`.

    Dynamic reserved memory regions must not be listed in the UEFI memory map because they are allocated by the OS after exiting firmware boot services.

    ## `/reserved-memory` Example

    This example defines 3 contiguous regions are defined for Linux kernel: one default of all device drivers (named `linux,cma` and 64MiB in size), one dedicated to the framebuffer device (named `framebuffer@78000000`, 8MiB), and one for multimedia processing (named `multimedia@77000000`, 64MiB).

    ```dts
    / {
        #address-cells = <1>;
        #size-cells = <1>;

        memory {
            reg = <0x40000000 0x40000000>;
        };

        reserved-memory {
            #address-cells = <1>;
            #size-cells = <1>;
            ranges;

            /* global autoconfigured region for contiguous allocations */
            linux,cma {
                compatible = "shared-dma-pool";
                reusable;
                size = <0x4000000>;
                alignment = <0x2000>;
                linux,cma-default;
            };

            display_reserved: framebuffer@78000000 {
                reg = <0x78000000 0x800000>;
            };

            multimedia_reserved: multimedia@77000000 {
                compatible = "acme,multimedia-memory";
                reg = <0x77000000 0x4000000>;
            };
        };

        /* ... */

        fb0: video@12300000 {
            memory-region = <&display_reserved>;
            /* ... */
        };

        scaler: scaler@12500000 {
            memory-region = <&multimedia_reserved>;
            /* ... */
        };

        codec: codec@12600000 {
            memory-region = <&multimedia_reserved>;
            /* ... */
        };
    };
    ```]]) -- luacheck: ignore 631

local memory_property_markdown = {
    device_type = [[
# Devicetree Specification:

## Property Name: device_type

## Path: /memory/device_type

## Usage: Required

## Definition:

Value shall be "memory"

All other standard properties are allowed but are optional.

## Anakin's Advice:

Not to be confused with the /cpus/cpu*/device_type which shall be `"cpu"` and not to be confused with the deprecated standard property `device_type`]]
        .. M.get_type_definition("string"),
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

local cpus_property_markdown = {
    ["#address-cells"] = [[
# Devicetree Specification:

## Property Name: #address-cells

## Path: /cpus/#address-cells

## Usage: Required

## Definition:

The value specifies how many cells each element of the `reg` property array takes in children of this node.

All other standard properties are allowed but are optional.]] .. M.get_type_definition("u32"),
    ["#size-cells"] = [[
# Devicetree Specification:

## Property Name: #size-cells

## Path: /cpus/#size-cells

## Usage: Required

## Definition:

Value shall be 0. Specifies that no size is required in the `reg` property in children of this node.

All other standard properties are allowed but are optional.]] .. M.get_type_definition("u32"),
}

local cpu_property_markdown = {
    device_type = [[
# Devicetree Specification:

## Property Name: device_type

## Path: /cpus/cpu@0/device_type

## Usage: Required

## Definition:

Value shall be `"cpu"`.

All other standard properties are allowed but are optional.]] .. M.get_type_definition("string"),
    reg = [[
# Devicetree Specification:

## Property Name: reg

## Path: /cpus/cpu@0/reg

## Usage: Required

## Definition:

The value of `reg` is a `<prop-encoded-array>` that defines a unique CPU/thread id for the CPU/threads represented by the CPU node.

If a CPU supports more than one thread (i.e. multiple streams of execution) the `reg` property is an array with 1 element per thread. The `#address-cells` on the `/cpus` node specifies how many cells each element of the array takes. Software can determine the number of threads by dividing the size of `reg` by the parent node's `#address-cells`.

If a CPU/thread can be the target of an external interrupt the `reg` property value must be a unique CPU/thread id that is addressable by the interrupt controller.

If a CPU/thread cannot be the target of an external interrupt, then `reg` must be unique and out of bounds of the range addressed by the interrupt controller.

If a CPU/thread's PIR (pending interrupt register) is modifiable, a client program should modify PIR to match the `reg` property value. If PIR cannot be modified and the PIR value is distinct from the interrupt controller number space, the CPUs binding may define a binding-specific representation of PIR values if desired.

All other standard properties are allowed but are optional.]] .. M.get_type_definition("prop_encoded_array"),
    ["clock-frequency"] = [[
# Devicetree Specification:

## Property Name: clock-frequency

## Path: /cpus/cpu@0/clock-frequency

## Usage: Optional

## Definition:

Specifies the clock speed of the CPU in Hertz, if that is constant. The value is a `<prop-encoded-array>` in one of two forms:
- A 32-bit integer consisting of one `<u32>` specifying the frequency.
- A 64-bit integer represented as a `<u64>` specifying the frequency.

All other standard properties are allowed but are optional.]] .. M.get_type_definition("prop_encoded_array"),
    ["bus-frequency"] = [[
# Devicetree Specification:

## Property Name: bus-frequency

## Path: /cpus/cpu@0/bus-frequency

## Usage: Deprecated

## Definition:

Older versions of devicetree may be encountered that contain a bus-frequency property on CPU nodes. For compatibility, a client-program might want to support bus-frequency. The format of the value is identical to that of clock-frequency. The recommended practice is to represent the frequency of a bus on the bus node using a clock-frequency property.

Specifies the clock speed of the CPU in Hertz, if that is constant. The value is a `<prop-encoded-array>` in one of two forms:
- A 32-bit integer consisting of one `<u32>` specifying the frequency.
- A 64-bit integer represented as a `<u64>` specifying the frequency.

All other standard properties are allowed but are optional.]] .. M.get_type_definition("prop_encoded_array"),
    ["timebase-frequency"] = [[
# Devicetree Specification:

## Property Name: timebase-frequency

## Path: /cpus/cpu@0/timebase-frequency

## Usage: Optional

## Definition:

Specifies the current frequency at which the timebase and decrementer registers are updated (in Hertz). The value is a `<prop-encoded-array>` in one of two forms:
- A 32-bit integer consisting of one `<u32>` specifying the frequency.
- A 64-bit integer represented as a `<u64>`.

All other standard properties are allowed but are optional.]] .. M.get_type_definition("prop_encoded_array"),
    status = [[
# Devicetree Specification:

## Property Name: status

## Path: /cpus/cpu@0/status

## Usage: See definition

## Definition:

A standard property describing the state of a CPU. This property shall be present for nodes representing CPUs in a symmetric multiprocessing (SMP) configuration. For a CPU node the meaning of the `"okay"`, `"disabled"` and `"fail"` values are as follows:

`"okay"` : The CPU is running.
`"disabled"` : The CPU is in a quiescent state.
`"fail"` : The CPU is not operational or does not exist.

A quiescent CPU is in a state where it cannot interfere with the normal operation of other CPUs, nor can its state be affected by the normal operation of other running CPUs, except by an explicit method for enabling or re-enabling the quiescent CPU (see the enable-method property).

In particular, a running CPU shall be able to issue broadcast TLB invalidates without affecting a quiescent CPU.

Examples: A quiescent CPU could be in a spin loop, held in reset, and electrically isolated from the system bus or in another implementation dependent state.

A CPU with `"fail"` status does not affect the system in any way. The status is assigned to nodes for which no corresponding CPU exists.

All other standard properties are allowed but are optional.]] .. M.get_type_definition("string"),
    ["enable-method"] = [[
# Devicetree Specification:

## Property Name: enable-method

## Path: /cpus/cpu@0/enable-method

## Usage: See definition

## Definition:

Describes the method by which a CPU in a disabled state is enabled. This property is required for CPUs with a status property with a value of `"disabled"`. The value consists of one or more strings that define the method to release this CPU. If a client program recognizes any of the methods, it may use it. The value shall be one of the following:

`"spin-table"` : The CPU is enabled with the spin table method defined in the |spec|.

`"[vendor],[method]"` : Implementation dependent string that describes the method by which a CPU is released from a `"disabled"` state. The required format is: `"[vendor],[method]"`, where vendor is a string describing the name of the manufacturer and method is a string describing the vendor specific mechanism.

Example: `"fsl,MPC8572DS"`

Note: Other methods may be added to later revisions of the Devicetree specification.

All other standard properties are allowed but are optional.]] .. M.get_type_definition("stringlist"),
    ["cpu-release-addr"] = [[
# Devicetree Specification:

## Property Name: cpu-release-addr

## Path: /cpus/cpu@0/cpu-release-addr

## Usage: See definition

## Definition:

The cpu-release-addr property is required for cpu nodes that have an enable-method property value of `"spin-table"`. The value specifies the physical address of a spin table entry that releases a secondary CPU from its spin loop.

All other standard properties are allowed but are optional.]] .. M.get_type_definition("u64"),
}

local function cpu_property(name, usage, definition, type_name)
    return ("# Devicetree Specification:\n\n## Property Name: %s\n\n## Path: /cpus/cpu@0/%s\n\n## Usage: %s\n\n## Definition:\n\n%s\n\nAll other standard properties are allowed but are optional."):format(
        name,
        name,
        usage,
        definition
    ) .. M.get_type_definition(type_name)
end

cpu_property_markdown["power-isa-version"] = cpu_property(
    "power-isa-version",
    "Optional",
    'A string that specifies the numerical portion of the Power ISA version string. For example, for an implementation complying with Power ISA Version 2.06, the value of this property would be `"2.06"`.',
    "string"
)
cpu_property_markdown["cache-op-block-size"] = cpu_property(
    "cache-op-block-size",
    "See definition",
    "Specifies the block size in bytes upon which cache block instructions operate (e.g., dcbz). Required if different than the L1 cache block size.",
    "u32"
)
cpu_property_markdown["reservation-granule-size"] = cpu_property(
    "reservation-granule-size",
    "See definition",
    "Specifies the reservation granule size supported by this processor in bytes.",
    "u32"
)
cpu_property_markdown["mmu-type"] = cpu_property(
    "mmu-type",
    "Optional",
    M.dedent([[
        Specifies the CPU’s MMU type.

        Valid values are shown below:
        - `"mpc8xx"`
        - `"ppc40x"`
        - `"ppc440"`
        - `"ppc476"`
        - `"power-embedded"`
        - `"powerpc-classic"`
        - `"power-server-stab"`
        - `"power-server-slb"`
        - `"none"`]]),
    "string"
)

local cpu_u32_properties = {
    ["tlb-size"] = "Specifies the number of entries in the TLB. Required for a CPU with a unified TLB for instruction and data addresses.",
    ["tlb-sets"] = "Specifies the number of associativity sets in the TLB. Required for a CPU with a unified TLB for instruction and data addresses.",
    ["d-tlb-size"] = "Specifies the number of entries in the data TLB. Required for a CPU with a split TLB configuration.",
    ["d-tlb-sets"] = "Specifies the number of entries in the data TLB. Required for a CPU with a split TLB configuration.",
    ["i-tlb-size"] = "Specifies the number of entries in the instruction TLB. Required for a CPU with a split TLB configuration.",
    ["i-tlb-sets"] = "Specifies the number of associativity sets in the instruction TLB. Required for a CPU with a split TLB configuration.",
    ["cache-size"] = "Specifies the size in bytes of a unified cache. Required if the cache is unified (combined instructions and data).",
    ["cache-sets"] = "Specifies the number of associativity sets in a unified cache. Required if the cache is unified (combined instructions and data).",
    ["cache-block-size"] = "Specifies the block size in bytes of a unified cache. Required if the processor has a unified cache (combined instructions and data).",
    ["cache-line-size"] = "Specifies the line size in bytes of a unified cache, if different than the cache block size. Required if the processor has a unified cache (combined instructions and data).",
    ["i-cache-size"] = "Specifies the size in bytes of the instruction cache. Required if the cpu has a separate cache for instructions.",
    ["i-cache-sets"] = "Specifies the number of associativity sets in the instruction cache. Required if the cpu has a separate cache for instructions.",
    ["i-cache-block-size"] = "Specifies the block size in bytes of the instruction cache. Required if the cpu has a separate cache for instructions.",
    ["i-cache-line-size"] = "Specifies the line size in bytes of the instruction cache, if different than the cache block size. Required if the cpu has a separate cache for instructions.",
    ["d-cache-size"] = "Specifies the size in bytes of the data cache. Required if the cpu has a separate cache for data.",
    ["d-cache-sets"] = "Specifies the number of associativity sets in the data cache. Required if the cpu has a separate cache for data.",
    ["d-cache-block-size"] = "Specifies the block size in bytes of the data cache. Required if the cpu has a separate cache for data.",
    ["d-cache-line-size"] = "Specifies the line size in bytes of the data cache, if different than the cache block size. Required if the cpu has a separate cache for data.",
}
for name, definition in pairs(cpu_u32_properties) do
    cpu_property_markdown[name] = cpu_property(name, "See definition", definition, "u32")
end

cpu_property_markdown["tlb-split"] = cpu_property(
    "tlb-split",
    "See definition",
    "If present specifies that the TLB has a split configuration, with separate TLBs for instructions and data. If absent, specifies that the TLB has a unified configuration. Required for a CPU with a TLB in a split configuration.",
    "empty"
)
cpu_property_markdown["cache-unified"] = cpu_property(
    "cache-unified",
    "See definition",
    "If present, specifies the cache has a unified organization. If not present, specifies that the cache has a Harvard architecture with separate caches for instructions and data.",
    "empty"
)
cpu_property_markdown["next-level-cache"] = cpu_property(
    "next-level-cache",
    "See definition",
    "If present, indicates that another level of cache exists. The value is the phandle of the next level of cache.",
    "phandle"
)
cpu_property_markdown["l2-cache"] = cpu_property(
    "l2-cache",
    "Deprecated",
    M.dedent(
        [[
        Older versions of devicetrees may be encountered that contain a deprecated form of the next-level-cache property called `l2-cache`. For compatibility, a client-program may wish to support `l2-cache` if a next-level-cache property is not present. The meaning and use of the two properties is identical.

        If present, indicates that another level of cache exists. The value is the phandle of the next level of cache.]]
    ),
    "phandle"
)

local power_isa_category_definition = M.dedent(
    [[
    If the `power-isa-version` property exists, then for each category from the Categories section of Book I of the Power ISA version indicated, the existence of a property named `power-isa-[CAT]`, where `[CAT]` is the abbreviated category name with all uppercase letters converted to lowercase, indicates that the category is supported by the implementation.

    For example, if the power-isa-version property exists and its value is `"2.06"` and the power-isa-e.hv property exists, then the implementation supports [Category:Embedded.Hypervisor] as defined in Power ISA Version 2.06.]]
)

local function cache_property(name, usage, definition, type_name)
    return cpu_property(name, usage, definition, type_name):gsub("/cpus/cpu@0", "%%s")
end

local cache_property_markdown = {
    compatible = cache_property(
        "compatible",
        "Required",
        'A standard property. The value shall include the string `"cache"`.',
        "string"
    ),
    ["cache-level"] = cache_property(
        "cache-level",
        "Required",
        "Specifies the level in the cache hierarchy. For example, a level 2 cache has a value of 2.",
        "u32"
    ),
}

local chosen_property_markdown = {
    bootargs = [[
# Devicetree Specification:

## Property Name: bootargs

## Path: /chosen/bootargs

## Usage: Optional

## Definition:

A string that specifies the boot arguments for the client program. The value could potentially be a null string if no boot arguments are required.

All other standard properties are allowed but are optional.]] .. M.get_type_definition("string"),
    bootsource = [[
# Devicetree Specification:

## Property Name: bootsource

## Path: /chosen/bootsource

## Usage: Optional

## Definition:

A string that specifies the full path to the node representing the device the BootROM used to load the initial boot program. If the initial boot program is split into multiple stages, this represents the storage medium or device (e.g. used by fastboot) from which the very first stage was loaded by the BootROM. It may differ from the device from which later stages of the boot program or client program are loaded from, as this property isn't meant to represent those devices. A later stage of the boot program, or the client program, may use this information to favor the device in this property over others for loading later stages, or know the storage medium to flash an update to.

All other standard properties are allowed but are optional.]] .. M.get_type_definition("string"),
    ["stdout-path"] = [[
# Devicetree Specification:

## Property Name: stdout-path

## Path: /chosen/stdout-path

## Usage: Optional

## Definition:

A string that specifies the full path to the node representing the device to be used for boot console output. If the character ":" is present in the value it terminates the path. The value may be an alias. If the stdin-path property is not specified, stdout-path should be assumed to define the input device.

Older versions of devicetrees may be encountered that contain a deprecated form of the `stdout-path` property called `linux,stdout-path`. For compatibility, a client program might want to support `linux,stdout-path` if a `stdout-path` property is not present. The meaning and use of the two properties is identical.

All other standard properties are allowed but are optional.]] .. M.get_type_definition("string"),
    ["linux,stdout-path"] = [[
# Devicetree Specification:

## Property Name: linux,stdout-path

## Path: /chosen/linux,stdout-path

## Usage: Optional

## Definition:

A string that specifies the full path to the node representing the device to be used for boot console output. If the character ":" is present in the value it terminates the path. The value may be an alias. If the stdin-path property is not specified, stdout-path should be assumed to define the input device.

Older versions of devicetrees may be encountered that contain a deprecated form of the `stdout-path` property called `linux,stdout-path`. For compatibility, a client program might want to support `linux,stdout-path` if a `stdout-path` property is not present. The meaning and use of the two properties is identical.

All other standard properties are allowed but are optional.]] .. M.get_type_definition("string"),
    ["stdin-path"] = [[
# Devicetree Specification:

## Property Name: stdin-path

## Path: /chosen/stdin-path

## Usage: Optional

## Definition:

A string that specifies the full path to the node representing the device to be used for boot console input. If the character ":" is present in the value it terminates the path. The value may be an alias.

All other standard properties are allowed but are optional.]] .. M.get_type_definition("string"),
}

local reserved_memory_property_markdown = {
    ["#address-cells"] = [[
# Devicetree Specification:

## Property Name: #address-cells

## Path: /reserved-memory/#address-cells

## Usage: Required

## Definition:

Specifies the number of `<u32>` cells to represent the address in the `reg` property in children of root.

`#address-cells` and `#size-cells` should use the same values as for the root node, and `ranges` should be empty so that address translation logic works correctly.]]
        .. M.get_type_definition("u32"),
    ["#size-cells"] = [[
# Devicetree Specification:

## Property Name: #size-cells

## Path: /reserved-memory/#size-cells

## Usage: Required

## Definition:

Specifies the number of `<u32>` cells to represent the size in the `reg` property in children of root.

`#address-cells` and `#size-cells` should use the same values as for the root node, and `ranges` should be empty so that address translation logic works correctly.]]
        .. M.get_type_definition("u32"),
    ranges = [[
# Devicetree Specification:

## Property Name: ranges

## Path: /reserved-memory/ranges

## Usage: Required

## Definition:

This property represents the mapping between parent address to child address spaces.

`#address-cells` and `#size-cells` should use the same values as for the root node, and `ranges` should be empty so that address translation logic works correctly.]]
        .. M.get_type_definition("prop_encoded_array"),
}

local reserved_memory_region_property_markdown = {
    reg = M.dedent([[
        # Devicetree Specification:

        ## Property Name: reg

        ## Path: %s/reg

        ## Usage: Optional

        ## Definition:

        Consists of an arbitrary number of address and size pairs that specify the physical address and size of the memory ranges.

        A reserved memory node requires either a `reg` property for static allocations, or a `size` property for dynamics allocations. Dynamic allocations may use `alignment` and `alloc-ranges` properties to constrain where the memory is allocated from. If both `reg` and `size` are present, then the region is treated as a static allocation with the `reg` property taking precedence and `size` is ignored.

        All other standard properties are allowed but are optional.]])
        .. M.get_type_definition("prop_encoded_array"),
    size = M.dedent([[
        # Devicetree Specification:

        ## Property Name: size

        ## Path: %s/size

        ## Usage: Optional

        ## Definition:

        Size in bytes of memory to reserve for dynamically allocated regions. Size of this property is based on parent node's `#size-cells` property.

        A reserved memory node requires either a `reg` property for static allocations, or a `size` property for dynamics allocations. Dynamic allocations may use `alignment` and `alloc-ranges` properties to constrain where the memory is allocated from. If both `reg` and `size` are present, then the region is treated as a static allocation with the `reg` property taking precedence and `size` is ignored.

        All other standard properties are allowed but are optional.]])
        .. M.get_type_definition("prop_encoded_array"),
    alignment = M.dedent([[
        # Devicetree Specification:

        ## Property Name: alignment

        ## Path: %s/alignment

        ## Usage: Optional

        ## Definition:

        Address boundary for alignment of allocation. Size of this property is based on parent node's `#size-cells` property.

        A reserved memory node requires either a `reg` property for static allocations, or a `size` property for dynamics allocations. Dynamic allocations may use `alignment` and `alloc-ranges` properties to constrain where the memory is allocated from. If both `reg` and `size` are present, then the region is treated as a static allocation with the `reg` property taking precedence and `size` is ignored.

        All other standard properties are allowed but are optional.]])
        .. M.get_type_definition("prop_encoded_array"),
    ["alloc-ranges"] = M.dedent([[
        # Devicetree Specification:

        ## Property Name: alloc-ranges

        ## Path: %s/alloc-ranges

        ## Usage: Optional

        ## Definition:

        Specifies regions of memory that are acceptable to allocate from. Format is (address, length pairs) tuples in same format as for `reg` properties.

        A reserved memory node requires either a `reg` property for static allocations, or a `size` property for dynamics allocations. Dynamic allocations may use `alignment` and `alloc-ranges` properties to constrain where the memory is allocated from. If both `reg` and `size` are present, then the region is treated as a static allocation with the `reg` property taking precedence and `size` is ignored.

        All other standard properties are allowed but are optional.]])
        .. M.get_type_definition("prop_encoded_array"),
    compatible = M.dedent([[
        # Devicetree Specification:

        ## Property Name: compatible

        ## Path: %s/compatible

        ## Usage: Optional

        ## Definition:

        May contain the following strings:
        - `shared-dma-pool`: This indicates a region of memory meant to be used as a shared pool of DMA buffers for a set of devices. It can be used by an operating system to instantiate the necessary pool management subsystem if necessary.
        - vendor specific string in the form `<vendor>,[<device>-]<usage>`

        All other standard properties are allowed but are optional.]]) .. M.get_type_definition("stringlist"),
    ["no-map"] = M.dedent([[
        # Devicetree Specification:

        ## Property Name: no-map

        ## Path: %s/no-map

        ## Usage: Optional

        ## Definition:

        If present, indicates the operating system must not create a virtual mapping of the region as part of its standard mapping of system memory, nor permit speculative access to it under any circumstances other than under the control of the device driver using the region.

        The `no-map` and `reusable` properties are mutually exclusive and both must not be used together in the same node.

        All other standard properties are allowed but are optional.]]) .. M.get_type_definition("empty"),
    reusable = M.dedent([[
        # Devicetree Specification:

        ## Property Name: reusable

        ## Path: %s/reusable

        ## Usage: Optional

        ## Definition:

        The operating system can use the memory in this region with the limitation that the device driver(s) owning the region need to be able to reclaim it back. Typically that means that the operating system can use that region to store volatile or cached data that can be otherwise regenerated or migrated elsewhere.

        The `no-map` and `reusable` properties are mutually exclusive and both must not be used together in the same node.

        All other standard properties are allowed but are optional.]]) .. M.get_type_definition("empty"),
    ["linux,cma-default"] = M.dedent([[
        # Devicetree Specification:

        ## Property Name: linux,cma-default

        ## Path: %s/linux,cma-default

        ## Usage: Optional

        ## Definition:

        If present, then Linux will use the region for the default pool of the contiguous memory allocator.

        All other standard properties are allowed but are optional.]]) .. M.get_type_definition("empty"),
    ["linux,dma-default"] = M.dedent([[
        # Devicetree Specification:

        ## Property Name: linux,dma-default

        ## Path: %s/linux,dma-default

        ## Usage: Optional

        ## Definition:

        If present, then Linux will use the region for the default pool of the consistent DMA allocator.

        All other standard properties are allowed but are optional.]]) .. M.get_type_definition("empty"),
}

local memory_region_property_markdown = {
    ["memory-region"] = M.dedent([[
        # Devicetree Specification:

        ## Property Name: memory-region

        ## Path: %s/memory-region

        ## Usage: Optional

        ## Definition:

        phandle, specifier pairs to children of `/reserved-memory`
    ]]) .. M.get_type_definition("prop_encoded_array"),
    ["memory-region-names"] = M.dedent([[
        # Devicetree Specification:

        ## Property Name: memory-region-names

        ## Path: %s/memory-region-names

        ## Usage: Optional

        ## Definition:

        A list of names, one for each corresponding entry in the `memory-region` property
    ]]) .. M.get_type_definition("stringlist"),
}

local phandle_definition = M.dedent(
    [[
    The `phandle` property specifies a numerical identifier for a node that is unique within the devicetree. The `phandle` property value is used by other nodes that need to refer to the node associated with the property.

    ## Example:

    See the following devicetree excerpt:

    ```dts
    pic@10000000 {
        phandle = <1>;
        interrupt-controller;
        reg = <0x10000000 0x100>;
    };
    ```

    A `phandle` value of 1 is defined. Another device node could reference the pic node with a phandle value of 1:

    ```dts
    another-device-node {
        interrupt-parent = <1>;
    };
    ```

    Note: Older versions of devicetrees may be encountered that contain a deprecated form of this property called `linux,phandle`. For compatibility, a client program might want to support `linux,phandle` if a `phandle` property is not present. The meaning and use of the two properties is identical.

    Note: Most devicetrees in `DTS (Device Tree Syntax)` will not contain explicit phandle properties. The DTC tool automatically inserts the `phandle` properties when the DTS is compiled into the binary DTB format.]]
)

local cells_definition = M.dedent(
    [[
    The `#address-cells` and `#size-cells` properties may be used in any device node that has children in the devicetree hierarchy and describes how child device nodes should be addressed. The `#address-cells` property defines the number of `<u32>` cells used to encode the address field in a child node's `reg` property. The `#size-cells` property defines the number of `<u32>` cells used to encode the size field in a child node’s `reg` property.

    The `#address-cells` and `#size-cells` properties are not inherited from ancestors in the devicetree. They shall be explicitly defined.

    A DTSpec-compliant boot program shall supply `#address-cells` and `#size-cells` on all nodes that have children.

    If missing, a client program should assume a default value of 2 for `#address-cells`, and a value of 1 for `#size-cells`.

    ## Example:

    See the following devicetree excerpt:

    ```dts
    soc {
        #address-cells = <1>;
        #size-cells = <1>;

        serial@4600 {
            compatible = "ns16550";
            reg = <0x4600 0x100>;
            clock-frequency = <0>;
            interrupts = <0xA 0x8>;
            interrupt-parent = <&ipic>;
        };
    };
    ```

    In this example, the `#address-cells` and `#size-cells` properties of the `soc` node are both set to 1. This setting specifies that one cell is required to represent an address and one cell is required to represent the size of nodes that are children of this node.

    The serial device `reg` property necessarily follows this specification set in the parent (`soc`) node—the address is represented by a single cell (0x4600), and the size is represented by a single cell (0x100).]]
)

local ranges_value_type =
    "`<empty>` or `<prop-encoded-array>` encoded as an arbitrary number of (`child-bus-address`, `parent-bus-address`, `length`) triplets."

local nexus_property_markdown = {
    ["interrupt-map"] = M.dedent(
        [[
        # Devicetree Specification:

        ## Property Name: interrupt-map

        ## Value type: `<prop-encoded-array>` encoded as an arbitrary number of interrupt mapping entries.

        ## Definition:

        An `interrupt-map` is a property on a nexus node that bridges one interrupt domain with a set of parent interrupt domains and specifies how interrupt specifiers in the child domain are mapped to their respective parent domains.

        The interrupt map is a table where each row is a mapping entry consisting of five components: `child unit address`, `child interrupt specifier`, `interrupt-parent`, `parent unit address`, `parent interrupt specifier`.

        ### child unit address

        The unit address of the child node being mapped. The number of 32-bit cells required to specify this is described by the `#address-cells` property of the bus node on which the child is located.

        ### child interrupt specifier

        The interrupt specifier of the child node being mapped. The number of 32-bit cells required to specify this component is described by the `#interrupt-cells` property of this node—the nexus node containing the `interrupt-map` property.

        ### interrupt-parent

        A single `<phandle>` value that points to the interrupt parent to which the child domain is being mapped.

        ### parent unit address

        The unit address in the domain of the interrupt parent. The number of 32-bit cells required to specify this address is described by the `#address-cells` property of the node pointed to by the interrupt-parent field.

        ### parent interrupt specifier

        The interrupt specifier in the parent domain. The number of 32-bit cells required to specify this component is described by the `#interrupt-cells` property of the node pointed to by the interrupt-parent field.

        Lookups are performed on the interrupt mapping table by matching a unit-address/interrupt specifier pair against the child components in the interrupt-map. Because some fields in the unit interrupt specifier may not be relevant, a mask is applied before the lookup is done. This mask is defined in the `interrupt-map-mask` property.

        Note: Both the child node and the interrupt parent node are required to have `#address-cells` and `#interrupt-cells` properties defined. If a unit address component is not required, `#address-cells` shall be explicitly defined to be zero.]]
    ) .. M.get_type_definition("prop_encoded_array"),
    ["interrupt-map-mask"] = M.dedent(
        [[
        # Devicetree Specification:

        ## Property Name: interrupt-map-mask

        ## Value type: `<prop-encoded-array>` encoded as a bit mask

        ## Definition:

        An `interrupt-map-mask` property is specified for a nexus node in the interrupt tree. This property specifies a mask that is ANDed with the incoming unit interrupt specifier being looked up in the table specified in the `interrupt-map` property.]]
    ) .. M.get_type_definition("prop_encoded_array"),
}

local specifier_cells_markdown = M.dedent([[
    # Devicetree Specification:

    ## Property Name: #%s-cells

    ## Definition:

    The `#<specifier>-cells` property defines the number of cells required to encode a specifier for a domain.]]) .. M.get_type_definition(
    "u32"
)

local specifier_map_markdown = M.dedent(
    [[
    # Devicetree Specification:

    ## Property Name: %s-map

    ## Value type: `<prop-encoded-array>` encoded as an arbitrary number of specifier mapping entries.

    ## Definition:

    A *<specifier>-map* is a property in a nexus node that bridges one specifier domain with a set of parent specifier domains and describes how specifiers in the child domain are mapped to their respective parent domains.

    The map is a table where each row is a mapping entry consisting of three components: *child specifier*, *specifier parent*, and *parent specifier*.

    ### child specifier

    The specifier of the child node being mapped. The number of 32-bit cells required to specify this component is described by the *#<specifier>-cells* property of this node—the nexus node containing the *<specifier>-map* property.

    ### specifier parent

    A single *<phandle>* value that points to the specifier parent to which the child domain is being mapped.

    ### parent specifier

    The specifier in the parent domain. The number of 32-bit cells required to specify this component is described by the *#<specifier>-cells* property of the specifier parent node.

    ---

    Lookups are performed on the mapping table by matching a specifier against the child specifier in the map. Because some fields in the specifier may not be relevant or need to be modified, a mask is applied before the lookup is done. This mask is defined in the *<specifier>-map-mask* property.

    Similarly, when the specifier is mapped, some fields in the unit specifier may need to be kept unmodified and passed through from the child node to the parent node. In this case, a *<specifier>-map-pass-thru* property may be specified to apply a mask to the child specifier and copy any bits that match to the parent unit specifier.]]
) .. M.get_type_definition("prop_encoded_array")

local specifier_map_mask_markdown = M.dedent(
    [[
    # Devicetree Specification:

    ## Property Name: %s-map-mask

    ## Value type: `<prop-encoded-array>` encoded as a bit mask

    ## Definition:

    A `<specifier>-map-mask` property may be specified for a nexus node. This property specifies a mask that is ANDed with the child unit specifier being looked up in the table specified in the `<specifier>-map` property. If this property is not specified, the mask is assumed to be a mask with all bits set.]]
) .. M.get_type_definition("prop_encoded_array")

local specifier_map_pass_thru_markdown = M.dedent(
    [[
    # Devicetree Specification:

    ## Property Name: %s-map-pass-thru

    ## Value type: `<prop-encoded-array>` encoded as a bit mask

    ## Definition:

    A `<specifier>-map-pass-thru` property may be specified for a nexus node. This property specifies a mask that is applied to the child unit specifier being looked up in the table specified in the `<specifier>-map` property. Any matching bits in the child unit specifier are copied over to the parent specifier. If this property is not specified, the mask is assumed to be a mask with no bits set.]]
) .. M.get_type_definition("prop_encoded_array")

local standard_property_markdown = {
    interrupts = M.dedent([[
        # Devicetree Specification:

        ## Property Name: interrupts

        ## Value type: `<prop-encoded-array>` encoded as arbitrary number of interrupt specifiers

        ## Definition:

        The `interrupts` property of a device node defines the interrupt or interrupts that are generated by the device. The value of the `interrupts` property consists of an arbitrary number of interrupt specifiers. The format of an interrupt specifier is defined by the binding of the interrupt domain root.

        `interrupts` is overridden by the `interrupts-extended` property and normally only one or the other should be used.

        ## Example:

        A common definition of an interrupt specifier in an open PIC–compatible interrupt domain consists of two cells; an interrupt number and level/sense information. See the following example, which defines a single interrupt specifier, with an interrupt number of 0xA and level/sense encoding of 8.

        `interrupts = <0xA 8>;`]]) .. M.get_type_definition("prop_encoded_array"),
    ["interrupt-parent"] = M.dedent(
        [[
        # Devicetree Specification:

        ## Property Name: interrupt-parent

        ## Definition:

        Because the hierarchy of the nodes in the interrupt tree might not match the devicetree, the `interrupt-parent` property is available to make the definition of an interrupt parent explicit. The value is the phandle to the interrupt parent. If this property is missing from a device, its interrupt parent is assumed to be its devicetree parent.]]
    ) .. M.get_type_definition("phandle"),
    ["interrupts-extended"] = M.dedent(
        [[
        # Devicetree Specification:

        ## Property Name: interrupts-extended

        ## Definition:

        The `interrupts-extended` property lists the interrupt(s) generated by a device. `interrupts-extended` should be used instead of `interrupts` when a device is connected to multiple interrupt controllers as it encodes a parent phandle with each interrupt specifier.

        ## Example:

        This example shows how a device with two interrupt outputs connected to two separate interrupt controllers would describe the connection using an `interrupts-extended` property. `pic` is an interrupt controller with an `#interrupt-cells` specifier of 2, while `gic` is an interrupt controller with an `#interrupts-cells` specifier of 1.

        `interrupts-extended = <&pic 0xA 8>, <&gic 0xda>;`

        The `interrupts` and `interrupts-extended` properties are mutually exclusive. A device node should use one or the other, but not both. Using both is only permissible when required for compatibility with software that does not understand `interrupts-extended`. If both `interrupts-extended` and `interrupts` are present then `interrupts-extended` takes precedence.]]
    )
        .. M.get_type_definition("phandle")
        .. M.get_type_definition("prop_encoded_array"),
    ["#interrupt-cells"] = M.dedent(
        [[
        # Devicetree Specification:

        ## Property Name: #interrupt-cells

        ## Definition:

        The `#interrupt-cells` property defines the number of cells required to encode an interrupt specifier for an interrupt domain.]]
    ) .. M.get_type_definition("u32"),
    ["interrupt-controller"] = M.dedent([[
        # Devicetree Specification:

        ## Property Name: interrupt-controller

        ## Definition:

        The presence of an `interrupt-controller` property defines a node as an interrupt controller node.]])
        .. M.get_type_definition("empty"),
    compatible = M.dedent(
        [[
        # Devicetree Specification:

        ## Property Name: compatible

        ## Definition:

        The `compatible` property value consists of one or more strings that define the specific programming model for the device. This list of strings should be used by a client program for device driver selection. The property value consists of a concatenated list of null-terminated strings, from most specific to most general. They allow a device to express its compatibility with a family of similar devices, potentially allowing a single device driver to match against several devices.

        The recommended format is `"manufacturer,model"`, where `manufacturer` is a string describing the name of the manufacturer (such as a stock ticker symbol), and `model` specifies the model number.

        The compatible string should consist only of lowercase letters, digits, and dashes, and should start with a letter. A single comma is typically only used following a vendor prefix. Underscores should not be used.

        ## Example:

        `compatible = "fsl,mpc8641", "ns16550";`

        In this example, an operating system would first try to locate a device driver that supported fsl,mpc8641. If a driver was not found, it would then try to locate a driver that supported the more general ns16550 device type.]]
    ) .. M.get_type_definition("stringlist"),
    model = M.dedent([[
        # Devicetree Specification:

        ## Property Name: model

        ## Definition:

        The model property value is a `<string>` that specifies the manufacturer’s model number of the device.

        The recommended format is: `"manufacturer,model"`, where `manufacturer` is a string describing the name of the manufacturer (such as a stock ticker symbol), and model specifies the model number.

        ## Example:

        `model = "fsl,MPC8349EMITX";`]]) .. M.get_type_definition("string"),
    phandle = "# Devicetree Specification:\n\n## Property Name: phandle\n\n## Definition:\n\n"
        .. phandle_definition
        .. M.get_type_definition("u32"),
    ["linux,phandle"] = "# Devicetree Specification:\n\n## Property Name: linux,phandle\n\n## Definition:\n\n"
        .. phandle_definition
        .. M.get_type_definition("u32"),
    status = M.dedent(
        [[
        # Devicetree Specification:

        ## Property Name: status

        ## Definition:

        The `status` property indicates the operational status of a device.  The lack of a `status` property should be treated as if the property existed with the value of `"okay"`.

        Valid values are:
        - `"okay"`: Indicates the device is operational.
        - `"disabled"`: Indicates that the device is not presently operational, but it might become operational in the future (for example, something is not plugged in, or switched off). Refer to the device binding for details on what disabled means for a given device.
        - `"reserved"`: Indicates that the device is operational, but should not be used. Typically this is used for devices that are controlled by another software component, such as platform firmware.
        - `"fail"`: Indicates that the device is not operational. A serious error was detected in the device, and it is unlikely to become operational without repair.
        - `"fail-sss"`: Indicates that the device is not operational. A serious error was detected in the device and it is unlikely to become operational without repair. The `sss` portion of the value is specific to the device and indicates the error condition detected.]]
    ) .. M.get_type_definition("string"),
    ["#address-cells"] = "# Devicetree Specification:\n\n## Property Name: #address-cells\n\n## Definition:\n\n"
        .. cells_definition
        .. M.get_type_definition("u32"),
    ["#size-cells"] = "# Devicetree Specification:\n\n## Property Name: #size-cells\n\n## Definition:\n\n"
        .. cells_definition
        .. M.get_type_definition("u32"),
    reg = M.dedent([[
        # Devicetree Specification:

        ## Property Name: reg

        ## Property value: `<prop-encoded-array>` encoded as an arbitrary number of (`address`, `length`) pairs.

        ## Definition:

        The `reg` property describes the address of the device’s resources within the address space defined by its parent bus. Most commonly this means the offsets and lengths of memory-mapped IO register blocks, but may have a different meaning on some bus types. Addresses in the address space defined by the root node are CPU real addresses.

        The value is a `<prop-encoded-array>`, composed of an arbitrary number of pairs of address and length, `<address length>`. The number of `<u32>` cells required to specify the address and length are bus-specific and are specified by the `#address-cells` and `#size-cells` properties in the parent of the device node. If the parent node specifies a value of 0 for `#size-cells`, the length field in the value of `reg` shall be omitted.

        ## Example:

        Suppose a device within a system-on-a-chip had two blocks of registers, a 32-byte block at offset 0x3000 in the SOC and a 256-byte block at offset 0xFE00. The `reg` property would be encoded as follows (assuming `#address-cells` and `#size-cells` values of 1):

        `reg = <0x3000 0x20 0xFE00 0x100>;`]]) .. M.get_type_definition("prop_encoded_array"),
    ["virtual-reg"] = M.dedent(
        [[
        # Devicetree Specification:

        ## Property Name: virtual-reg

        ## Definition:

        The `virtual-reg` property specifies an effective address that maps to the first physical address specified in the `reg` property of the device node. This property enables boot programs to provide client programs with virtual-to-physical mappings that have been set up.]]
    ) .. M.get_type_definition("u32"),
    ranges = M.dedent(
        [[
        # Devicetree Specification:

        ## Property Name: ranges

        ## Value type: %s

        ## Definition:

        The `ranges` property provides a means of defining a mapping or translation between the address space of the bus (the child address space) and the address space of the bus node’s parent (the parent address space).

        The format of the value of the `ranges` property is an arbitrary number of triplets of (`child-bus-address`, `parent-bus-address`, `length`)
        - The `child-bus-address` is a physical address within the child bus' address space. The number of cells to represent the address is bus dependent and can be determined from the `#address-cells` of this node (the node in which the `ranges` property appears).
        - The `parent-bus-address` is a physical address within the parent bus' address space. The number of cells to represent the parent address is bus dependent and can be determined from the `#address-cells` property of the node that defines the parent’s address space.
        - The `length` specifies the size of the range in the child’s address space. The number of cells to represent the size can be determined from the `#size-cells` of this node (the node in which the `ranges` property appears).

        If the property is defined with an `<empty>` value, it specifies that the parent and child address space is identical, and no address translation is required.

        If the property is not present in a bus node, it is assumed that no mapping exists between children of the node and the parent address space.

        ## Address Translation Example:

        ```dts
        soc {
            compatible = "simple-bus";
            #address-cells = <1>;
            #size-cells = <1>;
            ranges = <0x0 0xe0000000 0x00100000>;

            serial@4600 {
                device_type = "serial";
                compatible = "ns16550";
                reg = <0x4600 0x100>;
                clock-frequency = <0>;
                interrupts = <0xA 0x8>;
                interrupt-parent = <&ipic>;
            };
        };
        ```

        The `soc` node specifies a `ranges` property of

        `<0x0 0xe0000000 0x00100000>;`

        This property value specifies that for a 1024 KB range of address space, a child node addressed at physical 0x0 maps to a parent address of physical 0xe0000000. With this mapping, the `serial` device node can be addressed by a load or store at address 0xe0004600, an offset of 0x4600 (specified in `reg`) plus the 0xe0000000 mapping specified in `ranges`.]]
    ):format(ranges_value_type)
        .. M.get_type_definition("empty")
        .. M.get_type_definition("prop_encoded_array"),
    ["dma-ranges"] = M.dedent(
        [[
        # Devicetree Specification:

        ## Property Name: dma-ranges

        ## Value type: %s

        ## Definition:

        The `dma-ranges` property is used to describe the direct memory access (DMA) structure of a memory-mapped bus whose devicetree parent can be accessed from DMA operations originating from the bus. It provides a means of defining a mapping or translation between the physical address space of the bus and the physical address space of the parent of the bus.

        The format of the value of the `dma-ranges` property is an arbitrary number of triplets of (`child-bus-address`, `parent-bus-address`, `length`). Each triplet specified describes a contiguous DMA address range.
        - The `child-bus-address` is a physical address within the child bus' address space. The number of cells to represent the address depends on the bus and can be determined from the `#address-cells` of this node (the node in which the `dma-ranges` property appears).
        - The `parent-bus-address` is a physical address within the parent bus' address space. The number of cells to represent the parent address is bus dependent and can be determined from the `#address-cells` property of the node that defines the parent’s address space.
        - The `length` specifies the size of the range in the child’s address space. The number of cells to represent the size can be determined from the `#size-cells` of this node (the node in which the dma-ranges property appears).]]
    ):format(ranges_value_type)
        .. M.get_type_definition("empty")
        .. M.get_type_definition("prop_encoded_array"),
    ["dma-coherent"] = M.dedent(
        [[
        # Devicetree Specification:

        ## Property Name: dma-coherent

        ## Definition:

        For architectures which are by default non-coherent for I/O, the `dma-coherent` property is used to indicate a device is capable of coherent DMA operations. Some architectures have coherent DMA by default and this property is not applicable.]]
    ) .. M.get_type_definition("empty"),
    ["dma-noncoherent"] = M.dedent(
        [[
        # Devicetree Specification:

        ## Property Name: dma-noncoherent

        ## Definition:

        For architectures which are by default coherent for I/O, the `dma-noncoherent` property is used to indicate a device is not capable of coherent DMA operations. Some architectures have non-coherent DMA by default and this property is not applicable.]]
    ) .. M.get_type_definition("empty"),
    name = M.dedent(
        [[
        # Devicetree Specification:

        ## Property Name: name

        ## Usage: Deprecated

        ## Definition:

        The `name` property is a string specifying the name of the node. This property is deprecated, and its use is not recommended. However, it might be used in older non-DTSpec-compliant devicetrees. Operating system should determine a node’s name based on the `node-name` component of the node name.]]
    ) .. M.get_type_definition("string"),
    device_type = M.dedent(
        [[
        # Devicetree Specification:

        ## Property Name: device_type

        ## Usage: Deprecated

        ## Definition:

        The `device_type` property was used in IEEE 1275 to describe the device’s FCode programming model. Because DTSpec does not have FCode, new use of the property is deprecated, and it should be included only on `cpu` and `memory` nodes for compatibility with IEEE 1275–derived devicetrees.]]
    ) .. M.get_type_definition("string"),
}

local status_value_definitions = {
    okay = "Indicates the device is operational.",
    disabled = "Indicates that the device is not presently operational, but it might become operational in the future (for example, something is not plugged in, or switched off). Refer to the device binding for details on what disabled means for a given device.",
    reserved = "Indicates that the device is operational, but should not be used. Typically this is used for devices that are controlled by another software component, such as platform firmware.",
    fail = "Indicates that the device is not operational. A serious error was detected in the device, and it is unlikely to become operational without repair.",
    ["fail-sss"] = "Indicates that the device is not operational. A serious error was detected in the device and it is unlikely to become operational without repair. The `sss` portion of the value is specific to the device and indicates the error condition detected.",
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

local function chapter4_property(title, name, details, type_name)
    local heading = title and " " .. title or ""
    return ("# Devicetree Specification:%s\n\n## Property Name: %s\n\n## Path: %%s/%s\n\n%s"):format(
        heading,
        name,
        name,
        details
    ) .. M.get_type_definition(type_name)
end

local miscellaneous_property_markdown = {
    ["clock-frequency"] = chapter4_property(
        "Miscellaneous Properties",
        "clock-frequency",
        "## Definition:\n\nSpecifies the frequency of a clock in Hz. The value is a `<prop-encoded-array>` in one of two forms:\n- a 32-bit integer consisting of one `<u32>` specifying the frequency.\n- a 64-bit integer represented as a `<u64>` specifying the frequency.",
        "prop_encoded_array"
    ),
    ["reg-shift"] = chapter4_property(
        "Miscellaneous Properties",
        "reg-shift",
        '## Definition:\n\nThe `reg-shift` property provides a mechanism to represent devices that are identical in most respects except for the number of bytes between registers. The `reg-shift` property specifies in bytes how far the discrete device registers are separated from each other. The individual register location is calculated by using following formula: "registers address" << reg-shift. If unspecified, the default value is 0.\n\nFor example, in a system where 16540 UART registers are located at addresses 0x0, 0x4, 0x8, 0xC, 0x10, 0x14, 0x18, and 0x1C, a `reg-shift = <2>` property would be used to specify register locations.',
        "u32"
    ),
    label = chapter4_property(
        "Miscellaneous Properties",
        "label",
        "## Definition:\n\nThe label property defines a human-readable string describing a device. The binding for a given device specifies the exact meaning of the property for that device.",
        "string"
    ),
}

local serial_node_markdown = [[# Devicetree Specification: Serial Class Binding

## Serial Class Binding

## Path: %s

The class of serial devices consists of various types of point-to-point serial line devices. Examples of serial line devices include the 8250 UART, 16550 UART, HDLC device, and BISYNC device. In most cases, hardware compatible with the RS-232 standard fits into the serial device class.

I2C and SPI (Serial Peripheral Interface) devices shall not be represented as serial port devices because they have their own specific representation.]]
local serial_property_markdown = {
    ["clock-frequency"] = chapter4_property(
        "Serial Class Binding",
        "clock-frequency",
        "## Definition:\n\nSpecifies the frequency in Hertz of the baud rate generator's input clock.\n\n## Example:\n\n`clock-frequency = <100000000>;`",
        "u32"
    ),
    ["current-speed"] = chapter4_property(
        "Serial Class Binding",
        "current-speed",
        "## Definition:\n\nSpecifies the current speed of a serial device in bits per second. A boot program should set this property if it has initialized the serial device.\n\n## Example:\n\n115,200 Baud: `current-speed = <115200>;`",
        "u32"
    ),
}

local ns16550_title = "National Semiconductor 16450/16550 Compatible UART"
local ns16550_node_markdown = [[# Devicetree Specification: National Semiconductor 16450/16550 Compatible UART

## National Semiconductor 16450/16550 Compatible UART

## Path: %s

Serial devices compatible to the National Semiconductor 16450/16550 UART (Universal Asynchronous Receiver Transmitter).]]
local ns16550_property_markdown = {
    compatible = chapter4_property(
        ns16550_title,
        "compatible",
        '## Usage: Required\n\n## Definition:\n\nValue shall include "ns16550".\n\nAll other standard properties are allowed but are optional.',
        "stringlist"
    ),
    ["clock-frequency"] = chapter4_property(
        ns16550_title,
        "clock-frequency",
        "## Usage: Required\n\n## Definition:\n\nSpecifies the frequency (in Hz) of the baud rate generator’s input clock.\n\nAll other standard properties are allowed but are optional.",
        "u32"
    ),
    ["current-speed"] = chapter4_property(
        ns16550_title,
        "current-speed",
        "## Usage: Optional but recommended\n\n## Definition:\n\nSpecifies current serial device speed in bits per second.\n\nAll other standard properties are allowed but are optional.",
        "u32"
    ),
    reg = chapter4_property(
        ns16550_title,
        "reg",
        "## Usage: Required\n\n## Definition:\n\nSpecifies the physical address of the registers device within the address space of the parent bus.\n\nAll other standard properties are allowed but are optional.",
        "prop_encoded_array"
    ),
    interrupts = chapter4_property(
        ns16550_title,
        "interrupts",
        "## Usage: Optional but recommended\n\n## Definition:\n\nSpecifies the interrupts generated by this device. The value of the interrupts property consists of one or more interrupt specifiers. The format of an interrupt specifier is defined by the binding document describing the node’s interrupt parent.\n\nAll other standard properties are allowed but are optional.",
        "prop_encoded_array"
    ),
    ["reg-shift"] = chapter4_property(
        ns16550_title,
        "reg-shift",
        '## Usage: Optional\n\n## Definition:\n\nSpecifies in bytes how far the discrete device registers are separated from each other. The individual register location is calculated by using following formula: `"registers address" << reg-shift`. If unspecified, the default value is 0.\n\nAll other standard properties are allowed but are optional.',
        "u32"
    ),
    ["virtual-reg"] = chapter4_property(
        ns16550_title,
        "virtual-reg",
        "## Usage: See definition\n\n## Definition:\n\nSpecifies an effective address that maps to the first physical address specified in the `reg` property. This property is required if this device node is the system’s console.\n\nAll other standard properties are allowed but are optional.",
        "u32"
    ),
}

local network_node_markdown = [[# Devicetree Specification: Network Class Binding

## Network Class Binding

## Path: %s

Network devices are packet oriented communication devices. Devices in this class are assumed to implement the data link layer (layer 2) of the seven-layer OSI model and use Media Access Control (MAC) addresses. Examples of network devices include Ethernet, FDDI, 802.11, and Token-Ring.]]
local network_property_markdown = {
    ["address-bits"] = chapter4_property(
        "Network Class Binding",
        "address-bits",
        "## Definition:\n\nSpecifies number of address bits required to address the device described by this node. This property specifies number of bits in MAC address. If unspecified, the default value is 48.\n\n## Example:\n\n`address-bits = <48>;`",
        "u32"
    ),
    ["local-mac-address"] = "# Devicetree Specification: Network Class Binding\n\n## Property Name: local-mac-address\n\n## Value type: `<prop-encoded-array>` encoded as an array of hex numbers.\n\n## Path: %s/local-mac-address\n\n## Definition:\n\nSpecifies MAC address that was assigned to the network device described by the node containing this property.\n\n## Example:\n\n`local-mac-address = [ 00 00 12 34 56 78 ];`"
        .. M.get_type_definition("prop_encoded_array"),
    ["mac-address"] = "# Devicetree Specification: Network Class Binding\n\n## Property Name: mac-address\n\n## Value type: `<prop-encoded-array>` encoded as an array of hex numbers.\n\n## Path: %s/mac-address\n\n## Definition:\n\nSpecifies the MAC address that was last used by the boot program. This property should be used in cases where the MAC address assigned to the device by the boot program is different from the local-mac-address property. This property shall be used only if the value differs from local-mac-address property value.\n\n## Example:\n\n`mac-address = [ 02 03 04 05 06 07 ];`"
        .. M.get_type_definition("prop_encoded_array"),
    ["max-frame-size"] = chapter4_property(
        "Network Class Binding",
        "max-frame-size",
        "## Definition:\n\nSpecifies maximum packet length in bytes that the physical interface can send and receive.\n\n## Example:\n\n`max-frame-size = <1518>;`",
        "u32"
    ),
    ["max-speed"] = chapter4_property(
        "Ethernet specific considerations",
        "max-speed",
        "## Definition:\n\nSpecifies maximum speed (specified in megabits per second) supported the device.\n\n## Example:\n\n`max-speed = <1000>;`",
        "u32"
    ),
    ["phy-connection-type"] = chapter4_property(
        "Ethernet specific considerations",
        "phy-connection-type",
        '## Definition:\n\nSpecifies interface type between the Ethernet device and a physical layer (PHY) device. The value of this property is specific to the implementation.\n\n## Example:\n\n`phy-connection-type = "mii";`\n\n## Possible Values:\n\n- `mii`        Media Independent Interface\n- `rmii`       Reduced Media Independent Interface\n- `gmii`       Gigabit Media Independent Interface\n- `rgmii`      Reduced Gigabit Media Independent\n- `rgmii-id`   rgmii with internal delay\n- `rgmii-txid` rgmii with internal delay on TX only\n- `rgmii-rxid` rgmii with internal delay on RX only\n- `tbi`        Ten Bit Interface\n- `rtbi`       Reduced Ten Bit Interface\n- `smii`       Serial Media Independent Interface\n- `sgmii`      Serial Gigabit Media Independent Interface\n- `rev-mii`    Reverse Media Independent Interface\n- `xgmii`      10 Gigabits Media Independent Interface\n- `moca`       Multimedia over Coaxial\n- `qsgmii`     Quad Serial Gigabit Media Independent Interface\n- `trgmii`     Turbo Reduced Gigabit Media Independent Interface',
        "string"
    ),
    ["phy-handle"] = chapter4_property(
        "Ethernet specific considerations",
        "phy-handle",
        "## Definition:\n\nSpecifies a reference to a node representing a physical layer (PHY) device connected to this Ethernet device. This property is required in case where the Ethernet device is connected to a physical layer device.\n\n## Example:\n\n`phy-handle = <&PHY0>;`",
        "phandle"
    ),
}

local open_pic_title = "Power ISA Open PIC Interrupt Controller"
local open_pic_node_markdown = [[# Devicetree Specification: Power ISA Open PIC Interrupt Controller

## Power ISA Open PIC Interrupt Controller

## Path: %s

An Open PIC interrupt controller implements the Open PIC architecture (developed jointly by AMD and Cyrix) and specified in The Open Programmable Interrupt Controller (PIC) Register Interface Specification Revision 1.2.

Interrupt specifiers in an Open PIC interrupt domain are encoded with two cells. The first cell defines the interrupt number. The second cell defines the sense and level information.

Sense and level information shall be encoded as follows in interrupt specifiers:
```
0 = low to high edge sensitive type enabled
1 = active low level sensitive type enabled
2 = active high level sensitive type enabled
3 = high to low edge sensitive type enabled
```]]
local open_pic_property_markdown = {
    compatible = chapter4_property(
        open_pic_title,
        "compatible",
        '## Usage: Required\n\n## Definition:\n\nValue shall include `"open-pic"`.\n\nAll other standard properties are allowed but are optional.',
        "string"
    ),
    reg = chapter4_property(
        open_pic_title,
        "reg",
        "## Usage: Required\n\n## Definition:\n\nSpecifies the physical address of the registers device within the address space of the parent bus.\n\nAll other standard properties are allowed but are optional.",
        "prop_encoded_array"
    ),
    ["interrupt-controller"] = chapter4_property(
        open_pic_title,
        "interrupt-controller",
        "## Usage: Required\n\n## Definition:\n\nSpecifies that this node is an interrupt controller.\n\nAll other standard properties are allowed but are optional.",
        "empty"
    ),
    ["#interrupt-cells"] = chapter4_property(
        open_pic_title,
        "#interrupt-cells",
        "## Usage: Required\n\n## Definition:\n\nShall be 2.\n\nAll other standard properties are allowed but are optional.",
        "u32"
    ),
    ["#address-cells"] = chapter4_property(
        open_pic_title,
        "#address-cells",
        "## Usage: Required\n\n## Definition:\n\nShall be 0.\n\nAll other standard properties are allowed but are optional.",
        "u32"
    ),
}

local simple_bus_node_markdown = [[# Devicetree Specification: simple-bus Bindings

## `simple-bus` Node

## Path: %s

System-on-a-chip processors may have an internal I/O bus that cannot be probed for devices. The devices on the bus can be accessed directly without additional configuration required. This type of bus is represented as a node with a compatible value of "simple-bus".]]
local simple_bus_property_markdown = {
    compatible = chapter4_property(
        nil,
        "compatible",
        '## Usage: Required\n\n## Definition:\n\nValue shall include "simple-bus".',
        "string"
    ),
    ranges = chapter4_property(
        nil,
        "ranges",
        "## Usage: Required\n\n## Definition:\n\nThis property represents the mapping between parent address to child address spaces.",
        "prop_encoded_array"
    ),
    ["nonposted-mmio"] = chapter4_property(
        nil,
        "nonposted-mmio",
        "## Usage: Optional\n\n## Definition:\n\nSpecifies that direct children of this bus should use non-posted memory accesses (i.e. a non-posted mapping mode) for MMIO ranges.",
        "empty"
    ),
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

local function string_property_value_at_cursor(ctx, property_name)
    local line = read_lines(ctx.file)[ctx.row]
    if not line or not line:match("^%s*" .. property_name .. "%s*=") then
        return nil
    end

    local value_start, value_end, value = line:find('"([^"]+)"')
    if value and ctx.col > value_start and ctx.col < value_end then
        return value
    end
end

function M.hover(ctx)
    local line = read_lines(ctx.file)[ctx.row]
    if M.in_top_level(ctx) and line then
        local directive_start, directive_end = line:find("/dts%-v1/")
        if directive_start and ctx.col >= directive_start and ctx.col <= directive_end then
            return dts_v1_markdown
        end

        directive_start, directive_end = line:find("/memreserve/")
        if directive_start and ctx.col >= directive_start and ctx.col <= directive_end then
            return memreserve_markdown
        end
    end

    local label = label_definition_at_cursor(ctx)
    if label then
        local bounds = containing_node(ctx.file, ctx.row)
        return label_markdown:format("Definitions", label, bounds.path)
    end

    label = label_reference_at_cursor(ctx)
    if label then
        local bounds = find_node_label_bounds(ctx, label)
        if bounds then
            return label_markdown:format("References", label, bounds.path)
        end
    end

    if M.on_a_root_node(ctx) then
        return root_node_markdown
    end

    if M.on_an_aliases_node(ctx) then
        return aliases_node_markdown
    end

    if M.on_a_cpus_node(ctx) then
        return cpus_node_markdown
    end

    if M.on_a_cache_node(ctx) then
        local path = cache_node_path(ctx)
        return cache_node_markdown:format(path, path)
    end

    if M.on_a_cpu_node(ctx) then
        return cpu_node_markdown
    end

    if M.on_a_memory_node(ctx) then
        return memory_node_markdown:format(cache_node_path(ctx))
    end

    if M.on_a_chosen_node(ctx) then
        return chosen_node_markdown
    end

    if M.on_a_reserved_memory_node(ctx) then
        return reserved_memory_node_markdown
    end

    if M.on_a_reserved_memory_region_node(ctx) then
        return reserved_memory_region_node_markdown:format(reserved_memory_region_path(ctx))
    end

    local node_path = cache_node_path(ctx)
    if M.on_a_ns16550_node(ctx) then
        return ns16550_node_markdown:format(node_path)
    end
    if M.on_a_serial_device_node(ctx) then
        return serial_node_markdown:format(node_path)
    end
    if M.on_a_network_device_node(ctx) then
        return network_node_markdown:format(node_path)
    end
    if M.on_an_open_pic_node(ctx) then
        return open_pic_node_markdown:format(node_path)
    end
    if M.on_a_simple_bus_node(ctx) then
        return simple_bus_node_markdown:format(node_path)
    end

    if M.in_an_aliases_node(ctx) then
        local alias = property_name_at_cursor(ctx)
        if alias then
            return ("# Anakin's Advice:\n\n## Path: /aliases/%s\n\nA client program, such as Linux, Zephyr, or U-Boot, can look up the alias `%s` to refer to this node."):format(
                alias,
                alias
            )
        end
    end

    if M.in_a_cache_node(ctx) then
        local property_name = property_name_at_cursor(ctx)
        local markdown = cache_property_markdown[property_name]
        if markdown then
            return markdown:format(cache_node_path(ctx))
        end
        return cpu_property_markdown[property_name]
    end

    if M.in_a_cpu_node(ctx) then
        local property_name = property_name_at_cursor(ctx)
        if property_name and property_name:match("^power%-isa%-.+") and property_name ~= "power-isa-version" then
            return cpu_property(property_name, "Optional", power_isa_category_definition, "empty")
        end
        return cpu_property_markdown[property_name]
    end

    if M.in_a_cpus_node(ctx) then
        local property_name = property_name_at_cursor(ctx)
        local markdown = cpus_property_markdown[property_name]
        if markdown then
            return markdown
        end
    end

    if M.in_a_memory_node(ctx) then
        local property_name = property_name_at_cursor(ctx)
        local markdown = memory_property_markdown[property_name]
        return markdown and markdown:gsub("/memory/", cache_node_path(ctx) .. "/", 1)
    end

    if M.in_a_chosen_node(ctx) then
        local property_name = property_name_at_cursor(ctx)
        return chosen_property_markdown[property_name]
    end

    if M.in_a_reserved_memory_region_node(ctx) then
        local property_name = property_name_at_cursor(ctx)
        local markdown = reserved_memory_region_property_markdown[property_name]
        if markdown then
            return markdown:format(reserved_memory_region_path(ctx))
        end
    end

    if M.in_a_reserved_memory_node(ctx) then
        local property_name = property_name_at_cursor(ctx)
        return reserved_memory_property_markdown[property_name]
    end

    local property_name = property_name_at_cursor(ctx)
    local chapter4_markdown
    if M.in_a_ns16550_node(ctx) then
        chapter4_markdown = ns16550_property_markdown[property_name]
    elseif M.in_a_serial_device_node(ctx) then
        chapter4_markdown = serial_property_markdown[property_name]
    elseif M.in_a_network_device_node(ctx) then
        chapter4_markdown = network_property_markdown[property_name]
    elseif M.in_an_open_pic_node(ctx) then
        chapter4_markdown = open_pic_property_markdown[property_name]
    elseif M.in_a_simple_bus_node(ctx) then
        chapter4_markdown = simple_bus_property_markdown[property_name]
    end
    chapter4_markdown = chapter4_markdown or miscellaneous_property_markdown[property_name]
    if chapter4_markdown then
        return chapter4_markdown:format(node_path)
    end

    if M.in_possible_memory_region_consumer(ctx) then
        local markdown = memory_region_property_markdown[property_name]
        if markdown then
            return markdown:format(possible_memory_region_consumer_path(ctx))
        end
    end

    local in_descendant_node = in_node(ctx, function(stack)
        return #stack > 1
    end)
    if M.in_a_root_node(ctx) and not in_descendant_node then
        for root_property_name, markdown in pairs(root_property_markdown) do
            if on_a_property_name(ctx, root_property_name) then
                return markdown
            end
        end
    end

    local status_value = string_property_value_at_cursor(ctx, "status")
    local status_definition = status_value_definitions[status_value]
    if status_definition then
        return ("# Devicetree Specification:\n\n## Property Value: %s\n\n## Path: %s\n\n## Definition:\n\n%s"):format(
            status_value,
            property_path(ctx, "status"),
            status_definition
        )
    end

    local nexus_markdown = nexus_property_markdown[property_name]
    local standard_markdown = standard_property_markdown[property_name]
    if standard_markdown and not nexus_markdown then
        return with_path(standard_markdown, property_path(ctx, property_name))
    end

    for _, node_property in ipairs(M.list_node_properties(ctx)) do
        local specifier = node_property:match("^#([^#]+)%-cells$")
        if specifier and specifier ~= "address" and specifier ~= "size" then
            if nexus_markdown then
                return with_path(nexus_markdown, property_path(ctx, property_name))
            end

            if property_name == node_property then
                return with_path(specifier_cells_markdown:format(specifier), property_path(ctx, property_name))
            elseif property_name == specifier .. "-map" then
                return with_path(specifier_map_markdown:format(specifier), property_path(ctx, property_name))
            elseif property_name == specifier .. "-map-mask" then
                return with_path(specifier_map_mask_markdown:format(specifier), property_path(ctx, property_name))
            elseif property_name == specifier .. "-map-pass-thru" then
                return with_path(specifier_map_pass_thru_markdown:format(specifier), property_path(ctx, property_name))
            end
        end
    end

    local markdown = standard_property_markdown[property_name]
    return markdown and with_path(markdown, property_path(ctx, property_name))
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
    send_response(server, msg.id, {
        capabilities = {
            textDocumentSync = {
                openClose = true,
                change = 0,
                save = true,
            },
            hoverProvider = true,
            definitionProvider = true,
            implementationProvider = true,
        },
    })
end

default_handlers["initialized"] = function(_, _) end

local function publish_diagnostics(server, uri)
    send_notification(server, "textDocument/publishDiagnostics", {
        uri = uri,
        diagnostics = json.array(M.get_diagnostics(uri_to_path(uri))),
    })
end

default_handlers["textDocument/didOpen"] = function(server, msg)
    local params = msg.params or {}
    local uri = (params.textDocument or {}).uri
    local ctx = {
        file = uri_to_path(uri),
        workspace_root = server.workspace_root,
    }

    if M.out_of_tree_without_config(ctx) then
        send_notification(server, "window/showMessage", {
            type = 2,
            message = "Out-of-tree devicetree detected, but no .anakins-dtls was found.\n"
                .. "In a Yocto project you can generate one with:\n"
                .. "```sh\n"
                .. "bitbake-getvar S -r virtual/kernel > .anakins-dtls\n"
                .. "```\n"
                .. "For buildroot run the following command:\n"
                .. "```sh\n"
                .. "make -s --no-print-directory printvars VARS=LINUX_DIR > .anakins-dtls\n"
                .. "```",
        })
    end

    publish_diagnostics(server, uri)
end

default_handlers["shutdown"] = function(server, msg)
    if server.state ~= "initialized" then
        send_error(server, msg.id, -32600, "Cannot shut down: server is not initialized")
        return
    end

    server.state = "shutdown"
    send_response(server, msg.id, json.NULL)
end

default_handlers["textDocument/didSave"] = function(server, msg)
    local uri = ((msg.params or {}).textDocument or {}).uri
    publish_diagnostics(server, uri)
end

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

default_handlers["textDocument/definition"] = function(server, msg)
    local params = msg.params or {}
    local position = params.position or {}
    local definition = M.goto_definition({
        file = uri_to_path((params.textDocument or {}).uri),
        row = (position.line or 0) + 1,
        col = (position.character or 0) + 1,
    })

    if definition then
        send_response(server, msg.id, {
            uri = "file://" .. definition.file,
            range = {
                start = { line = definition.row - 1, character = definition.start_col - 1 },
                ["end"] = { line = definition.row - 1, character = definition.end_col },
            },
        })
    else
        send_response(server, msg.id, json.NULL)
    end
end

default_handlers["textDocument/implementation"] = function(server, msg)
    local params = msg.params or {}
    local position = params.position or {}
    local implementation = M.goto_implementation({
        file = uri_to_path((params.textDocument or {}).uri),
        row = (position.line or 0) + 1,
        col = (position.character or 0) + 1,
    })

    if implementation then
        send_response(server, msg.id, {
            uri = "file://" .. implementation.file,
            range = {
                start = { line = implementation.row - 1, character = implementation.start_col - 1 },
                ["end"] = { line = implementation.row - 1, character = implementation.end_col },
            },
        })
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
    if arg[1] == "--version" or arg[1] == "-v" then
        local version = os.getenv("ANAKINS_DTLS_VERSION") or "unknown"
        local revision = os.getenv("ANAKINS_DTLS_REVISION") or "unknown"
        io.write("having a hoot and a holler\n")
        io.write(("anakins-dtls %s (%s)\n"):format(version, revision))
        os.exit(0)
    end

    local server = M.new_server(new_stdio_channel())
    M.server_run(server)
    os.exit(server.exit_code or 0)
end

return M
