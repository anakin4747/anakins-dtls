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
    end)
end)
