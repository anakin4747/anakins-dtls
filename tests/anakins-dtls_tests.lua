local busted = require("busted")
local assert = require("luassert")
local describe = busted.describe
local it = busted.it

package.path = "./lua/?.lua;" .. package.path
local dtls = require("anakins-dtls")

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
                ctx.row = 16
                ctx.col = 2
                assert(dtls.in_a_root_node(ctx))
            end)

            it("does not mistake outside of a root node for inside a root node", function()
                ctx.row = 0
                ctx.col = 0
                assert(not dtls.in_a_root_node(ctx))

                ctx.row = 114
                assert(not dtls.in_a_root_node(ctx))
            end)

            it("indicates if not on a root node", function()
                ctx.row = 0
                ctx.col = 0
                assert(not dtls.on_a_root_node(ctx))
            end)

            it("indicates if on a root node's opening bracket", function()
                ctx.row = 20
                ctx.col = 10
                assert(dtls.on_a_root_node(ctx))

                ctx.col = 9 -- The space before should also count
                assert(dtls.on_a_root_node(ctx))
            end)

            it("indicates if on a root node's closing bracket", function()
                ctx.row = 45
                ctx.col = 2
                assert(dtls.on_a_root_node(ctx))

                ctx.col = 3 -- The semicolon after should also count
                assert(dtls.on_a_root_node(ctx))
            end)
        end)

        describe("/aliases", function()
            it("identifies if in an /aliases node", function()
                ctx.row = 21
                ctx.col = 3
                assert(dtls.in_an_aliases_node(ctx))
            end)

            it("indicates if in a root node even in an /aliases node", function()
                ctx.row = 21
                ctx.col = 3
                assert(dtls.in_a_root_node(ctx))
            end)

            it("doesn't mistake inside the root node for inside an /aliases node", function()
                ctx.row = 17
                ctx.col = 2
                assert(not dtls.in_an_aliases_node(ctx))
            end)

            it("doesn't mistake being inside a /child/aliases node for being inside an /aliases node", function()
                ctx.row = 110
                ctx.col = 13
                assert(not dtls.in_an_aliases_node(ctx))
            end)
        end)
    end)
end
