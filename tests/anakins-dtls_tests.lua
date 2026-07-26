local busted = require("busted")
local assert = require("luassert")
local spy = require("luassert.spy")
local describe = busted.describe
local it = busted.it

package.path = "./lua/?.lua;" .. package.path
local dtls = require("anakins-dtls")

local function row_col(filename_linenumber)
    local row, col = filename_linenumber:match(":(%d+):(%d+)")
    return tonumber(row), tonumber(col)
end

local handle = io.popen("pwd")
local cwd = handle:read("*l")
handle:close()

local dts_locations = {
    { name = "in-tree", path = "arch/arm64/boot/dts/freescale/custom.dts" },
    { name = "out-of-tree", path = "custom.dts" },
}

for _, location in ipairs(dts_locations) do
    local ctx = {
        file = ("%s/tests/%s/%s"):format(cwd, location.name, location.path),
    }

    describe(location.name, function()
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
        end)

        -- describe("in_a_serial_device_node()", function()
        --     it("returns true if in a serial device node", function()
        --         -- inside serial-device { (compatible = "ns8250")
        --         ctx.row, ctx.col = row_col("tests/custom.dts:426:9")
        --         assert(dtls.in_a_serial_device_node(ctx))
        --
        --         -- inside hdlc-device { (compatible = "arinc,x25-hdlc")
        --         ctx.row, ctx.col = row_col("tests/custom.dts:436:9")
        --         assert(dtls.in_a_serial_device_node(ctx))
        --     end)
        --
        --     it("returns false if not in a serial device node", function()
        --         -- inside a non serial device node
        --         ctx.row, ctx.col = row_col("tests/custom.dts:419:9")
        --         assert(not dtls.in_a_serial_device_node(ctx))
        --     end)
        -- end)
        --
        -- describe("on_a_serial_device_node()", function()
        --     it("returns true if on a serial device node", function()
        --         -- serial-device's 's'
        --         ctx.row, ctx.col = row_col("tests/custom.dts:425:5")
        --         assert(dtls.on_a_serial_device_node(ctx))
        --
        --         -- serial-device's '{'
        --         ctx.row, ctx.col = row_col("tests/custom.dts:425:19")
        --         assert(dtls.on_a_serial_device_node(ctx))
        --
        --         -- serial-device's '}'
        --         ctx.row, ctx.col = row_col("tests/custom.dts:428:5")
        --         assert(dtls.on_a_serial_device_node(ctx))
        --
        --         -- serial-device's ';'
        --         ctx.row, ctx.col = row_col("tests/custom.dts:428:6")
        --         assert(dtls.on_a_serial_device_node(ctx))
        --     end)
        --
        --     it("returns false if not on a serial device node", function()
        --         -- on miscellaneous-device's 'm'
        --         ctx.row, ctx.col = row_col("tests/custom.dts:415:5")
        --         assert(not dtls.on_a_serial_device_node(ctx))
        --
        --         -- inside serial-device
        --         ctx.row, ctx.col = row_col("tests/custom.dts:426:9")
        --         assert(not dtls.on_a_serial_device_node(ctx))
        --     end)
        -- end)
        --
        -- describe("in_a_ns16550_node()", function()
        --     it("returns true if in a ns16550 node", function()
        --         -- inside uart@4600 { (compatible = "ns16550")
        --         ctx.row, ctx.col = row_col("tests/custom.dts:440:9")
        --         assert(dtls.in_a_ns16550_node(ctx))
        --     end)
        --
        --     it("returns false if not in a ns16550 node", function()
        --         -- inside serial-device (compatible = "ns8250", not ns16550)
        --         ctx.row, ctx.col = row_col("tests/custom.dts:426:9")
        --         assert(not dtls.in_a_ns16550_node(ctx))
        --
        --         -- on miscellaneous-device's 'm'
        --         ctx.row, ctx.col = row_col("tests/custom.dts:416:9")
        --         assert(not dtls.in_a_ns16550_node(ctx))
        --     end)
        -- end)
        --
        -- describe("on_a_ns16550_node()", function()
        --     it("returns true if on a ns16550 node", function()
        --         -- uart@4600's 'u'
        --         ctx.row, ctx.col = row_col("tests/custom.dts:439:5")
        --         assert(dtls.on_a_ns16550_node(ctx))
        --
        --         -- uart@4600's '{'
        --         ctx.row, ctx.col = row_col("tests/custom.dts:439:15")
        --         assert(dtls.on_a_ns16550_node(ctx))
        --
        --         -- uart@4600's '}'
        --         ctx.row, ctx.col = row_col("tests/custom.dts:447:5")
        --         assert(dtls.on_a_ns16550_node(ctx))
        --
        --         -- uart@4600's ';'
        --         ctx.row, ctx.col = row_col("tests/custom.dts:447:6")
        --         assert(dtls.on_a_ns16550_node(ctx))
        --
        --         -- uart@4600's '@'
        --         ctx.row, ctx.col = row_col("tests/custom.dts:439:9")
        --         assert(dtls.on_a_ns16550_node(ctx))
        --
        --         -- uart@4600's '4'
        --         ctx.row, ctx.col = row_col("tests/custom.dts:439:10")
        --         assert(dtls.on_a_ns16550_node(ctx))
        --     end)
        --
        --     it("returns false if not on a ns16550 node", function()
        --         -- on serial-device's 's' (compatible = "ns8250")
        --         ctx.row, ctx.col = row_col("tests/custom.dts:425:5")
        --         assert(not dtls.on_a_ns16550_node(ctx))
        --
        --         -- inside uart@4600
        --         ctx.row, ctx.col = row_col("tests/custom.dts:440:9")
        --         assert(not dtls.on_a_ns16550_node(ctx))
        --     end)
        -- end)
        --
        -- describe("in_a_network_device_node()", function()
        --     it("returns true if in a network device node", function()
        --         -- inside ethernet@0
        --         ctx.row, ctx.col = row_col("tests/custom.dts:450:9")
        --         assert(dtls.in_a_network_device_node(ctx))
        --
        --         -- inside ethernet@1
        --         ctx.row, ctx.col = row_col("tests/custom.dts:457:9")
        --         assert(dtls.in_a_network_device_node(ctx))
        --     end)
        --
        --     it("returns false if not in a network device node", function()
        --         -- inside uart@4600, an unrelated device
        --         ctx.row, ctx.col = row_col("tests/custom.dts:440:9")
        --         assert(not dtls.in_a_network_device_node(ctx))
        --
        --         -- on ethernet@1's 'e'
        --         ctx.row, ctx.col = row_col("tests/custom.dts:456:5")
        --         assert(not dtls.in_a_network_device_node(ctx))
        --     end)
        -- end)
        --
        -- describe("on_a_network_device_node()", function()
        --     it("returns true if on a network device node", function()
        --         -- ethernet@0's 'e'
        --         ctx.row, ctx.col = row_col("tests/custom.dts:449:5")
        --         assert(dtls.on_a_network_device_node(ctx))
        --
        --         -- ethernet@0's '{'
        --         ctx.row, ctx.col = row_col("tests/custom.dts:449:16")
        --         assert(dtls.on_a_network_device_node(ctx))
        --
        --         -- ethernet@0's '}'
        --         ctx.row, ctx.col = row_col("tests/custom.dts:454:5")
        --         assert(dtls.on_a_network_device_node(ctx))
        --
        --         -- ethernet@0's ';'
        --         ctx.row, ctx.col = row_col("tests/custom.dts:454:6")
        --         assert(dtls.on_a_network_device_node(ctx))
        --
        --         -- ethernet@0's '@'
        --         ctx.row, ctx.col = row_col("tests/custom.dts:449:13")
        --         assert(dtls.on_a_network_device_node(ctx))
        --
        --         -- ethernet@0's '0'
        --         ctx.row, ctx.col = row_col("tests/custom.dts:449:14")
        --         assert(dtls.on_a_network_device_node(ctx))
        --
        --         -- ethernet@1's 'e'
        --         ctx.row, ctx.col = row_col("tests/custom.dts:456:5")
        --         assert(dtls.on_a_network_device_node(ctx))
        --     end)
        --
        --     it("returns false if not on a network device node", function()
        --         -- on uart@4600's 'u'
        --         ctx.row, ctx.col = row_col("tests/custom.dts:439:5")
        --         assert(not dtls.on_a_network_device_node(ctx))
        --
        --         -- inside ethernet@0
        --         ctx.row, ctx.col = row_col("tests/custom.dts:450:9")
        --         assert(not dtls.on_a_network_device_node(ctx))
        --     end)
        -- end)
        --
        -- describe("in_an_open_pic_node()", function()
        --     it("returns true if in an open-pic node", function()
        --         -- inside interrupt-controller@10000000 { (compatible = "open-pic")
        --         ctx.row, ctx.col = row_col("tests/custom.dts:463:9")
        --         assert(dtls.in_an_open_pic_node(ctx))
        --     end)
        --
        --     it("returns false if not in an open-pic node", function()
        --         -- inside pic@10000000, which has no compatible property
        --         ctx.row, ctx.col = row_col("tests/custom.dts:227:9")
        --         assert(not dtls.in_an_open_pic_node(ctx))
        --     end)
        -- end)
        --
        -- describe("on_an_open_pic_node()", function()
        --     it("returns true if on an open-pic node", function()
        --         -- interrupt-controller@10000000's 'i'
        --         ctx.row, ctx.col = row_col("tests/custom.dts:462:5")
        --         assert(dtls.on_an_open_pic_node(ctx))
        --
        --         -- interrupt-controller@10000000's '{'
        --         ctx.row, ctx.col = row_col("tests/custom.dts:462:35")
        --         assert(dtls.on_an_open_pic_node(ctx))
        --
        --         -- interrupt-controller@10000000's '}'
        --         ctx.row, ctx.col = row_col("tests/custom.dts:468:5")
        --         assert(dtls.on_an_open_pic_node(ctx))
        --
        --         -- interrupt-controller@10000000's ';'
        --         ctx.row, ctx.col = row_col("tests/custom.dts:468:6")
        --         assert(dtls.on_an_open_pic_node(ctx))
        --
        --         -- interrupt-controller@10000000's '@'
        --         ctx.row, ctx.col = row_col("tests/custom.dts:462:25")
        --         assert(dtls.on_an_open_pic_node(ctx))
        --
        --         -- interrupt-controller@10000000's '1'
        --         ctx.row, ctx.col = row_col("tests/custom.dts:462:26")
        --         assert(dtls.on_an_open_pic_node(ctx))
        --     end)
        --
        --     it("returns false if not on an open-pic node", function()
        --         -- on pic@10000000's 'p' (no compatible property)
        --         ctx.row, ctx.col = row_col("tests/custom.dts:226:5")
        --         assert(not dtls.on_an_open_pic_node(ctx))
        --
        --         -- inside interrupt-controller@10000000
        --         ctx.row, ctx.col = row_col("tests/custom.dts:463:9")
        --         assert(not dtls.on_an_open_pic_node(ctx))
        --     end)
        -- end)
        --
        -- describe("in_a_simple_bus_node()", function()
        --     it("returns true if in a simple-bus node", function()
        --         -- inside the second soc { (compatible = "simple-bus")
        --         ctx.row, ctx.col = row_col("tests/custom.dts:471:9")
        --         assert(dtls.in_a_simple_bus_node(ctx))
        --     end)
        --
        --     it("returns false if not in a simple-bus node", function()
        --         -- inside the first soc {
        --         ctx.row, ctx.col = row_col("tests/custom.dts:234:13")
        --         assert(not dtls.in_a_simple_bus_node(ctx))
        --     end)
        -- end)
        --
        -- describe("on_a_simple_bus_node()", function()
        --     it("returns true if on a simple-bus node", function()
        --         -- soc's 's'
        --         ctx.row, ctx.col = row_col("tests/custom.dts:470:5")
        --         assert(dtls.on_a_simple_bus_node(ctx))
        --
        --         -- soc's '{'
        --         ctx.row, ctx.col = row_col("tests/custom.dts:470:9")
        --         assert(dtls.on_a_simple_bus_node(ctx))
        --
        --         -- soc's '}'
        --         ctx.row, ctx.col = row_col("tests/custom.dts:474:5")
        --         assert(dtls.on_a_simple_bus_node(ctx))
        --
        --         -- soc's ';'
        --         ctx.row, ctx.col = row_col("tests/custom.dts:474:6")
        --         assert(dtls.on_a_simple_bus_node(ctx))
        --     end)
        --
        --     it("returns false if not on a simple-bus node", function()
        --         -- on the first soc's 's' (no compatible property)
        --         ctx.row, ctx.col = row_col("tests/custom.dts:232:5")
        --         assert(not dtls.on_a_simple_bus_node(ctx))
        --
        --         -- inside the second soc
        --         ctx.row, ctx.col = row_col("tests/custom.dts:471:9")
        --         assert(not dtls.on_a_simple_bus_node(ctx))
        --     end)
        -- end)
        --
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

            it("does not return /aliases hover markdown for descendant aliases nodes", function()
                ctx.row, ctx.col = row_col("tests/custom.dts:114:9")
                assert.is_nil(dtls.hover(ctx))
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
                    # Anakin's Advice

                    A client program, such as Linux, Zephyr, or U-Boot, can look up the alias `ethernet1` to refer to this node.
                ]])
                local actual = dtls.hover(ctx)
                assert.are.same(expected, actual)

                ctx.row, ctx.col = row_col("tests/custom.dts:27:9")
                expected = dtls.dedent([[
                    # Anakin's Advice

                    A client program, such as Linux, Zephyr, or U-Boot, can look up the alias `gpio0` to refer to this node.
                ]])
                actual = dtls.hover(ctx)
                assert.are.same(expected, actual)
            end)

            it("returns hover markdown across an alias property name", function()
                local expected = dtls.dedent([[
                    # Anakin's Advice

                    A client program, such as Linux, Zephyr, or U-Boot, can look up the alias `ethernet1` to refer to this node.
                ]])

                for col = 9, 17 do
                    ctx.row, ctx.col = 26, col
                    local actual = dtls.hover(ctx)
                    assert.are.same(expected, actual)
                end
            end)

            it("does not return alias hover markdown outside a property name", function()
                for _, col in ipairs({ 8, 18, 19, 20, 21, 25, 26 }) do
                    ctx.row, ctx.col = 26, col
                    assert.is_nil(dtls.hover(ctx))
                end
            end)

            it("does not return alias hover markdown in descendant aliases nodes", function()
                ctx.row, ctx.col = row_col("tests/custom.dts:115:13")
                assert.is_nil(dtls.hover(ctx))
            end)

            it("calls in_an_aliases_node() to determine the type of node", function()
                local in_an_aliases_node = spy.on(dtls, "in_an_aliases_node")

                ctx.row, ctx.col = row_col("tests/custom.dts:26:9")
                dtls.hover(ctx)

                assert.spy(in_an_aliases_node).was_called()
                assert.spy(in_an_aliases_node).returned_with(true)
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

            it("returns /memory hover markdown across node declarations", function()
                for col = 5, 12 do
                    ctx.row, ctx.col = 119, col
                    assert.are.same(memory_node_markdown, dtls.hover(ctx))
                end

                for col = 5, 14 do
                    ctx.row, ctx.col = 126, col
                    assert.are.same(memory_node_markdown, dtls.hover(ctx))
                end
            end)

            it("does not return /memory hover markdown outside node declaration boundaries", function()
                local positions = {
                    "tests/custom.dts:119:13",
                    "tests/custom.dts:124:4",
                    "tests/custom.dts:124:7",
                    "tests/custom.dts:126:15",
                    "tests/custom.dts:130:4",
                    "tests/custom.dts:130:7",
                }

                for _, position in ipairs(positions) do
                    ctx.row, ctx.col = row_col(position)
                    assert.is_nil(dtls.hover(ctx))
                end
            end)

            it("does not return /memory node hover markdown inside or between memory nodes", function()
                local property_positions = {
                    "tests/custom.dts:120:9", -- property in memory
                    "tests/custom.dts:123:9", -- property in memory
                    "tests/custom.dts:127:9", -- property in memory@0
                }

                for _, position in ipairs(property_positions) do
                    ctx.row, ctx.col = row_col(position)
                    assert.are_not.same(memory_node_markdown, dtls.hover(ctx))
                end

                ctx.row, ctx.col = row_col("tests/custom.dts:125:1") -- blank line between memory nodes
                assert.is_nil(dtls.hover(ctx))
            end)

            it("does not return /memory hover markdown for descendant memory nodes", function()
                ctx.row, ctx.col = row_col("tests/custom.dts:369:9")
                assert.is_nil(dtls.hover(ctx))
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

            it("returns hover markdown across memory property names", function()
                local properties = {
                    { name = "device_type", row = 120 },
                    { name = "reg", row = 121 },
                    { name = "hotpluggable", row = 122 },
                    { name = "initial-mapped-area", row = 123 },
                }

                for _, property in ipairs(properties) do
                    for col = 9, 8 + #property.name do
                        ctx.row, ctx.col = property.row, col
                        assert.are.same(memory_property_markdown[property.name], dtls.hover(ctx))
                    end
                end
            end)

            it("does not return memory property hover markdown outside property names", function()
                local positions = {
                    "tests/custom.dts:120:8",
                    "tests/custom.dts:120:20",
                    "tests/custom.dts:120:21",
                    "tests/custom.dts:121:8",
                    "tests/custom.dts:121:12",
                    "tests/custom.dts:121:13",
                    "tests/custom.dts:122:8",
                    "tests/custom.dts:122:21",
                    "tests/custom.dts:123:8",
                    "tests/custom.dts:123:28",
                    "tests/custom.dts:123:29",
                }

                for _, position in ipairs(positions) do
                    ctx.row, ctx.col = row_col(position)
                    assert.is_nil(dtls.hover(ctx))
                end

                ctx.row, ctx.col = row_col("tests/custom.dts:120:9")
                assert.are.same(memory_property_markdown.device_type, dtls.hover(ctx))
            end)

            it("does not return memory property hover markdown outside memory nodes", function()
                local positions = {
                    "tests/custom.dts:265:5", -- device_type
                    "tests/custom.dts:258:5", -- reg
                }

                for _, position in ipairs(positions) do
                    ctx.row, ctx.col = row_col(position)
                    assert.is_nil(dtls.hover(ctx))
                end

                ctx.row, ctx.col = row_col("tests/custom.dts:121:9")
                assert.are.same(memory_property_markdown.reg, dtls.hover(ctx))
            end)

            it("does not return memory property hover markdown in descendant memory nodes", function()
                ctx.row, ctx.col = row_col("tests/custom.dts:370:13")
                assert.is_nil(dtls.hover(ctx))

                ctx.row, ctx.col = row_col("tests/custom.dts:120:9")
                assert.are.same(memory_property_markdown.device_type, dtls.hover(ctx))
            end)

            it("calls in_a_memory_node() to determine the type of node", function()
                local in_a_memory_node = spy.on(dtls, "in_a_memory_node")

                ctx.row, ctx.col = row_col("tests/custom.dts:120:9")
                dtls.hover(ctx)

                assert.spy(in_a_memory_node).was_called()
                assert.spy(in_a_memory_node).returned_with(true)
            end)
        end)
    end)
end

describe("missing file", function()
    local function_names = {
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
            local ctx = { file = "/nonexistent/custom.dts", row = 1, col = 1 }
            assert.has_error(function()
                dtls[name](ctx)
            end)
        end)
    end
end)
