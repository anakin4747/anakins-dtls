local busted = require("busted")
local assert = require("luassert")
local describe = busted.describe
local it = busted.it

package.path = "./lua/?.lua;" .. package.path
local dtls = require("anakins-dtls")

local handle = io.popen("pwd")
local cwd = handle:read("*l")
handle:close()

describe("get_diagnostics()", function()
    it("errors if the file path is not absolute", function()
        assert.has_error(function()
            dtls.get_diagnostics("tests/missing-semicolons.dts")
        end, "get_diagnostics: file path must be absolute")
    end)

    describe("reports user-friendly syntax errors", function()
        it("for missing semicolons", function()
            assert.same({
                {
                    range = {
                        start = { line = 1, character = 24 },
                        ["end"] = { line = 1, character = 24 },
                    },
                    severity = 1,
                    source = "anakins-dtls",
                    message = "Missing semicolon",
                },
                {
                    range = {
                        start = { line = 6, character = 27 },
                        ["end"] = { line = 6, character = 27 },
                    },
                    severity = 1,
                    source = "anakins-dtls",
                    message = "Missing semicolon",
                },
                {
                    range = {
                        start = { line = 12, character = 13 },
                        ["end"] = { line = 12, character = 13 },
                    },
                    severity = 1,
                    source = "anakins-dtls",
                    message = "Missing semicolon",
                },
                {
                    range = {
                        start = { line = 15, character = 1 },
                        ["end"] = { line = 15, character = 1 },
                    },
                    severity = 1,
                    source = "anakins-dtls",
                    message = "Missing semicolon",
                },
            }, dtls.get_diagnostics(cwd .. "/tests/missing-semicolons.dts"))
        end)

        it("for missing closing delimiters", function()
            assert.same({
                {
                    range = {
                        start = { line = 3, character = 4 },
                        ["end"] = { line = 3, character = 4 },
                    },
                    severity = 1,
                    source = "anakins-dtls",
                    message = "Missing closing brace",
                },
                {
                    range = {
                        start = { line = 6, character = 34 },
                        ["end"] = { line = 6, character = 34 },
                    },
                    severity = 1,
                    source = "anakins-dtls",
                    message = "Missing closing double quote",
                },
                {
                    range = {
                        start = { line = 10, character = 36 },
                        ["end"] = { line = 10, character = 36 },
                    },
                    severity = 1,
                    source = "anakins-dtls",
                    message = "Missing closing >",
                },
            }, dtls.get_diagnostics(cwd .. "/tests/missing-closing-delimiters.dts"))
        end)

        it("for values too large to fit in a cell", function()
            assert.same({
                {
                    range = {
                        start = { line = 2, character = 21 },
                        ["end"] = { line = 2, character = 32 },
                    },
                    severity = 1,
                    source = "anakins-dtls",
                    message = "Cell value exceeds 0xFFFFFFFF; represent a <u64> as two cells",
                },
                {
                    range = {
                        start = { line = 3, character = 25 },
                        ["end"] = { line = 3, character = 35 },
                    },
                    severity = 1,
                    source = "anakins-dtls",
                    message = "Cell value exceeds 0xFFFFFFFF; represent a <u64> as two cells",
                },
                {
                    range = {
                        start = { line = 5, character = 15 },
                        ["end"] = { line = 5, character = 33 },
                    },
                    severity = 1,
                    source = "anakins-dtls",
                    message = "Cell value exceeds 0xFFFFFFFF; represent a <u64> as two cells",
                },
            }, dtls.get_diagnostics(cwd .. "/tests/oversized-cells.dts"))
        end)
    end)

    describe("hints about inconsistent indentation", function()
        it("for indentation that does not match structural levels", function()
            assert.same({
                {
                    range = {
                        start = { line = 2, character = 7 },
                        ["end"] = { line = 2, character = 7 },
                    },
                    severity = 4,
                    source = "anakins-dtls",
                    message = "Inconsistent indentation: expected 8 spaces, found 7",
                },
                {
                    range = {
                        start = { line = 7, character = 8 },
                        ["end"] = { line = 7, character = 8 },
                    },
                    severity = 4,
                    source = "anakins-dtls",
                    message = "Inconsistent indentation: expected 12 spaces, found 8",
                },
                {
                    range = {
                        start = { line = 8, character = 0 },
                        ["end"] = { line = 8, character = 0 },
                    },
                    severity = 4,
                    source = "anakins-dtls",
                    message = "Use spaces consistently for indentation",
                },
                {
                    range = {
                        start = { line = 12, character = 5 },
                        ["end"] = { line = 12, character = 5 },
                    },
                    severity = 4,
                    source = "anakins-dtls",
                    message = "Inconsistent indentation: expected 4 spaces, found 5",
                },
            }, dtls.get_diagnostics(cwd .. "/tests/inconsistent-indentation.dts"))
        end)
    end)
end)
