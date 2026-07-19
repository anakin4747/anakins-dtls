local busted = require("busted")
local assert = require("luassert")
local describe = busted.describe
local it = busted.it

local dts_locations = {
    { name = "in-tree", path = "in-tree/arch/arm64/boot/dts/freescale/custom.dts" },
    { name = "out-of-tree", path = "out-of-tree/custom.dts" },
}

for _, location in ipairs(dts_locations) do
    describe(location.name, function()
        it("dummy test", function()
            assert(true)
        end)
    end)
end
