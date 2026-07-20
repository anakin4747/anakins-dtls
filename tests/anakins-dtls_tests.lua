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

            it("indicates if not in a root node", function()
                -- before the root node
                ctx.row, ctx.col = row_col("tests/custom.dts:1:1")
                assert(not dtls.in_a_root_node(ctx))

                -- after the root node
                ctx.row, ctx.col = row_col("tests/custom.dts:114:1")
                assert(not dtls.in_a_root_node(ctx))
            end)

            it("indicates if on a root node", function()
                -- should cover the '/', the ' ', the '{'
                ctx.row, ctx.col = row_col("tests/custom.dts:15:2")
                assert(dtls.on_a_root_node(ctx))
                ctx.row, ctx.col = row_col("tests/custom.dts:15:3")
                assert(dtls.on_a_root_node(ctx))
                ctx.row, ctx.col = row_col("tests/custom.dts:15:4")
                assert(dtls.on_a_root_node(ctx))

                -- and the '}' and ';'
                ctx.row, ctx.col = row_col("tests/custom.dts:113:1")
                assert(dtls.on_a_root_node(ctx))
                ctx.row, ctx.col = row_col("tests/custom.dts:113:2")
                assert(dtls.on_a_root_node(ctx))
            end)

            it("indicates if not on a root node", function()
                -- outside the root node
                ctx.row, ctx.col = row_col("tests/custom.dts:1:1")
                assert(not dtls.on_a_root_node(ctx))

                -- inside the root node
                ctx.row, ctx.col = row_col("tests/custom.dts:16:1")
                assert(not dtls.on_a_root_node(ctx))
            end)

            it("doesn't mistake being on an aliases node for being on a root node", function()
                -- /aliases' 'a'
                ctx.row, ctx.col = row_col("tests/custom.dts:20:2")
                assert(not dtls.on_a_root_node(ctx))

                -- /aliases' '}'
                ctx.row, ctx.col = row_col("tests/custom.dts:45:2")
                assert(not dtls.on_a_root_node(ctx))
            end)
        end)

        describe("/aliases", function()
            it("identifies if in an /aliases node", function()
                ctx.row, ctx.col = row_col("tests/custom.dts:21:3")
                assert(dtls.in_an_aliases_node(ctx))
            end)

            it("indicates that it is in a root node even in an /aliases node", function()
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

            it("identifies if on an /aliases node", function()
                -- /aliases' 'a'
                ctx.row, ctx.col = row_col("tests/custom.dts:20:2")
                assert(dtls.on_an_aliases_node(ctx))

                -- /aliases' '{'
                ctx.row, ctx.col = row_col("tests/custom.dts:20:10")
                assert(dtls.on_an_aliases_node(ctx))

                -- /aliases' '}'
                ctx.row, ctx.col = row_col("tests/custom.dts:45:2")
                assert(dtls.on_an_aliases_node(ctx))

                -- /aliases' ';'
                ctx.row, ctx.col = row_col("tests/custom.dts:45:3")
                assert(dtls.on_an_aliases_node(ctx))
            end)

            it("indicates if not on an /aliases node", function()
                -- on /chosen's '}'
                ctx.row, ctx.col = row_col("tests/custom.dts:49:2")
                assert(not dtls.on_an_aliases_node(ctx))

                -- inside /aliases
                ctx.row, ctx.col = row_col("tests/custom.dts:40:3")
                assert(not dtls.on_an_aliases_node(ctx))

                -- on /'s '}'
                ctx.row, ctx.col = row_col("tests/custom.dts:121:1")
                assert(not dtls.on_an_aliases_node(ctx))
            end)
        end)

        describe("/memory", function()
            it("identifies if in a /memory node without a unit address", function()
                -- inside memory {
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.in_a_memory_node(ctx))
            end)

            it("identifies if in a /memory node with a unit address", function()
                -- inside memory@0 {
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.in_a_memory_node(ctx))
            end)

            it("identifies if not in a /memory node", function()
                -- in root node but outside /memory
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.in_a_memory_node(ctx))

                -- in /child/memory
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.in_a_memory_node(ctx))
            end)

            it("indicates that it is in a root node even in a /memory node", function()
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.in_a_root_node(ctx))
            end)

            it("identifies if on a /memory node", function()
                -- /memory's 'm'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_memory_node(ctx))

                -- /memory's '{'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_memory_node(ctx))

                -- /memory's '}'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_memory_node(ctx))

                -- /memory's ';'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_memory_node(ctx))

                -- /memory@0's '@'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_memory_node(ctx))

                -- /memory@0's '0'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_memory_node(ctx))
            end)

            it("indicates if not on a /memory node", function()
                -- on /chosen's '}'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.on_a_memory_node(ctx))

                -- inside /memory
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.on_a_memory_node(ctx))

                -- on /aliases's 'a'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.on_a_memory_node(ctx))

                -- on /child/memory's 'm'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.on_a_memory_node(ctx))
            end)
        end)
    end)
end
