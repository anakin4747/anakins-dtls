local busted = require("busted")
local assert = require("luassert")
local describe = busted.describe
local it = busted.it

package.path = "./lua/?.lua;" .. package.path
local dtls = require("anakins-dtls")

local function row_col(filename_linenumber)
    local row, col = filename_linenumber:match(":(%d+):(%d+)")
    return tonumber(row), tonumber(col)
end

local dts_locations = {
    { name = "in-tree", path = "arch/arm64/boot/dts/freescale/custom.dts" },
    { name = "out-of-tree", path = "custom.dts" },
}

for _, location in ipairs(dts_locations) do
    local ctx = {
        cwd = location.name,
        file = location.path,
    }

    describe(location.name, function()
        describe("/", function()
            it("indicates if in a root node", function()
                ctx.row, ctx.col = row_col("tests/custom.dts:16:2")
                assert(dtls.in_a_root_node(ctx))
            end)

            it("does not mistake outside of a root node for inside a root node", function()
                ctx.row, ctx.col = row_col("tests/custom.dts:1:1")
                assert(not dtls.in_a_root_node(ctx))

                ctx.row, ctx.col = row_col("tests/custom.dts:114:1")
                assert(not dtls.in_a_root_node(ctx))
            end)

            it("indicates if not on a root node", function()
                ctx.row, ctx.col = row_col("tests/custom.dts:1:1")
                assert(not dtls.on_a_root_node(ctx))
            end)

            it("indicates if on a root node's opening bracket", function()
                ctx.row, ctx.col = row_col("tests/custom.dts:20:10")
                assert(dtls.on_a_root_node(ctx))

                ctx.row, ctx.col = row_col("tests/custom.dts:20:9") -- The space before should also count
                assert(dtls.on_a_root_node(ctx))
            end)

            it("indicates if on a root node's closing bracket", function()
                ctx.row, ctx.col = row_col("tests/custom.dts:45:2")
                assert(dtls.on_a_root_node(ctx))

                ctx.row, ctx.col = row_col("tests/custom.dts:45:3") -- The semicolon after should also count
                assert(dtls.on_a_root_node(ctx))
            end)
        end)

        describe("/aliases", function()
            it("identifies if in an /aliases node", function()
                ctx.row, ctx.col = row_col("tests/custom.dts:21:3")
                assert(dtls.in_an_aliases_node(ctx))
            end)

            it("indicates if in a root node even in an /aliases node", function()
                ctx.row, ctx.col = row_col("tests/custom.dts:21:3")
                assert(dtls.in_a_root_node(ctx))
            end)

            it("doesn't mistake inside the root node for inside an /aliases node", function()
                ctx.row, ctx.col = row_col("tests/custom.dts:17:2")
                assert(not dtls.in_an_aliases_node(ctx))
            end)

            it("doesn't mistake being inside a /child/aliases node for being inside an /aliases node", function()
                ctx.row, ctx.col = row_col("tests/custom.dts:110:13")
                assert(not dtls.in_an_aliases_node(ctx))
            end)
        end)
    end)
end
