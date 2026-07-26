local busted = require("busted")
local assert = require("luassert")
local spy = require("luassert.spy")
local describe = busted.describe
local it = busted.it
local before_each = busted.before_each

package.path = "./lua/?.lua;" .. package.path
local dtls = require("anakins-dtls")

local function row_col(filename_linenumber)
    local row, col = filename_linenumber:match(":(%d+):(%d+)")
    return tonumber(row), tonumber(col)
end

local function sorted(values)
    table.sort(values)
    return values
end

local function with_node_properties(properties, values, callback)
    local original = dtls.list_node_properties
    local list_node_properties = spy.new(function()
        return properties, values
    end)
    dtls.list_node_properties = list_node_properties
    local result = callback()
    dtls.list_node_properties = original

    assert.spy(list_node_properties).was_called()
    return result
end

local handle = io.popen("pwd")
local cwd = handle:read("*l")
handle:close()

local dts_locations = {
    {
        name = "in-tree",
        path = "arch/arm64/boot/dts/freescale/custom.dts",
        kernel_path = "",
    },
    { name = "out-of-tree", path = "custom.dts", kernel_path = "linux" },
}

local file = ("%s/tests/%s/%s"):format(cwd, dts_locations[1].name, dts_locations[1].path)
local ctx = {}

before_each(function()
    ctx = {
        row = nil,
        col = nil,
        file = file,
    }
end)

describe("in_a_root_node()", function()
    it("returns true if in a root node", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:16:5")
        assert(dtls.in_a_root_node(ctx))
    end)

    it("returns false if not in a root node", function()
        -- before the root node
        ctx.row, ctx.col = row_col("tests/custom.dts:1:1")
        assert(not dtls.in_a_root_node(ctx))

        -- after the root node
        ctx.row, ctx.col = row_col("tests/custom.dts:476:1")
        assert(not dtls.in_a_root_node(ctx))
    end)
end)

describe("on_a_root_node()", function()
    it("returns true if on a root node", function()
        -- should cover the '/', the ' ', the '{'
        ctx.row, ctx.col = row_col("tests/custom.dts:15:1")
        assert(dtls.on_a_root_node(ctx))
        ctx.row, ctx.col = row_col("tests/custom.dts:15:2")
        assert(dtls.on_a_root_node(ctx))
        ctx.row, ctx.col = row_col("tests/custom.dts:15:3")
        assert(dtls.on_a_root_node(ctx))

        -- and the '}' and ';'
        ctx.row, ctx.col = row_col("tests/custom.dts:475:1")
        assert(dtls.on_a_root_node(ctx))
        ctx.row, ctx.col = row_col("tests/custom.dts:475:2")
        assert(dtls.on_a_root_node(ctx))
    end)

    it("returns false if not on a root node", function()
        -- outside the root node
        ctx.row, ctx.col = row_col("tests/custom.dts:1:1")
        assert(not dtls.on_a_root_node(ctx))

        -- inside the root node
        ctx.row, ctx.col = row_col("tests/custom.dts:16:1")
        assert(not dtls.on_a_root_node(ctx))
    end)

    it("returns false if on an /aliases node", function()
        -- /aliases' 'a'
        ctx.row, ctx.col = row_col("tests/custom.dts:25:5")
        assert(not dtls.on_a_root_node(ctx))

        -- /aliases' '}'
        ctx.row, ctx.col = row_col("tests/custom.dts:50:5")
        assert(not dtls.on_a_root_node(ctx))
    end)
end)

describe("in_an_aliases_node()", function()
    it("returns true if in an /aliases node", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:30:9")
        assert(dtls.in_an_aliases_node(ctx))
    end)

    it("returns false if not in an /aliases node", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:17:2")
        assert(not dtls.in_an_aliases_node(ctx))
    end)

    it("returns false if in a /child/aliases node", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:115:13")
        assert(not dtls.in_an_aliases_node(ctx))
    end)
end)

describe("on_an_aliases_node()", function()
    it("returns true if on an /aliases node", function()
        -- /aliases' 'a'
        ctx.row, ctx.col = row_col("tests/custom.dts:25:5")
        assert(dtls.on_an_aliases_node(ctx))

        -- /aliases' '{'
        ctx.row, ctx.col = row_col("tests/custom.dts:25:13")
        assert(dtls.on_an_aliases_node(ctx))

        -- /aliases' '}'
        ctx.row, ctx.col = row_col("tests/custom.dts:50:5")
        assert(dtls.on_an_aliases_node(ctx))

        -- /aliases' ';'
        ctx.row, ctx.col = row_col("tests/custom.dts:50:6")
        assert(dtls.on_an_aliases_node(ctx))
    end)

    it("returns false if not on an /aliases node", function()
        -- on /chosen's '}'
        ctx.row, ctx.col = row_col("tests/custom.dts:54:5")
        assert(not dtls.on_an_aliases_node(ctx))

        -- inside /aliases
        ctx.row, ctx.col = row_col("tests/custom.dts:40:9")
        assert(not dtls.on_an_aliases_node(ctx))

        -- on /'s '}'
        ctx.row, ctx.col = row_col("tests/custom.dts:475:1")
        assert(not dtls.on_an_aliases_node(ctx))
    end)

    it("returns false on whitespace before an /aliases node", function()
        for col = 1, 4 do
            ctx.row, ctx.col = 25, col
            assert(not dtls.on_an_aliases_node(ctx))
        end
    end)
end)

describe("in_a_memory_node()", function()
    it("returns true if in a /memory node", function()
        -- inside memory {
        ctx.row, ctx.col = row_col("tests/custom.dts:120:9")
        assert(dtls.in_a_memory_node(ctx))
    end)

    it("returns true if in a /memory@unit-address node", function()
        -- inside memory@0 {
        ctx.row, ctx.col = row_col("tests/custom.dts:127:9")
        assert(dtls.in_a_memory_node(ctx))
    end)

    it("returns false if not in a /memory node", function()
        -- in root node but outside /memory
        ctx.row, ctx.col = row_col("tests/custom.dts:56:5")
        assert(not dtls.in_a_memory_node(ctx))

        -- in /child/memory
        ctx.row, ctx.col = row_col("tests/custom.dts:370:13")
        assert(not dtls.in_a_memory_node(ctx))
    end)
end)

describe("on_a_memory_node()", function()
    it("returns true if on a /memory node", function()
        -- /memory's 'm'
        ctx.row, ctx.col = row_col("tests/custom.dts:119:5")
        assert(dtls.on_a_memory_node(ctx))

        -- /memory's '{'
        ctx.row, ctx.col = row_col("tests/custom.dts:119:12")
        assert(dtls.on_a_memory_node(ctx))

        -- /memory's '}'
        ctx.row, ctx.col = row_col("tests/custom.dts:124:5")
        assert(dtls.on_a_memory_node(ctx))

        -- /memory's ';'
        ctx.row, ctx.col = row_col("tests/custom.dts:124:6")
        assert(dtls.on_a_memory_node(ctx))

        -- /memory@0's '@'
        ctx.row, ctx.col = row_col("tests/custom.dts:126:11")
        assert(dtls.on_a_memory_node(ctx))

        -- /memory@0's '0'
        ctx.row, ctx.col = row_col("tests/custom.dts:126:12")
        assert(dtls.on_a_memory_node(ctx))
    end)

    it("returns false if not on a /memory node", function()
        -- on /chosen's '}'
        ctx.row, ctx.col = row_col("tests/custom.dts:54:5")
        assert(not dtls.on_a_memory_node(ctx))

        -- inside /memory
        ctx.row, ctx.col = row_col("tests/custom.dts:120:9")
        assert(not dtls.on_a_memory_node(ctx))

        -- on /aliases's 'a'
        ctx.row, ctx.col = row_col("tests/custom.dts:25:5")
        assert(not dtls.on_a_memory_node(ctx))

        -- on /child/memory's 'm'
        ctx.row, ctx.col = row_col("tests/custom.dts:369:9")
        assert(not dtls.on_a_memory_node(ctx))
    end)

    it("returns false on whitespace before a /memory node", function()
        for _, row in ipairs({ 119, 126 }) do
            for col = 1, 4 do
                ctx.row, ctx.col = row, col
                assert(not dtls.on_a_memory_node(ctx))
            end
        end
    end)
end)

describe("in_a_chosen_node()", function()
    it("returns true if in a /chosen node", function()
        -- inside chosen {
        ctx.row, ctx.col = row_col("tests/custom.dts:53:9")
        assert(dtls.in_a_chosen_node(ctx))
    end)

    it("returns false if not in a /chosen node", function()
        -- in root node but outside /chosen
        ctx.row, ctx.col = row_col("tests/custom.dts:56:5")
        assert(not dtls.in_a_chosen_node(ctx))

        -- in /child/chosen
        ctx.row, ctx.col = row_col("tests/custom.dts:374:13")
        assert(not dtls.in_a_chosen_node(ctx))
    end)
end)

describe("on_a_chosen_node()", function()
    it("returns true if on a /chosen node", function()
        -- /chosen's 'c'
        ctx.row, ctx.col = row_col("tests/custom.dts:52:5")
        assert(dtls.on_a_chosen_node(ctx))

        -- /chosen's '{'
        ctx.row, ctx.col = row_col("tests/custom.dts:52:12")
        assert(dtls.on_a_chosen_node(ctx))

        -- /chosen's '}'
        ctx.row, ctx.col = row_col("tests/custom.dts:54:5")
        assert(dtls.on_a_chosen_node(ctx))

        -- /chosen's ';'
        ctx.row, ctx.col = row_col("tests/custom.dts:54:6")
        assert(dtls.on_a_chosen_node(ctx))
    end)

    it("returns false if not on a /chosen node", function()
        -- on /memory's 'm'
        ctx.row, ctx.col = row_col("tests/custom.dts:119:5")
        assert(not dtls.on_a_chosen_node(ctx))

        -- inside /chosen
        ctx.row, ctx.col = row_col("tests/custom.dts:53:9")
        assert(not dtls.on_a_chosen_node(ctx))

        -- on /aliases's 'a'
        ctx.row, ctx.col = row_col("tests/custom.dts:25:5")
        assert(not dtls.on_a_chosen_node(ctx))

        -- on /child/chosen's 'c'
        ctx.row, ctx.col = row_col("tests/custom.dts:373:9")
        assert(not dtls.on_a_chosen_node(ctx))
    end)

    it("returns false on whitespace before a /chosen node", function()
        for col = 1, 4 do
            ctx.row, ctx.col = 52, col
            assert(not dtls.on_a_chosen_node(ctx))
        end
    end)
end)

describe("in_a_cpus_node()", function()
    it("returns true if in a /cpus node", function()
        -- inside /cpus {
        ctx.row, ctx.col = row_col("tests/custom.dts:173:9")
        assert(dtls.in_a_cpus_node(ctx))
    end)

    it("returns false if not in a /cpus node", function()
        -- in root node but outside /cpus
        ctx.row, ctx.col = row_col("tests/custom.dts:56:5")
        assert(not dtls.in_a_cpus_node(ctx))

        -- in /child/cpus
        ctx.row, ctx.col = row_col("tests/custom.dts:378:13")
        assert(not dtls.in_a_cpus_node(ctx))
    end)
end)

describe("on_a_cpus_node()", function()
    it("returns true if on a /cpus node", function()
        -- /cpus' 'c'
        ctx.row, ctx.col = row_col("tests/custom.dts:172:5")
        assert(dtls.on_a_cpus_node(ctx))

        -- /cpus' '{'
        ctx.row, ctx.col = row_col("tests/custom.dts:172:10")
        assert(dtls.on_a_cpus_node(ctx))

        -- /cpus' '}'
        ctx.row, ctx.col = row_col("tests/custom.dts:224:5")
        assert(dtls.on_a_cpus_node(ctx))

        -- /cpus' ';'
        ctx.row, ctx.col = row_col("tests/custom.dts:224:6")
        assert(dtls.on_a_cpus_node(ctx))
    end)

    it("returns false if not on a /cpus node", function()
        -- inside /cpus
        ctx.row, ctx.col = row_col("tests/custom.dts:173:9")
        assert(not dtls.on_a_cpus_node(ctx))

        -- on /aliases's 'a'
        ctx.row, ctx.col = row_col("tests/custom.dts:25:5")
        assert(not dtls.on_a_cpus_node(ctx))

        -- on /child/cpus's 'c'
        ctx.row, ctx.col = row_col("tests/custom.dts:377:9")
        assert(not dtls.on_a_cpus_node(ctx))
    end)

    it("returns false on whitespace before a /cpus node", function()
        for col = 1, 4 do
            ctx.row, ctx.col = 172, col
            assert(not dtls.on_a_cpus_node(ctx))
        end
    end)
end)

describe("in_a_cpu_node()", function()
    it("returns true if in a cpu node", function()
        -- inside cpu@0 {
        ctx.row, ctx.col = row_col("tests/custom.dts:176:13")
        assert(dtls.in_a_cpu_node(ctx))
    end)

    it("returns false if not in a cpu node", function()
        -- in /cpus but outside any cpu@N
        ctx.row, ctx.col = row_col("tests/custom.dts:173:9")
        assert(not dtls.in_a_cpu_node(ctx))

        -- outside /cpus
        ctx.row, ctx.col = row_col("tests/custom.dts:171:5")
        assert(not dtls.in_a_cpu_node(ctx))
    end)
end)

describe("on_a_cpu_node()", function()
    it("returns true if on a cpu node", function()
        -- cpu@0's 'c'
        ctx.row, ctx.col = row_col("tests/custom.dts:175:9")
        assert(dtls.on_a_cpu_node(ctx))

        -- cpu@0's '{'
        ctx.row, ctx.col = row_col("tests/custom.dts:175:15")
        assert(dtls.on_a_cpu_node(ctx))

        -- cpu@0's '}'
        ctx.row, ctx.col = row_col("tests/custom.dts:203:9")
        assert(dtls.on_a_cpu_node(ctx))

        -- cpu@0's ';'
        ctx.row, ctx.col = row_col("tests/custom.dts:203:10")
        assert(dtls.on_a_cpu_node(ctx))

        -- cpu@0's '@'
        ctx.row, ctx.col = row_col("tests/custom.dts:175:12")
        assert(dtls.on_a_cpu_node(ctx))

        -- cpu@0's '0'
        ctx.row, ctx.col = row_col("tests/custom.dts:175:13")
        assert(dtls.on_a_cpu_node(ctx))
    end)

    it("returns false if not on a cpu node", function()
        -- on /cpus' 'c'
        ctx.row, ctx.col = row_col("tests/custom.dts:172:5")
        assert(not dtls.on_a_cpu_node(ctx))

        -- inside cpu@0
        ctx.row, ctx.col = row_col("tests/custom.dts:176:13")
        assert(not dtls.on_a_cpu_node(ctx))

        -- on /memory's 'm'
        ctx.row, ctx.col = row_col("tests/custom.dts:119:5")
        assert(not dtls.on_a_cpu_node(ctx))
    end)

    it("returns false on whitespace before a cpu node", function()
        for col = 1, 8 do
            ctx.row, ctx.col = 175, col
            assert(not dtls.on_a_cpu_node(ctx))
        end
    end)
end)

describe("in_a_cache_node()", function()
    it("returns true if in a cache node", function()
        -- inside l2-cache {
        ctx.row, ctx.col = row_col("tests/custom.dts:185:17")
        assert(dtls.in_a_cache_node(ctx))

        -- inside nested l3-cache {
        ctx.row, ctx.col = row_col("tests/custom.dts:195:21")
        assert(dtls.in_a_cache_node(ctx))
    end)

    it("returns false if not in a cache node", function()
        -- in cpu@0 but outside any cache node
        ctx.row, ctx.col = row_col("tests/custom.dts:176:13")
        assert(not dtls.in_a_cache_node(ctx))

        -- in /cpus
        ctx.row, ctx.col = row_col("tests/custom.dts:173:9")
        assert(not dtls.in_a_cache_node(ctx))
    end)
end)

describe("on_a_cache_node()", function()
    it("returns true if on a cache node", function()
        -- l2-cache's 'l'
        ctx.row, ctx.col = row_col("tests/custom.dts:184:18")
        assert(dtls.on_a_cache_node(ctx))

        -- l2-cache's '{'
        ctx.row, ctx.col = row_col("tests/custom.dts:184:27")
        assert(dtls.on_a_cache_node(ctx))

        -- l2-cache's '}'
        ctx.row, ctx.col = row_col("tests/custom.dts:202:13")
        assert(dtls.on_a_cache_node(ctx))

        -- l2-cache's ';'
        ctx.row, ctx.col = row_col("tests/custom.dts:202:14")
        assert(dtls.on_a_cache_node(ctx))
    end)

    it("returns false if not on a cache node", function()
        -- on cpu@0's 'c'
        ctx.row, ctx.col = row_col("tests/custom.dts:175:9")
        assert(not dtls.on_a_cache_node(ctx))

        -- inside l2-cache
        ctx.row, ctx.col = row_col("tests/custom.dts:185:17")
        assert(not dtls.on_a_cache_node(ctx))

        -- on /memory's 'm'
        ctx.row, ctx.col = row_col("tests/custom.dts:119:5")
        assert(not dtls.on_a_cache_node(ctx))
    end)

    it("returns false on whitespace before a cache node", function()
        for col = 1, 12 do
            ctx.row, ctx.col = 184, col
            assert(not dtls.on_a_cache_node(ctx))
        end
    end)

    it("returns false on a cache node label definition", function()
        for col = 13, 17 do
            ctx.row, ctx.col = 184, col
            assert(not dtls.on_a_cache_node(ctx))
        end
    end)
end)

describe("in_a_reserved_memory_node()", function()
    it("returns true if in a /reserved-memory node", function()
        -- inside reserved-memory {
        ctx.row, ctx.col = row_col("tests/custom.dts:133:9")
        assert(dtls.in_a_reserved_memory_node(ctx))
    end)

    it("returns false if not in a /reserved-memory node", function()
        -- in root node but outside /reserved-memory
        ctx.row, ctx.col = row_col("tests/custom.dts:56:5")
        assert(not dtls.in_a_reserved_memory_node(ctx))

        -- in /child/reserved-memory
        ctx.row, ctx.col = row_col("tests/custom.dts:382:13")
        assert(not dtls.in_a_reserved_memory_node(ctx))
    end)
end)

describe("on_a_reserved_memory_node()", function()
    it("returns true if on a /reserved-memory node", function()
        -- /reserved-memory's 'r'
        ctx.row, ctx.col = row_col("tests/custom.dts:132:5")
        assert(dtls.on_a_reserved_memory_node(ctx))

        -- /reserved-memory's '{'
        ctx.row, ctx.col = row_col("tests/custom.dts:132:21")
        assert(dtls.on_a_reserved_memory_node(ctx))

        -- /reserved-memory's '}'
        ctx.row, ctx.col = row_col("tests/custom.dts:159:5")
        assert(dtls.on_a_reserved_memory_node(ctx))

        -- /reserved-memory's ';'
        ctx.row, ctx.col = row_col("tests/custom.dts:159:6")
        assert(dtls.on_a_reserved_memory_node(ctx))
    end)

    it("returns false if not on a /reserved-memory node", function()
        -- on /memory's 'm'
        ctx.row, ctx.col = row_col("tests/custom.dts:119:5")
        assert(not dtls.on_a_reserved_memory_node(ctx))

        -- inside /reserved-memory
        ctx.row, ctx.col = row_col("tests/custom.dts:133:9")
        assert(not dtls.on_a_reserved_memory_node(ctx))
    end)

    it("returns false on whitespace before a /reserved-memory node", function()
        for col = 1, 4 do
            ctx.row, ctx.col = 132, col
            assert(not dtls.on_a_reserved_memory_node(ctx))
        end
    end)
end)

describe("in_a_reserved_memory_region_node()", function()
    it("returns true if in a reserved-memory region node", function()
        -- inside linux,cma {
        ctx.row, ctx.col = row_col("tests/custom.dts:139:13")
        assert(dtls.in_a_reserved_memory_region_node(ctx))

        -- inside framebuffer@78000000 {
        ctx.row, ctx.col = row_col("tests/custom.dts:149:13")
        assert(dtls.in_a_reserved_memory_region_node(ctx))

        -- inside multimedia@77000000 {
        ctx.row, ctx.col = row_col("tests/custom.dts:155:13")
        assert(dtls.in_a_reserved_memory_region_node(ctx))
    end)

    it("returns false if not in a reserved-memory region node", function()
        -- in /reserved-memory but outside any region node
        ctx.row, ctx.col = row_col("tests/custom.dts:133:9")
        assert(not dtls.in_a_reserved_memory_region_node(ctx))
    end)
end)

describe("on_a_reserved_memory_region_node()", function()
    it("returns true if on a reserved-memory region node", function()
        -- linux,cma's 'l'
        ctx.row, ctx.col = row_col("tests/custom.dts:138:9")
        assert(dtls.on_a_reserved_memory_region_node(ctx))

        -- linux,cma's '{'
        ctx.row, ctx.col = row_col("tests/custom.dts:138:19")
        assert(dtls.on_a_reserved_memory_region_node(ctx))

        -- linux,cma's '}'
        ctx.row, ctx.col = row_col("tests/custom.dts:146:9")
        assert(dtls.on_a_reserved_memory_region_node(ctx))

        -- linux,cma's ';'
        ctx.row, ctx.col = row_col("tests/custom.dts:146:10")
        assert(dtls.on_a_reserved_memory_region_node(ctx))

        -- framebuffer@78000000's '@'
        ctx.row, ctx.col = row_col("tests/custom.dts:148:38")
        assert(dtls.on_a_reserved_memory_region_node(ctx))

        -- framebuffer@78000000's '7'
        ctx.row, ctx.col = row_col("tests/custom.dts:148:39")
        assert(dtls.on_a_reserved_memory_region_node(ctx))
    end)

    it("returns false if not on a reserved-memory region node", function()
        -- on /reserved-memory's 'r'
        ctx.row, ctx.col = row_col("tests/custom.dts:132:5")
        assert(not dtls.on_a_reserved_memory_region_node(ctx))

        -- inside linux,cma
        ctx.row, ctx.col = row_col("tests/custom.dts:139:13")
        assert(not dtls.on_a_reserved_memory_region_node(ctx))

        -- on /memory's 'm'
        ctx.row, ctx.col = row_col("tests/custom.dts:119:5")
        assert(not dtls.on_a_reserved_memory_region_node(ctx))
    end)

    it("returns false on whitespace before a reserved-memory region node", function()
        for col = 1, 8 do
            ctx.row, ctx.col = 138, col
            assert(not dtls.on_a_reserved_memory_region_node(ctx))
        end
    end)

    it("returns false on a reserved-memory region label definition", function()
        for col = 9, 25 do
            ctx.row, ctx.col = 148, col
            assert(not dtls.on_a_reserved_memory_region_node(ctx))
        end
    end)
end)

for _, location in ipairs(dts_locations) do
    local layout = location

    describe("list_node_properties() " .. layout.name, function()
        before_each(function()
            ctx = {
                row = nil,
                col = nil,
                file = ("%s/tests/%s/%s"):format(cwd, layout.name, layout.path),
            }
        end)

        it("returns all properties inside the iio-hwmon node", function()
            ctx.row, ctx.col = row_col("tests/custom.dts:75:9")
            local properties = dtls.list_node_properties(ctx)

            assert.are.same(sorted({
                "compatible",
                "io-channels",
            }), sorted(properties))
        end)

        it("returns all properties inside a node reference dts", function()
            ctx.row, ctx.col = row_col("tests/custom.dts:578:5")
            local properties, values = dtls.list_node_properties(ctx)

            assert.are.same(sorted({
                "vbus-supply",
                "compatible",
                "#phy-cells",
                "clocks",
                "clock-names",
            }), sorted(properties))
            assert.are.same({ '"usb-nop-xceiv"' }, values.compatible)
        end)

        it("returns all properties inside a node in a dtsi file but not the appended dts properties", function()
            ctx = {
                row = 114,
                col = 3,
                file = ("%s/tests/%s/%s/arch/arm64/boot/dts/freescale/imx91_93_common.dtsi"):format(
                    cwd, layout.name, layout.kernel_path
                ),
            }

            local properties = dtls.list_node_properties(ctx)
            assert.are.same(sorted({
                "compatible",
                "#phy-cells",
                "clocks",
                "clock-names",
            }), sorted(properties))
        end)
    end)
end

describe("in_a_serial_device_node()", function()
    it("uses list_node_properties() to determine the compatible string", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:416:9")
        assert(with_node_properties({ "compatible" }, { compatible = { '"ns8250"' } }, function()
            return dtls.in_a_serial_device_node(ctx)
        end))
    end)

    it("returns true if in a node with a compatible string is 'ns8250'", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:426:9")
        assert(dtls.in_a_serial_device_node(ctx))
    end)

    it("returns true if in a node a compatible string is contains '-hdlc$'", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:436:9")
        assert(dtls.in_a_serial_device_node(ctx))
    end)

    it("returns false if not in a serial device node", function()
        -- inside a non serial device node
        ctx.row, ctx.col = row_col("tests/custom.dts:389:9")
        assert(not dtls.in_a_serial_device_node(ctx))

        -- inside a ns16550 device node
        ctx.row, ctx.col = row_col("tests/custom.dts:440:9")
        assert(not dtls.in_a_serial_device_node(ctx))
    end)
end)

describe("on_a_serial_device_node()", function()
    it("uses list_node_properties() to determine the compatible string", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:415:5")
        assert(with_node_properties({ "compatible" }, { compatible = { '"vendor,sync-hdlc"' } }, function()
            return dtls.on_a_serial_device_node(ctx)
        end))
    end)

    it("returns true if on a serial device node", function()
        local tests = {
            "tests/custom.dts:425:5",  -- serial-device's 's'
            "tests/custom.dts:425:19", -- serial-device's '{'
            "tests/custom.dts:428:5",  -- serial-device's '}'
            "tests/custom.dts:428:6",  -- serial-device's ';'
            "tests/custom.dts:435:5",  -- serial-device's 'h'
            "tests/custom.dts:435:17", -- serial-device's '{'
            "tests/custom.dts:437:5",  -- serial-device's '}'
            "tests/custom.dts:437:6",  -- serial-device's ';'
        }
        for _, test in ipairs(tests) do
            ctx.row, ctx.col = row_col(test)
            assert(dtls.on_a_serial_device_node(ctx))
        end
    end)

    it("returns false if not on a serial device node", function()
        -- on miscellaneous-device's 'm'
        ctx.row, ctx.col = row_col("tests/custom.dts:415:5")
        assert(not dtls.on_a_serial_device_node(ctx))

        -- inside serial-device
        ctx.row, ctx.col = row_col("tests/custom.dts:426:9")
        assert(not dtls.on_a_serial_device_node(ctx))
        ctx.row, ctx.col = row_col("tests/custom.dts:436:9")
        assert(not dtls.on_a_serial_device_node(ctx))
    end)
end)

describe("in_a_ns16550_node()", function()
    it("uses list_node_properties() to determine the compatible string", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:416:9")
        assert(with_node_properties({ "compatible" }, { compatible = { '"ns16550"' } }, function()
            return dtls.in_a_ns16550_node(ctx)
        end))
    end)

    it("returns true if in a node with a compatible string of 'ns16550'", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:440:9")
        assert(dtls.in_a_ns16550_node(ctx))
    end)

    it("returns false if not in a ns16550 node", function()
        -- inside serial-device (compatible = "ns8250", not ns16550)
        ctx.row, ctx.col = row_col("tests/custom.dts:426:9")
        assert(not dtls.in_a_ns16550_node(ctx))

        -- in a miscellaneous-device
        ctx.row, ctx.col = row_col("tests/custom.dts:416:9")
        assert(not dtls.in_a_ns16550_node(ctx))
    end)
end)

describe("on_a_ns16550_node()", function()
    it("uses list_node_properties() to determine the compatible string", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:415:5")
        assert(with_node_properties({ "compatible" }, { compatible = { '"ns16550"' } }, function()
            return dtls.on_a_ns16550_node(ctx)
        end))
    end)

    it("returns true if on a ns16550 node", function()
        -- uart@4600's 'u'
        ctx.row, ctx.col = row_col("tests/custom.dts:439:5")
        assert(dtls.on_a_ns16550_node(ctx))

        -- uart@4600's '{'
        ctx.row, ctx.col = row_col("tests/custom.dts:439:15")
        assert(dtls.on_a_ns16550_node(ctx))

        -- uart@4600's '}'
        ctx.row, ctx.col = row_col("tests/custom.dts:447:5")
        assert(dtls.on_a_ns16550_node(ctx))

        -- uart@4600's ';'
        ctx.row, ctx.col = row_col("tests/custom.dts:447:6")
        assert(dtls.on_a_ns16550_node(ctx))

        -- uart@4600's '@'
        ctx.row, ctx.col = row_col("tests/custom.dts:439:9")
        assert(dtls.on_a_ns16550_node(ctx))

        -- uart@4600's '4'
        ctx.row, ctx.col = row_col("tests/custom.dts:439:10")
        assert(dtls.on_a_ns16550_node(ctx))
    end)

    it("returns false if not on a ns16550 node", function()
        -- on serial-device's 's' (compatible = "ns8250")
        ctx.row, ctx.col = row_col("tests/custom.dts:425:5")
        assert(not dtls.on_a_ns16550_node(ctx))

        -- inside uart@4600
        ctx.row, ctx.col = row_col("tests/custom.dts:440:9")
        assert(not dtls.on_a_ns16550_node(ctx))
    end)
end)

describe("in_a_network_device_node()", function()
    it("uses list_node_properties() to determine the node type", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:440:9")
        assert(with_node_properties({ "mac-address" }, {}, function()
            return dtls.in_a_network_device_node(ctx)
        end))
    end)

    it("returns true if in a network device node", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:450:9")
        assert(dtls.in_a_network_device_node(ctx))

        ctx.row, ctx.col = row_col("tests/custom.dts:457:9")
        assert(dtls.in_a_network_device_node(ctx))
    end)

    it("returns false if not in a network device node", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:440:9")
        assert(not dtls.in_a_network_device_node(ctx))

        ctx.row, ctx.col = row_col("tests/custom.dts:456:5")
        assert(not dtls.in_a_network_device_node(ctx))
    end)
end)

describe("on_a_network_device_node()", function()
    it("uses list_node_properties() to determine the node type", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:439:5")
        assert(with_node_properties({ "phy-handle" }, {}, function()
            return dtls.on_a_network_device_node(ctx)
        end))
    end)

    it("returns true if on a network device node", function()
        local tests = {
            "tests/custom.dts:449:5",
            "tests/custom.dts:449:16",
            "tests/custom.dts:454:5",
            "tests/custom.dts:454:6",
            "tests/custom.dts:449:13",
            "tests/custom.dts:449:14",
            "tests/custom.dts:456:5",
        }
        for _, test in ipairs(tests) do
            ctx.row, ctx.col = row_col(test)
            assert(dtls.on_a_network_device_node(ctx))
        end
    end)

    it("returns false if not on a network device node", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:439:5")
        assert(not dtls.on_a_network_device_node(ctx))

        ctx.row, ctx.col = row_col("tests/custom.dts:450:9")
        assert(not dtls.on_a_network_device_node(ctx))
    end)
end)
--
describe("in_an_open_pic_node()", function()
    it("uses list_node_properties() to determine the compatible string", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:227:9")
        assert(with_node_properties({ "compatible" }, { compatible = { '"open-pic"' } }, function()
            return dtls.in_an_open_pic_node(ctx)
        end))
    end)

    it("returns true if in an open-pic node", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:463:9")
        assert(dtls.in_an_open_pic_node(ctx))
    end)

    it("returns false if not in an open-pic node", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:227:9")
        assert(not dtls.in_an_open_pic_node(ctx))
    end)
end)

describe("on_an_open_pic_node()", function()
    it("uses list_node_properties() to determine the compatible string", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:226:5")
        assert(with_node_properties({ "compatible" }, { compatible = { '"open-pic"' } }, function()
            return dtls.on_an_open_pic_node(ctx)
        end))
    end)

    it("returns true if on an open-pic node", function()
        local tests = {
            "tests/custom.dts:462:5",
            "tests/custom.dts:462:35",
            "tests/custom.dts:468:5",
            "tests/custom.dts:468:6",
            "tests/custom.dts:462:25",
            "tests/custom.dts:462:26",
        }
        for _, test in ipairs(tests) do
            ctx.row, ctx.col = row_col(test)
            assert(dtls.on_an_open_pic_node(ctx))
        end
    end)

    it("returns false if not on an open-pic node", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:226:5")
        assert(not dtls.on_an_open_pic_node(ctx))

        ctx.row, ctx.col = row_col("tests/custom.dts:463:9")
        assert(not dtls.on_an_open_pic_node(ctx))
    end)
end)
--
describe("in_a_simple_bus_node()", function()
    it("uses list_node_properties() to determine the compatible string", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:234:13")
        assert(with_node_properties({ "compatible" }, { compatible = { '"simple-bus"' } }, function()
            return dtls.in_a_simple_bus_node(ctx)
        end))
    end)

    it("returns true if in a simple-bus node", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:471:9")
        assert(dtls.in_a_simple_bus_node(ctx))
    end)

    it("returns false if not in a simple-bus node", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:234:13")
        assert(not dtls.in_a_simple_bus_node(ctx))
    end)
end)

describe("on_a_simple_bus_node()", function()
    it("uses list_node_properties() to determine the compatible string", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:232:5")
        assert(with_node_properties({ "compatible" }, { compatible = { '"simple-bus"' } }, function()
            return dtls.on_a_simple_bus_node(ctx)
        end))
    end)

    it("returns true if on a simple-bus node", function()
        local tests = {
            "tests/custom.dts:470:5",
            "tests/custom.dts:470:9",
            "tests/custom.dts:474:5",
            "tests/custom.dts:474:6",
        }
        for _, test in ipairs(tests) do
            ctx.row, ctx.col = row_col(test)
            assert(dtls.on_a_simple_bus_node(ctx))
        end
    end)

    it("returns false if not on a simple-bus node", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:232:5")
        assert(not dtls.on_a_simple_bus_node(ctx))

        ctx.row, ctx.col = row_col("tests/custom.dts:471:9")
        assert(not dtls.on_a_simple_bus_node(ctx))
    end)
end)

describe("in_top_level()", function()
    it("returns true if at the top level", function()
        -- before /dts-v1/;
        ctx.row, ctx.col = row_col("tests/custom.dts:9:1")
        assert(dtls.in_top_level(ctx))

        -- after the root node's closing '};' and before '&adc1 {'
        ctx.row, ctx.col = row_col("tests/custom.dts:476:1")
        assert(dtls.in_top_level(ctx))

        -- between '&adc1 { ... };' and '&eqos { ... };'
        ctx.row, ctx.col = row_col("tests/custom.dts:481:1")
        assert(dtls.in_top_level(ctx))
    end)

    it("returns false if not at the top level", function()
        -- inside the root node
        ctx.row, ctx.col = row_col("tests/custom.dts:16:5")
        assert(not dtls.in_top_level(ctx))

        -- inside a &label { ... } reference block
        ctx.row, ctx.col = row_col("tests/custom.dts:479:5")
        assert(not dtls.in_top_level(ctx))
    end)
end)

describe("on_a_label_definition()", function()
    it("returns true if on a label definition", function()
        -- curr_sens: current-sense {
        ctx.row, ctx.col = row_col("tests/custom.dts:56:5")
        assert(dtls.on_a_label_definition(ctx))

        -- display_reserved: framebuffer@78000000 {
        ctx.row, ctx.col = row_col("tests/custom.dts:148:9")
        assert(dtls.on_a_label_definition(ctx))

        -- L2_0:l2-cache {
        ctx.row, ctx.col = row_col("tests/custom.dts:184:13")
        assert(dtls.on_a_label_definition(ctx))
    end)

    it("returns false if not on a label definition", function()
        -- on the node name after the label, e.g. "current-sense"
        ctx.row, ctx.col = row_col("tests/custom.dts:56:16")
        assert(not dtls.on_a_label_definition(ctx))

        -- on a node with no label at all, e.g. "serial-device"
        ctx.row, ctx.col = row_col("tests/custom.dts:425:5")
        assert(not dtls.on_a_label_definition(ctx))

        -- on a label reference, e.g. "&eqos"
        ctx.row, ctx.col = row_col("tests/custom.dts:26:21")
        assert(not dtls.on_a_label_definition(ctx))
    end)
end)

describe("on_a_label_reference()", function()
    it("returns true if on a label reference", function()
        -- ethernet1 = &eqos;
        ctx.row, ctx.col = row_col("tests/custom.dts:26:21")
        assert(dtls.on_a_label_reference(ctx))

        -- io-channels = <&adc1 1>;
        ctx.row, ctx.col = row_col("tests/custom.dts:59:24")
        assert(dtls.on_a_label_reference(ctx))

        -- interrupt-parent = <&pic>;
        ctx.row, ctx.col = row_col("tests/custom.dts:360:29")
        assert(dtls.on_a_label_reference(ctx))

        -- &adc1 { ... }; top-level reference/override block
        ctx.row, ctx.col = row_col("tests/custom.dts:478:1")
        assert(dtls.on_a_label_reference(ctx))
    end)

    it("returns false if not on a label reference", function()
        -- on a label definition, e.g. "curr_sens:"
        ctx.row, ctx.col = row_col("tests/custom.dts:56:5")
        assert(not dtls.on_a_label_reference(ctx))

        -- on a property name/value that isn't a label reference
        ctx.row, ctx.col = row_col("tests/custom.dts:16:5")
        assert(not dtls.on_a_label_reference(ctx))
    end)
end)

describe("in_possible_memory_region_consumer()", function()
    it("returns true in a device node with a memory-region property", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:164:9")
        assert(dtls.in_possible_memory_region_consumer(ctx))
    end)

    it("returns true in a device node without memory-region properties", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:387:9")
        assert(dtls.in_possible_memory_region_consumer(ctx))
    end)

    it("returns true in a nested device node without memory-region properties", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:195:21")
        assert(dtls.in_possible_memory_region_consumer(ctx))
    end)

    it("returns false in the root node", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:269:5")
        assert(not dtls.in_possible_memory_region_consumer(ctx))
    end)

    it("returns false in /reserved-memory", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:133:9")
        assert(not dtls.in_possible_memory_region_consumer(ctx))
    end)

    it("returns false in a reserved-memory region node", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:139:13")
        assert(not dtls.in_possible_memory_region_consumer(ctx))
    end)
end)

describe("hover()", function()
    it("returns hover markdown for root node", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:15:1")
        local expected = dtls.dedent([[
            # Devicetree Specification:

            The root node does not have a `node-name` or `unit-address`. It is identified by a forward slash (/).

            All devicetrees shall have a root node and the following nodes shall be present at the root of all devicetrees:
            -  One `/cpus` node
            -  At least one `/memory` node

            The devicetree has a single root node of which all other device nodes are descendants. The full path to the root node is `/`.
        ]])
        assert.are.same(expected, dtls.hover(ctx))
    end)

    it("calls on_a_root_node() to determine the type of node", function()
        local on_a_root_node = spy.on(dtls, "on_a_root_node")

        ctx.row, ctx.col = row_col("tests/custom.dts:15:1")
        dtls.hover(ctx)

        assert.spy(on_a_root_node).was_called()
        assert.spy(on_a_root_node).returned_with(true)
    end)

    it("returns hover markdown for root node `model` property name", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:16:5")
        local expected = dtls.dedent([[
            # Devicetree Specification:

            ## Property Name: model

            ## Path: /model

            ## Usage: Required

            ## Definition:

            Specifies a string that uniquely identifies the model of the system board. The recommended format is "manufacturer,model-number".
        ]]) .. dtls.get_type_definition("string")
        assert.are.same(expected, dtls.hover(ctx))
    end)

    it("calls in_a_root_node() to determine the type of node", function()
        local in_a_root_node = spy.on(dtls, "in_a_root_node")

        ctx.row, ctx.col = row_col("tests/custom.dts:16:5")
        dtls.hover(ctx)

        assert.spy(in_a_root_node).was_called()
        assert.spy(in_a_root_node).returned_with(true)
    end)

    it("returns hover markdown for root node `compatible` property name", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:17:5")
        local expected = dtls.dedent([[
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
            ```
        ]]) .. dtls.get_type_definition("stringlist")
        assert.are.same(expected, dtls.hover(ctx))
    end)

    it("returns hover markdown for root node `#address-cells` property name", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:19:5")
        local expected = dtls.dedent([[
            # Devicetree Specification:

            ## Property Name: #address-cells

            ## Path: /#address-cells

            ## Usage: Required

            ## Definition:

            Specifies the number of `<u32>` cells to represent the address in the `reg` property in children of root.
        ]]) .. dtls.get_type_definition("u32")
        assert.are.same(expected, dtls.hover(ctx))
    end)

    it("returns hover markdown for root node `#size-cells` property name", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:20:5")
        local expected = dtls.dedent([[
            # Devicetree Specification:

            ## Property Name: #size-cells

            ## Path: /#size-cells

            ## Usage: Required

            ## Definition:

            Specifies the number of `<u32>` cells to represent the size in the `reg` property in children of root.
        ]]) .. dtls.get_type_definition("u32")
        assert.are.same(expected, dtls.hover(ctx))
    end)

    it("returns hover markdown for root node `serial-number` property name", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:22:5")
        local expected = dtls.dedent([[
            # Devicetree Specification:

            ## Property Name: serial-number

            ## Path: /serial-number

            ## Usage: Optional

            ## Definition:

            Specifies a string representing the device's serial number.
        ]]) .. dtls.get_type_definition("string")
        assert.are.same(expected, dtls.hover(ctx))
    end)

    it("returns hover markdown for root node `chassis-type` property name", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:23:5")
        local expected = dtls.dedent([[
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
            - `"spectacles"`
        ]]) .. dtls.get_type_definition("string")
        assert.are.same(expected, dtls.hover(ctx))
    end)

    it("does not return root property hover markdown for descendant properties", function()
        local positions = {
            "tests/custom.dts:416:9", -- compatible
            "tests/custom.dts:417:9", -- model
            "tests/custom.dts:418:9", -- #address-cells
            "tests/custom.dts:419:9", -- #size-cells
            "tests/custom.dts:349:9", -- serial-number
            "tests/custom.dts:350:9", -- chassis-type
        }

        for _, position in ipairs(positions) do
            ctx.row, ctx.col = row_col(position)
            assert.is_nil(dtls.hover(ctx))
        end
    end)

    it("returns hover markdown for /aliases node", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:25:5")
        local expected = dtls.dedent([[
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

            Given the alias `serial0`, a client program can look at the `/aliases` node and determine the alias refers to the device path `/simple-bus@fe000000/serial@llc500`.
        ]])
        assert.are.same(expected, dtls.hover(ctx))
    end)

    it("calls on_an_aliases_node() to determine the type of node", function()
        local on_an_aliases_node = spy.on(dtls, "on_an_aliases_node")

        ctx.row, ctx.col = row_col("tests/custom.dts:25:5")
        dtls.hover(ctx)

        assert.spy(on_an_aliases_node).was_called()
        assert.spy(on_an_aliases_node).returned_with(true)
    end)

    it("returns hover markdown for /aliases node properties", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:26:9")
        local expected = dtls.dedent([[
            # Anakin's Advice:

            A client program, such as Linux, Zephyr, or U-Boot, can look up the alias `ethernet1` to refer to this node.
        ]])
        local actual = dtls.hover(ctx)
        assert.are.same(expected, actual)

        ctx.row, ctx.col = row_col("tests/custom.dts:27:9")
        expected = dtls.dedent([[
            # Anakin's Advice:

            A client program, such as Linux, Zephyr, or U-Boot, can look up the alias `gpio0` to refer to this node.
        ]])
        actual = dtls.hover(ctx)
        assert.are.same(expected, actual)
    end)

    it("calls in_an_aliases_node() to determine the type of node", function()
        local in_an_aliases_node = spy.on(dtls, "in_an_aliases_node")

        ctx.row, ctx.col = row_col("tests/custom.dts:26:9")
        dtls.hover(ctx)

        assert.spy(in_an_aliases_node).was_called()
        assert.spy(in_an_aliases_node).returned_with(true)
    end)

    local cpus_node_markdown = dtls.dedent([[
        # Devicetree Specification:

        ## `/cpus` node

        A `/cpus` node is required for all devicetrees. It does not represent a real device in the system, but acts as a container for child `cpu` nodes which represent the systems CPUs.

        The `/cpus` node may contain properties that are common across `cpu` nodes.
    ]])

    it("returns hover markdown for /cpus node", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:172:5")
        local actual = dtls.hover(ctx)
        assert.are.same(cpus_node_markdown, actual)
    end)

    it("calls on_a_cpus_node() to determine the type of node", function()
        local on_a_cpus_node = spy.on(dtls, "on_a_cpus_node")

        ctx.row, ctx.col = row_col("tests/custom.dts:172:5")
        dtls.hover(ctx)

        assert.spy(on_a_cpus_node).was_called()
        assert.spy(on_a_cpus_node).returned_with(true)
    end)

    local cpus_property_markdown = {
        ["#address-cells"] = dtls.dedent([[
            # Devicetree Specification:

            ## Property Name: #address-cells

            ## Path: /cpus/#address-cells

            ## Usage: Required

            ## Definition:

            The value specifies how many cells each element of the `reg` property array takes in children of this node.

            All other standard properties are allowed but are optional.
        ]]) .. dtls.get_type_definition("u32"),
        ["#size-cells"] = dtls.dedent([[
            # Devicetree Specification:

            ## Property Name: #size-cells

            ## Path: /cpus/#size-cells

            ## Usage: Required

            ## Definition:

            Value shall be 0. Specifies that no size is required in the `reg` property in children of this node.

            All other standard properties are allowed but are optional.
        ]]) .. dtls.get_type_definition("u32"),
    }

    it("returns hover markdown for /cpus `#address-cells` property name", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:173:9")
        local actual = dtls.hover(ctx)
        assert.are.same(cpus_property_markdown["#address-cells"], actual)
    end)

    it("returns hover markdown for /cpus `#size-cells` property name", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:174:9")
        local actual = dtls.hover(ctx)
        assert.are.same(cpus_property_markdown["#size-cells"], actual)
    end)

    it("calls in_a_cpus_node() to determine the type of node", function()
        local in_a_cpus_node = spy.on(dtls, "in_a_cpus_node")

        ctx.row, ctx.col = row_col("tests/custom.dts:173:9")
        dtls.hover(ctx)

        assert.spy(in_a_cpus_node).was_called()
        assert.spy(in_a_cpus_node).returned_with(true)
    end)

    local memory_node_markdown = dtls.dedent([[
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

        The `reg` property is used to define the address and size of the two memory ranges. The 2 GB I/O region is skipped. Note that the `#address-cells` and `#size-cells` properties of the root node specify a value of 2, which means that two 32-bit cells are required to define the address and length for the `reg` property of the memory node.
    ]])

    it("returns hover markdown for /memory and /memory@unit-address nodes", function()
        local positions = {
            "tests/custom.dts:119:5", -- memory
            "tests/custom.dts:124:5", -- memory closing brace
            "tests/custom.dts:126:5", -- memory@0
            "tests/custom.dts:130:5", -- memory@0 closing brace
        }

        for _, position in ipairs(positions) do
            ctx.row, ctx.col = row_col(position)
            assert.are.same(memory_node_markdown, dtls.hover(ctx))
        end
    end)

    it("calls on_a_memory_node() to determine the type of node", function()
        local on_a_memory_node = spy.on(dtls, "on_a_memory_node")

        ctx.row, ctx.col = row_col("tests/custom.dts:119:5")
        dtls.hover(ctx)

        assert.spy(on_a_memory_node).was_called()
        assert.spy(on_a_memory_node).returned_with(true)
    end)

    local memory_property_markdown = {
        device_type = dtls.dedent([[
            # Devicetree Specification:

            ## Property Name: device_type

            ## Path: /memory/device_type

            ## Usage: Required

            ## Definition:

            Value shall be "memory"

            All other standard properties are allowed but are optional.

            ## Anakin's Advice:

            Not to be confused with the /cpus/cpu*/device_type which shall be `"cpu"` and not to be confused with the deprecated standard property `device_type`
        ]]) .. dtls.get_type_definition("string"),
        reg = dtls.dedent([[
            # Devicetree Specification:

            ## Property Name: reg

            ## Path: /memory/reg

            ## Usage: Required

            ## Definition:

            Consists of an arbitrary number of address and size pairs that specify the physical address and size of the memory ranges.

            All other standard properties are allowed but are optional.
        ]]) .. dtls.get_type_definition("prop_encoded_array"),
        ["initial-mapped-area"] = dtls.dedent([[
            # Devicetree Specification:

            ## Property Name: initial-mapped-area

            ## Path: /memory/initial-mapped-area

            ## Usage: Optional

            ## Definition:

            Specifies the address and size of the Initial Mapped Area

            Is a prop-encoded-array consisting of a triplet of (effective address, physical address, size). The effective and physical address shall each be 64-bit (`<u64>` value), and the size shall be 32-bits (`<u32>` value).

            All other standard properties are allowed but are optional.
        ]]) .. dtls.get_type_definition("prop_encoded_array"),
        hotpluggable = dtls.dedent([[
            # Devicetree Specification:

            ## Property Name: hotpluggable

            ## Path: /memory/hotpluggable

            ## Usage: Optional

            ## Definition:

            Specifies an explicit hint to the operating system that this memory may potentially be removed later.

            All other standard properties are allowed but are optional.
        ]]) .. dtls.get_type_definition("empty"),
    }

    it("returns hover markdown for /memory `device_type` property name", function()
        for _, row in ipairs({ 120, 127 }) do
            ctx.row, ctx.col = row, 9
            assert.are.same(memory_property_markdown.device_type, dtls.hover(ctx))
        end
    end)

    it("returns hover markdown for /memory `reg` property name", function()
        for _, row in ipairs({ 121, 128 }) do
            ctx.row, ctx.col = row, 9
            assert.are.same(memory_property_markdown.reg, dtls.hover(ctx))
        end
    end)

    it("returns hover markdown for /memory `initial-mapped-area` property name", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:123:9")
        assert.are.same(memory_property_markdown["initial-mapped-area"], dtls.hover(ctx))
    end)

    it("returns hover markdown for /memory `hotpluggable` property name", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:122:9")
        assert.are.same(memory_property_markdown.hotpluggable, dtls.hover(ctx))
    end)

    it("calls in_a_memory_node() to determine the type of node", function()
        local in_a_memory_node = spy.on(dtls, "in_a_memory_node")

        ctx.row, ctx.col = row_col("tests/custom.dts:120:9")
        dtls.hover(ctx)

        assert.spy(in_a_memory_node).was_called()
        assert.spy(in_a_memory_node).returned_with(true)
    end)

    local reserved_memory_node_markdown = dtls.dedent([[
        # Devicetree Specification:

        ## `/reserved-memory` node

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
        ```
    ]])

    it("returns hover markdown for /reserved-memory node", function()
        local positions = {
            "tests/custom.dts:132:5", -- reserved-memory
            "tests/custom.dts:159:5", -- closing brace
        }

        for _, position in ipairs(positions) do
            ctx.row, ctx.col = row_col(position)
            assert.are.same(reserved_memory_node_markdown, dtls.hover(ctx))
        end
    end)

    it("calls on_a_reserved_memory_node() to determine the type of node", function()
        local on_a_reserved_memory_node = spy.on(dtls, "on_a_reserved_memory_node")

        ctx.row, ctx.col = row_col("tests/custom.dts:132:5")
        dtls.hover(ctx)

        assert.spy(on_a_reserved_memory_node).was_called()
        assert.spy(on_a_reserved_memory_node).returned_with(true)
    end)

    local reserved_memory_property_markdown = {
        ["#address-cells"] = dtls.dedent([[
            # Devicetree Specification:

            ## Property Name: #address-cells

            ## Path: /reserved-memory/#address-cells

            ## Usage: Required

            ## Definition:

            Specifies the number of `<u32>` cells to represent the address in the `reg` property in children of root.

            `#address-cells` and `#size-cells` should use the same values as for the root node, and `ranges` should be empty so that address translation logic works correctly.
        ]]) .. dtls.get_type_definition("u32"),
        ["#size-cells"] = dtls.dedent([[
            # Devicetree Specification:

            ## Property Name: #size-cells

            ## Path: /reserved-memory/#size-cells

            ## Usage: Required

            ## Definition:

            Specifies the number of `<u32>` cells to represent the size in the `reg` property in children of root.

            `#address-cells` and `#size-cells` should use the same values as for the root node, and `ranges` should be empty so that address translation logic works correctly.
        ]]) .. dtls.get_type_definition("u32"),
        ranges = dtls.dedent([[
            # Devicetree Specification:

            ## Property Name: ranges

            ## Path: /reserved-memory/ranges

            ## Usage: Required

            ## Definition:

            This property represents the mapping between parent address to child address spaces.

            `#address-cells` and `#size-cells` should use the same values as for the root node, and `ranges` should be empty so that address translation logic works correctly.
        ]]) .. dtls.get_type_definition("prop_encoded_array"),
    }

    it("returns hover markdown for /reserved-memory `#address-cells` property name", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:133:9")
        assert.are.same(reserved_memory_property_markdown["#address-cells"], dtls.hover(ctx))
    end)

    it("returns hover markdown for /reserved-memory `#size-cells` property name", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:134:9")
        assert.are.same(reserved_memory_property_markdown["#size-cells"], dtls.hover(ctx))
    end)

    it("returns hover markdown for /reserved-memory `ranges` property name", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:135:9")
        assert.are.same(reserved_memory_property_markdown.ranges, dtls.hover(ctx))
    end)

    it("does not return reserved-memory property hover markdown outside /reserved-memory", function()
        local positions = {
            "tests/custom.dts:19:5", -- root #address-cells
            "tests/custom.dts:20:5", -- root #size-cells
            "tests/custom.dts:260:5", -- root ranges
        }

        for _, position in ipairs(positions) do
            ctx.row, ctx.col = row_col(position)
            local actual = dtls.hover(ctx)
            assert.are_not.same(reserved_memory_property_markdown["#address-cells"], actual)
            assert.are_not.same(reserved_memory_property_markdown["#size-cells"], actual)
            assert.are_not.same(reserved_memory_property_markdown.ranges, actual)
        end
    end)

    it("does not confuse root cell properties with /reserved-memory cell properties", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:19:5")
        assert.are_not.same(reserved_memory_property_markdown["#address-cells"], dtls.hover(ctx))

        ctx.row, ctx.col = row_col("tests/custom.dts:20:5")
        assert.are_not.same(reserved_memory_property_markdown["#size-cells"], dtls.hover(ctx))
    end)

    it("calls in_a_reserved_memory_node() to determine the type of node", function()
        local in_a_reserved_memory_node = spy.on(dtls, "in_a_reserved_memory_node")

        ctx.row, ctx.col = row_col("tests/custom.dts:133:9")
        dtls.hover(ctx)

        assert.spy(in_a_reserved_memory_node).was_called()
        assert.spy(in_a_reserved_memory_node).returned_with(true)
    end)

    local function reserved_memory_region_node_markdown(region_path)
        return dtls.dedent(([[
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
            ```
        ]]):format(region_path))
    end

    it("returns hover markdown for /reserved-memory/linux,cma node", function()
        local expected = reserved_memory_region_node_markdown("/reserved-memory/linux,cma")
        ctx.row, ctx.col = row_col("tests/custom.dts:138:9")
        assert.are.same(expected, dtls.hover(ctx))
    end)

    it("returns hover markdown for /reserved-memory/framebuffer@78000000 node", function()
        local expected = reserved_memory_region_node_markdown(
            "/reserved-memory/framebuffer@78000000"
        )

        ctx.row, ctx.col = row_col("tests/custom.dts:148:27")
        assert.are.same(expected, dtls.hover(ctx))
    end)

    it("calls on_a_reserved_memory_region_node() to determine the type of node", function()
        local on_a_reserved_memory_region_node = spy.on(dtls, "on_a_reserved_memory_region_node")

        ctx.row, ctx.col = row_col("tests/custom.dts:138:9")
        dtls.hover(ctx)

        assert.spy(on_a_reserved_memory_region_node).was_called()
        assert.spy(on_a_reserved_memory_region_node).returned_with(true)
    end)

    local function reserved_memory_region_property_markdown(region_path)
        return {
            reg = dtls.dedent(([[
            # Devicetree Specification:

            ## Property Name: reg

            ## Path: %s/reg

            ## Usage: Optional

            ## Definition:

            Consists of an arbitrary number of address and size pairs that specify the physical address and size of the memory ranges.

            A reserved memory node requires either a `reg` property for static allocations, or a `size` property for dynamics allocations. Dynamic allocations may use `alignment` and `alloc-ranges` properties to constrain where the memory is allocated from. If both `reg` and `size` are present, then the region is treated as a static allocation with the `reg` property taking precedence and `size` is ignored.

            All other standard properties are allowed but are optional.
        ]]):format(region_path)) .. dtls.get_type_definition("prop_encoded_array"),
            size = dtls.dedent(([[
            # Devicetree Specification:

            ## Property Name: size

            ## Path: %s/size

            ## Usage: Optional

            ## Definition:

            Size in bytes of memory to reserve for dynamically allocated regions. Size of this property is based on parent node's `#size-cells` property.

            A reserved memory node requires either a `reg` property for static allocations, or a `size` property for dynamics allocations. Dynamic allocations may use `alignment` and `alloc-ranges` properties to constrain where the memory is allocated from. If both `reg` and `size` are present, then the region is treated as a static allocation with the `reg` property taking precedence and `size` is ignored.

            All other standard properties are allowed but are optional.
        ]]):format(region_path)) .. dtls.get_type_definition("prop_encoded_array"),
            alignment = dtls.dedent(([[
            # Devicetree Specification:

            ## Property Name: alignment

            ## Path: %s/alignment

            ## Usage: Optional

            ## Definition:

            Address boundary for alignment of allocation. Size of this property is based on parent node's `#size-cells` property.

            A reserved memory node requires either a `reg` property for static allocations, or a `size` property for dynamics allocations. Dynamic allocations may use `alignment` and `alloc-ranges` properties to constrain where the memory is allocated from. If both `reg` and `size` are present, then the region is treated as a static allocation with the `reg` property taking precedence and `size` is ignored.

            All other standard properties are allowed but are optional.
        ]]):format(region_path)) .. dtls.get_type_definition("prop_encoded_array"),
            ["alloc-ranges"] = dtls.dedent(([[
            # Devicetree Specification:

            ## Property Name: alloc-ranges

            ## Path: %s/alloc-ranges

            ## Usage: Optional

            ## Definition:

            Specifies regions of memory that are acceptable to allocate from. Format is (address, length pairs) tuples in same format as for `reg` properties.

            A reserved memory node requires either a `reg` property for static allocations, or a `size` property for dynamics allocations. Dynamic allocations may use `alignment` and `alloc-ranges` properties to constrain where the memory is allocated from. If both `reg` and `size` are present, then the region is treated as a static allocation with the `reg` property taking precedence and `size` is ignored.

            All other standard properties are allowed but are optional.
        ]]):format(region_path)) .. dtls.get_type_definition("prop_encoded_array"),
            compatible = dtls.dedent(([[
            # Devicetree Specification:

            ## Property Name: compatible

            ## Path: %s/compatible

            ## Usage: Optional

            ## Definition:

            May contain the following strings:
            - `shared-dma-pool`: This indicates a region of memory meant to be used as a shared pool of DMA buffers for a set of devices. It can be used by an operating system to instantiate the necessary pool management subsystem if necessary.
            - vendor specific string in the form `<vendor>,[<device>-]<usage>`

            All other standard properties are allowed but are optional.
        ]]):format(region_path)) .. dtls.get_type_definition("stringlist"),
            ["no-map"] = dtls.dedent(([[
            # Devicetree Specification:

            ## Property Name: no-map

            ## Path: %s/no-map

            ## Usage: Optional

            ## Definition:

            If present, indicates the operating system must not create a virtual mapping of the region as part of its standard mapping of system memory, nor permit speculative access to it under any circumstances other than under the control of the device driver using the region.

            The `no-map` and `reusable` properties are mutually exclusive and both must not be used together in the same node.

            All other standard properties are allowed but are optional.
        ]]):format(region_path)) .. dtls.get_type_definition("empty"),
            reusable = dtls.dedent(([[
            # Devicetree Specification:

            ## Property Name: reusable

            ## Path: %s/reusable

            ## Usage: Optional

            ## Definition:

            The operating system can use the memory in this region with the limitation that the device driver(s) owning the region need to be able to reclaim it back. Typically that means that the operating system can use that region to store volatile or cached data that can be otherwise regenerated or migrated elsewhere.

            The `no-map` and `reusable` properties are mutually exclusive and both must not be used together in the same node.

            All other standard properties are allowed but are optional.
        ]]):format(region_path)) .. dtls.get_type_definition("empty"),
            ["linux,cma-default"] = dtls.dedent(([[
            # Devicetree Specification:

            ## Property Name: linux,cma-default

            ## Path: %s/linux,cma-default

            ## Usage: Optional

            ## Definition:

            If present, then Linux will use the region for the default pool of the contiguous memory allocator.

            All other standard properties are allowed but are optional.
        ]]):format(region_path)) .. dtls.get_type_definition("empty"),
            ["linux,dma-default"] = dtls.dedent(([[
            # Devicetree Specification:

            ## Property Name: linux,dma-default

            ## Path: %s/linux,dma-default

            ## Usage: Optional

            ## Definition:

            If present, then Linux will use the region for the default pool of the consistent DMA allocator.

            All other standard properties are allowed but are optional.
        ]]):format(region_path)) .. dtls.get_type_definition("empty"),
        }
    end

    local linux_cma_property_markdown = reserved_memory_region_property_markdown(
        "/reserved-memory/linux,cma"
    )
    local framebuffer_property_markdown = reserved_memory_region_property_markdown(
        "/reserved-memory/framebuffer@78000000"
    )
    local multimedia_property_markdown = reserved_memory_region_property_markdown(
        "/reserved-memory/multimedia@77000000"
    )

    it("returns hover markdown for reserved-memory region `reg` property name", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:150:13")
        assert.are.same(framebuffer_property_markdown.reg, dtls.hover(ctx))

        ctx.row, ctx.col = row_col("tests/custom.dts:156:13")
        assert.are.same(multimedia_property_markdown.reg, dtls.hover(ctx))
    end)

    it("returns hover markdown for reserved-memory region `size` property name", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:141:13")
        assert.are.same(linux_cma_property_markdown.size, dtls.hover(ctx))
    end)

    it("returns hover markdown for reserved-memory region `alignment` property name", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:142:13")
        assert.are.same(linux_cma_property_markdown.alignment, dtls.hover(ctx))
    end)

    it("returns hover markdown for reserved-memory region `alloc-ranges` property name", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:145:13")
        assert.are.same(linux_cma_property_markdown["alloc-ranges"], dtls.hover(ctx))
    end)

    it("returns hover markdown for reserved-memory region `compatible` property name", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:139:13")
        assert.are.same(linux_cma_property_markdown.compatible, dtls.hover(ctx))

        ctx.row, ctx.col = row_col("tests/custom.dts:155:13")
        assert.are.same(multimedia_property_markdown.compatible, dtls.hover(ctx))
    end)

    it("returns hover markdown for reserved-memory region `no-map` property name", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:144:13")
        assert.are.same(linux_cma_property_markdown["no-map"], dtls.hover(ctx))
    end)

    it("returns hover markdown for reserved-memory region `reusable` property name", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:140:13")
        assert.are.same(linux_cma_property_markdown.reusable, dtls.hover(ctx))

        ctx.row, ctx.col = row_col("tests/custom.dts:149:13")
        assert.are.same(framebuffer_property_markdown.reusable, dtls.hover(ctx))
    end)

    it("returns hover markdown for reserved-memory region `linux,cma-default` property name", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:143:13")
        assert.are.same(linux_cma_property_markdown["linux,cma-default"], dtls.hover(ctx))

        ctx.row, ctx.col = row_col("tests/custom.dts:151:13")
        assert.are.same(
            framebuffer_property_markdown["linux,cma-default"],
            dtls.hover(ctx)
        )
    end)

    it("returns hover markdown for reserved-memory region `linux,dma-default` property name", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:157:13")
        assert.are.same(
            multimedia_property_markdown["linux,dma-default"],
            dtls.hover(ctx)
        )
    end)

    it("does not return reserved-memory region property hover markdown outside region nodes", function()
        local properties = {
            { expected = linux_cma_property_markdown.compatible, position = "tests/custom.dts:17:5" },
            { expected = framebuffer_property_markdown.reg, position = "tests/custom.dts:258:5" },
        }

        for _, property in ipairs(properties) do
            ctx.row, ctx.col = row_col(property.position)
            assert.is_false(property.expected == dtls.hover(ctx))
        end
    end)

    it("does not return reserved-memory region property hover markdown on /reserved-memory", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:135:9")
        assert.are_not.same(linux_cma_property_markdown.reg, dtls.hover(ctx))
    end)

    it("calls in_a_reserved_memory_region_node() to determine the type of node", function()
        local in_a_reserved_memory_region_node = spy.on(dtls, "in_a_reserved_memory_region_node")

        ctx.row, ctx.col = row_col("tests/custom.dts:139:13")
        dtls.hover(ctx)

        assert.spy(in_a_reserved_memory_region_node).was_called()
        assert.spy(in_a_reserved_memory_region_node).returned_with(true)
    end)

    local memory_region_property_markdown = {
        ["memory-region"] = dtls.dedent([[
            # Devicetree Specification:

            ## Property Name: memory-region

            ## Path: /child/memory-region

            ## Usage: Optional

            ## Definition:

            phandle, specifier pairs to children of `/reserved-memory`
        ]]) .. dtls.get_type_definition("prop_encoded_array"),
        ["memory-region-names"] = dtls.dedent([[
            # Devicetree Specification:

            ## Property Name: memory-region-names

            ## Path: /child/memory-region-names

            ## Usage: Optional

            ## Definition:

            A list of names, one for each corresponding entry in the `memory-region` property
        ]]) .. dtls.get_type_definition("stringlist"),
    }

    it("returns hover markdown for `memory-region` property name", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:352:9")
        assert.are.same(memory_region_property_markdown["memory-region"], dtls.hover(ctx))
    end)

    it("returns the device path for `memory-region` property name", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:164:9")
        local markdown = memory_region_property_markdown["memory-region"]:gsub(
            "/child/memory%-region",
            "/video@12300000/memory-region"
        )
        assert.are.same(markdown, dtls.hover(ctx))
    end)

    it("returns hover markdown for `memory-region-names` property name", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:353:9")
        assert.are.same(memory_region_property_markdown["memory-region-names"], dtls.hover(ctx))
    end)

    it("does not return memory-region property hover markdown outside device nodes", function()
        local positions = {
            "tests/custom.dts:269:5",
            "tests/custom.dts:270:5",
            "tests/custom.dts:290:13",
            "tests/custom.dts:291:13",
        }

        for _, position in ipairs(positions) do
            ctx.row, ctx.col = row_col(position)
            assert.is_nil(dtls.hover(ctx))
        end
    end)

    it("calls in_possible_memory_region_consumer() to determine the type of node", function()
        local in_possible_memory_region_consumer = spy.on(
            dtls,
            "in_possible_memory_region_consumer"
        )

        ctx.row, ctx.col = row_col("tests/custom.dts:352:9")
        dtls.hover(ctx)

        assert.spy(in_possible_memory_region_consumer).was_called()
        assert.spy(in_possible_memory_region_consumer).returned_with(true)
    end)

    local chosen_node_markdown = dtls.dedent([[
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

        Older versions of devicetrees may be encountered that contain a deprecated form of the `stdout-path` property called `linux,stdout-path`. For compatibility, a client program might want to support `linux,stdout-path` if a `stdout-path` property is not present. The meaning and use of the two properties is identical.
    ]])

    it("returns hover markdown for /chosen node", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:52:5")
        assert.are.same(chosen_node_markdown, dtls.hover(ctx))
    end)

    it("calls on_a_chosen_node() to determine the type of node", function()
        local on_a_chosen_node = spy.on(dtls, "on_a_chosen_node")

        ctx.row, ctx.col = row_col("tests/custom.dts:52:5")
        dtls.hover(ctx)

        assert.spy(on_a_chosen_node).was_called()
        assert.spy(on_a_chosen_node).returned_with(true)
    end)

    local chosen_property_markdown = {
        bootargs = dtls.dedent([[
            # Devicetree Specification:

            ## Property Name: bootargs

            ## Path: /chosen/bootargs

            ## Usage: Optional

            ## Definition:

            A string that specifies the boot arguments for the client program. The value could potentially be a null string if no boot arguments are required.

            All other standard properties are allowed but are optional.
        ]]) .. dtls.get_type_definition("string"),
        bootsource = dtls.dedent([[
            # Devicetree Specification:

            ## Property Name: bootsource

            ## Path: /chosen/bootsource

            ## Usage: Optional

            ## Definition:

            A string that specifies the full path to the node representing the device the BootROM used to load the initial boot program. If the initial boot program is split into multiple stages, this represents the storage medium or device (e.g. used by fastboot) from which the very first stage was loaded by the BootROM. It may differ from the device from which later stages of the boot program or client program are loaded from, as this property isn't meant to represent those devices. A later stage of the boot program, or the client program, may use this information to favor the device in this property over others for loading later stages, or know the storage medium to flash an update to.

            All other standard properties are allowed but are optional.
        ]]) .. dtls.get_type_definition("string"),
        ["stdout-path"] = dtls.dedent([[
            # Devicetree Specification:

            ## Property Name: stdout-path

            ## Path: /chosen/stdout-path

            ## Usage: Optional

            ## Definition:

            A string that specifies the full path to the node representing the device to be used for boot console output. If the character ":" is present in the value it terminates the path. The value may be an alias. If the stdin-path property is not specified, stdout-path should be assumed to define the input device.

            Older versions of devicetrees may be encountered that contain a deprecated form of the `stdout-path` property called `linux,stdout-path`. For compatibility, a client program might want to support `linux,stdout-path` if a `stdout-path` property is not present. The meaning and use of the two properties is identical.

            All other standard properties are allowed but are optional.
        ]]) .. dtls.get_type_definition("string"),
        ["linux,stdout-path"] = dtls.dedent([[
            # Devicetree Specification:

            ## Property Name: linux,stdout-path

            ## Path: /chosen/linux,stdout-path

            ## Usage: Optional

            ## Definition:

            A string that specifies the full path to the node representing the device to be used for boot console output. If the character ":" is present in the value it terminates the path. The value may be an alias. If the stdin-path property is not specified, stdout-path should be assumed to define the input device.

            Older versions of devicetrees may be encountered that contain a deprecated form of the `stdout-path` property called `linux,stdout-path`. For compatibility, a client program might want to support `linux,stdout-path` if a `stdout-path` property is not present. The meaning and use of the two properties is identical.

            All other standard properties are allowed but are optional.
        ]]) .. dtls.get_type_definition("string"),
        ["stdin-path"] = dtls.dedent([[
            # Devicetree Specification:

            ## Property Name: stdin-path

            ## Path: /chosen/stdin-path

            ## Usage: Optional

            ## Definition:

            A string that specifies the full path to the node representing the device to be used for boot console input. If the character ":" is present in the value it terminates the path. The value may be an alias.

            All other standard properties are allowed but are optional.
        ]]) .. dtls.get_type_definition("string"),
    }

    it("returns hover markdown for /chosen `bootargs` property name", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:296:9")
        assert.are.same(chosen_property_markdown.bootargs, dtls.hover(ctx))
    end)

    it("returns hover markdown for /chosen `bootsource` property name", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:297:9")
        assert.are.same(chosen_property_markdown.bootsource, dtls.hover(ctx))
    end)

    it("returns hover markdown for /chosen `stdout-path` property name", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:298:9")
        assert.are.same(chosen_property_markdown["stdout-path"], dtls.hover(ctx))
    end)

    it("returns hover markdown for deprecated /chosen `linux,stdout-path` property name", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:53:9")
        assert.are.same(chosen_property_markdown["linux,stdout-path"], dtls.hover(ctx))
    end)

    it("returns hover markdown for /chosen `stdin-path` property name", function()
        ctx.row, ctx.col = row_col("tests/custom.dts:299:9")
        assert.are.same(chosen_property_markdown["stdin-path"], dtls.hover(ctx))
    end)

    it("calls in_a_chosen_node() to determine the type of node", function()
        local in_a_chosen_node = spy.on(dtls, "in_a_chosen_node")

        ctx.row, ctx.col = row_col("tests/custom.dts:296:9")
        dtls.hover(ctx)

        assert.spy(in_a_chosen_node).was_called()
        assert.spy(in_a_chosen_node).returned_with(true)
    end)
end)

describe("out_of_tree_without_config()", function()
    it("returns true for an out-of-tree file with no .anakins-dtls at the workspace root", function()
        ctx = {
            file = ("%s/tests/out-of-tree-no-config/one/path/to/devicetree.dts"):format(cwd),
            workspace_root = ("%s/tests/out-of-tree-no-config"):format(cwd),
        }
        assert(dtls.out_of_tree_without_config(ctx))
    end)

    it("returns false when .anakins-dtls is present at the workspace root", function()
        ctx = {
            file = ("%s/tests/out-of-tree/custom.dts"):format(cwd),
            workspace_root = ("%s/tests/out-of-tree"):format(cwd),
        }
        assert(not dtls.out_of_tree_without_config(ctx))
    end)

    it("returns false for an in-tree file (recognizable kernel layout)", function()
        ctx = {
            file = ("%s/tests/in-tree/arch/arm64/boot/dts/freescale/custom.dts"):format(cwd),
            workspace_root = ("%s/tests/in-tree"):format(cwd),
        }
        assert(not dtls.out_of_tree_without_config(ctx))
    end)
end)

describe("missing file", function()
    local function_names = {
        "out_of_tree_without_config",
        "in_a_root_node",
        "on_a_root_node",
        "in_an_aliases_node",
        "on_an_aliases_node",
        "in_a_memory_node",
        "on_a_memory_node",
        "in_a_chosen_node",
        "on_a_chosen_node",
        "in_a_cpus_node",
        "on_a_cpus_node",
        "in_a_cpu_node",
        "on_a_cpu_node",
        "in_a_cache_node",
        "on_a_cache_node",
        "in_a_reserved_memory_node",
        "on_a_reserved_memory_node",
        "in_a_reserved_memory_region_node",
        "on_a_reserved_memory_region_node",
        "in_a_serial_device_node",
        "on_a_serial_device_node",
        "in_a_ns16550_node",
        "on_a_ns16550_node",
        "in_a_network_device_node",
        "on_a_network_device_node",
        "in_an_open_pic_node",
        "on_an_open_pic_node",
        "in_a_simple_bus_node",
        "on_a_simple_bus_node",
        "in_top_level",
        "on_a_label_definition",
        "on_a_label_reference",
    }

    for _, name in ipairs(function_names) do
        it(name .. "() errors if ctx.file does not exist", function()
            ctx = { file = "/nonexistent/custom.dts", row = 1, col = 1 }
            assert.has_error(function()
                dtls[name](ctx)
            end)
        end)
    end
end)
