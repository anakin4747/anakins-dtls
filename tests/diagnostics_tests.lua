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
                        start = { line = 8, character = 14 },
                        ["end"] = { line = 8, character = 22 },
                    },
                    severity = 1,
                    source = "anakins-dtls",
                    message = "Unit address must match the first address in reg",
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

        it("accepts multiline reg arrays", function()
            assert.same({}, dtls.get_diagnostics(cwd .. "/tests/multiline-reg.dts"))
        end)

        it("matches a zero unit address to a zero-padded hexadecimal reg address", function()
            assert.same({}, dtls.get_diagnostics(cwd .. "/tests/zero-padded-reg-address.dts"))
        end)

        it("matches a unit address to the identical hexadecimal reg address", function()
            assert.same({}, dtls.get_diagnostics(cwd .. "/tests/matching-reg-address.dts"))
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
                        ["end"] = { line = 6, character = 35 },
                    },
                    severity = 1,
                    source = "anakins-dtls",
                    message = "Missing closing double quote",
                },
                {
                    range = {
                        start = { line = 10, character = 36 },
                        ["end"] = { line = 10, character = 37 },
                    },
                    severity = 1,
                    source = "anakins-dtls",
                    message = "Missing closing >",
                },
            }, dtls.get_diagnostics(cwd .. "/tests/missing-closing-delimiters.dts"))
        end)

        it("for missing node opening braces and label colons", function()
            local diagnostics = dtls.get_diagnostics(cwd .. "/tests/missing-node-syntax.dts")
            local actual = {}
            for _, item in ipairs(diagnostics) do
                if item.message == "Missing opening brace" or item.message == "Missing colon after label" then
                    actual[#actual + 1] = item
                end
            end

            assert.same({
                {
                    range = {
                        start = { line = 1, character = 14 },
                        ["end"] = { line = 1, character = 14 },
                    },
                    severity = 1,
                    source = "anakins-dtls",
                    message = "Missing opening brace",
                },
                {
                    range = {
                        start = { line = 5, character = 1 },
                        ["end"] = { line = 5, character = 14 },
                    },
                    severity = 1,
                    source = "anakins-dtls",
                    message = "Missing colon after label",
                },
            }, actual)
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

    describe("reports invalid node names", function()
        it("checks node-name and unit-address requirements", function()
            local diagnostics = dtls.get_diagnostics(cwd .. "/tests/invalid-node-names.dts")
            local actual = {}
            for _, item in ipairs(diagnostics) do
                if item.message:find("Node name", 1, true) or item.message:find("Unit address", 1, true) then
                    actual[#actual + 1] = item
                end
            end

            assert.same({
                {
                    range = {
                        start = { line = 3, character = 1 },
                        ["end"] = { line = 3, character = 33 },
                    },
                    severity = 1,
                    source = "anakins-dtls",
                    message = "Node name must be 1 to 31 characters long",
                },
                {
                    range = {
                        start = { line = 7, character = 1 },
                        ["end"] = { line = 7, character = 9 },
                    },
                    severity = 1,
                    source = "anakins-dtls",
                    message = "Node name contains an invalid character",
                },
                {
                    range = {
                        start = { line = 11, character = 8 },
                        ["end"] = { line = 11, character = 17 },
                    },
                    severity = 1,
                    source = "anakins-dtls",
                    message = "Unit address contains an invalid character",
                },
                {
                    range = {
                        start = { line = 15, character = 1 },
                        ["end"] = { line = 15, character = 8 },
                    },
                    severity = 1,
                    source = "anakins-dtls",
                    message = "Node name must start with a letter",
                },
                {
                    range = {
                        start = { line = 18, character = 13 },
                        ["end"] = { line = 18, character = 14 },
                    },
                    severity = 1,
                    source = "anakins-dtls",
                    message = "Unit address must be omitted when the node has no reg property",
                },
                {
                    range = {
                        start = { line = 21, character = 15 },
                        ["end"] = { line = 21, character = 16 },
                    },
                    severity = 1,
                    source = "anakins-dtls",
                    message = "Unit address must match the first address in reg",
                },
                {
                    range = {
                        start = { line = 38, character = 1 },
                        ["end"] = { line = 38, character = 19 },
                    },
                    severity = 1,
                    source = "anakins-dtls",
                    message = "Node name without a unit address conflicts with a property name",
                },
            }, actual)
        end)
    end)

    describe("reports invalid properties", function()
        it("checks property names and duplicate properties", function()
            local diagnostics = dtls.get_diagnostics(cwd .. "/tests/invalid-property-names.dts")
            local actual = {}
            for _, item in ipairs(diagnostics) do
                if item.message:find("Property", 1, true) or item.message:find("Duplicate", 1, true) then
                    actual[#actual + 1] = item
                end
            end

            assert.same({
                {
                    range = {
                        start = { line = 1, character = 1 },
                        ["end"] = { line = 1, character = 33 },
                    },
                    severity = 1,
                    source = "anakins-dtls",
                    message = "Property name must be 1 to 31 characters long",
                },
                {
                    range = {
                        start = { line = 2, character = 1 },
                        ["end"] = { line = 2, character = 13 },
                    },
                    severity = 1,
                    source = "anakins-dtls",
                    message = "Property name contains an invalid character",
                },
                {
                    range = {
                        start = { line = 6, character = 1 },
                        ["end"] = { line = 6, character = 10 },
                    },
                    severity = 1,
                    source = "anakins-dtls",
                    message = "Duplicate property 'duplicate'",
                },
            }, actual)
        end)
    end)

    describe("hints about inconsistent indentation", function()
        it("accepts consistent tab indentation", function()
            local diagnostics = dtls.get_diagnostics(
                cwd .. "/tests/out-of-tree/linux/arch/arm64/boot/dts/freescale/imx93-phyboard-nash.dts"
            )
            local indentation_hints = {}
            for _, item in ipairs(diagnostics) do
                if item.message:find("indentation", 1, true) then
                    indentation_hints[#indentation_hints + 1] = item
                end
            end

            assert.same({}, indentation_hints)
        end)

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
                    message = "Do not mix tabs and spaces for indentation",
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
