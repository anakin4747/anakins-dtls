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
        describe("in_a_root_node()", function()
            it("returns true if in a root node", function()
                ctx.row, ctx.col = row_col("tests/custom.dts:16:2")
                assert(dtls.in_a_root_node(ctx))
            end)

            it("returns false if not in a root node", function()
                -- before the root node
                ctx.row, ctx.col = row_col("tests/custom.dts:1:1")
                assert(not dtls.in_a_root_node(ctx))

                -- after the root node
                ctx.row, ctx.col = row_col("tests/custom.dts:114:1")
                assert(not dtls.in_a_root_node(ctx))
            end)
        end)

        describe("on_a_root_node()", function()
            it("returns true if on a root node", function()
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
                ctx.row, ctx.col = row_col("tests/custom.dts:20:2")
                assert(not dtls.on_a_root_node(ctx))

                -- /aliases' '}'
                ctx.row, ctx.col = row_col("tests/custom.dts:45:2")
                assert(not dtls.on_a_root_node(ctx))
            end)
        end)

        describe("in_an_aliases_node()", function()
            it("returns true if in an /aliases node", function()
                ctx.row, ctx.col = row_col("tests/custom.dts:21:3")
                assert(dtls.in_an_aliases_node(ctx))
            end)

            it("returns false if not in an /aliases node", function()
                ctx.row, ctx.col = row_col("tests/custom.dts:17:2")
                assert(not dtls.in_an_aliases_node(ctx))
            end)

            it("returns false if in a /child/aliases node", function()
                ctx.row, ctx.col = row_col("tests/custom.dts:114:13")
                assert(not dtls.in_an_aliases_node(ctx))
            end)
        end)

        describe("on_an_aliases_node()", function()
            it("returns true if on an /aliases node", function()
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

            it("returns false if not on an /aliases node", function()
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
        end)

        describe("in_a_serial_device_node()", function()
            it("returns true if in a serial device node", function()
                -- inside serial-device { (compatible = "ns8250")
                ctx.row, ctx.col = row_col("tests/custom.dts:426:9")
                assert(dtls.in_a_serial_device_node(ctx))

                -- inside hdlc-device { (compatible = "arinc,x25-hdlc")
                ctx.row, ctx.col = row_col("tests/custom.dts:436:9")
                assert(dtls.in_a_serial_device_node(ctx))
            end)

            it("returns false if not in a serial device node", function()
                -- inside serial@4500, which has no compatible property
                ctx.row, ctx.col = row_col("tests/custom.dts:431:9")
                assert(not dtls.in_a_serial_device_node(ctx))

                -- inside ethernet@0, unrelated device
                ctx.row, ctx.col = row_col("tests/custom.dts:450:9")
                assert(not dtls.in_a_serial_device_node(ctx))
            end)
        end)

        describe("on_a_serial_device_node()", function()
            it("returns true if on a serial device node", function()
                -- serial-device's 's'
                ctx.row, ctx.col = row_col("tests/custom.dts:425:5")
                assert(dtls.on_a_serial_device_node(ctx))

                -- serial-device's '{'
                ctx.row, ctx.col = row_col("tests/custom.dts:425:19")
                assert(dtls.on_a_serial_device_node(ctx))

                -- serial-device's '}'
                ctx.row, ctx.col = row_col("tests/custom.dts:428:5")
                assert(dtls.on_a_serial_device_node(ctx))

                -- serial-device's ';'
                ctx.row, ctx.col = row_col("tests/custom.dts:428:6")
                assert(dtls.on_a_serial_device_node(ctx))
            end)

            it("returns false if not on a serial device node", function()
                -- on serial@4500's 's' (no compatible property)
                ctx.row, ctx.col = row_col("tests/custom.dts:430:5")
                assert(not dtls.on_a_serial_device_node(ctx))

                -- inside serial-device
                ctx.row, ctx.col = row_col("tests/custom.dts:426:9")
                assert(not dtls.on_a_serial_device_node(ctx))
            end)
        end)

        describe("in_a_ns16550_node()", function()
            it("returns true if in a ns16550 node", function()
                -- inside uart@4600 { (compatible = "ns16550")
                ctx.row, ctx.col = row_col("tests/custom.dts:440:9")
                assert(dtls.in_a_ns16550_node(ctx))
            end)

            it("returns false if not in a ns16550 node", function()
                -- inside serial-device (compatible = "ns8250", not ns16550)
                ctx.row, ctx.col = row_col("tests/custom.dts:426:9")
                assert(not dtls.in_a_ns16550_node(ctx))

                -- inside serial@4500, which has no compatible property
                ctx.row, ctx.col = row_col("tests/custom.dts:431:9")
                assert(not dtls.in_a_ns16550_node(ctx))
            end)
        end)

        describe("on_a_ns16550_node()", function()
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
            it("returns true if in a network device node", function()
                -- inside ethernet@0 { (has local-mac-address, mac-address, max-frame-size)
                ctx.row, ctx.col = row_col("tests/custom.dts:450:9")
                assert(dtls.in_a_network_device_node(ctx))

                -- inside ethernet@1 { (still a network device even without those
                -- extra properties -- they extend, not gate, the classification)
                ctx.row, ctx.col = row_col("tests/custom.dts:457:9")
                assert(dtls.in_a_network_device_node(ctx))
            end)

            it("returns false if not in a network device node", function()
                -- inside uart@4600, an unrelated device
                ctx.row, ctx.col = row_col("tests/custom.dts:440:9")
                assert(not dtls.in_a_network_device_node(ctx))
            end)
        end)

        describe("on_a_network_device_node()", function()
            it("returns true if on a network device node", function()
                -- ethernet@0's 'e'
                ctx.row, ctx.col = row_col("tests/custom.dts:449:5")
                assert(dtls.on_a_network_device_node(ctx))

                -- ethernet@0's '{'
                ctx.row, ctx.col = row_col("tests/custom.dts:449:16")
                assert(dtls.on_a_network_device_node(ctx))

                -- ethernet@0's '}'
                ctx.row, ctx.col = row_col("tests/custom.dts:454:5")
                assert(dtls.on_a_network_device_node(ctx))

                -- ethernet@0's ';'
                ctx.row, ctx.col = row_col("tests/custom.dts:454:6")
                assert(dtls.on_a_network_device_node(ctx))

                -- ethernet@0's '@'
                ctx.row, ctx.col = row_col("tests/custom.dts:449:13")
                assert(dtls.on_a_network_device_node(ctx))

                -- ethernet@0's '0'
                ctx.row, ctx.col = row_col("tests/custom.dts:449:14")
                assert(dtls.on_a_network_device_node(ctx))

                -- ethernet@1's 'e'
                ctx.row, ctx.col = row_col("tests/custom.dts:456:5")
                assert(dtls.on_a_network_device_node(ctx))
            end)

            it("returns false if not on a network device node", function()
                -- on uart@4600's 'u'
                ctx.row, ctx.col = row_col("tests/custom.dts:439:5")
                assert(not dtls.on_a_network_device_node(ctx))

                -- inside ethernet@0
                ctx.row, ctx.col = row_col("tests/custom.dts:450:9")
                assert(not dtls.on_a_network_device_node(ctx))
            end)
        end)

        describe("in_an_open_pic_node()", function()
            it("returns true if in an open-pic node", function()
                -- inside interrupt-controller@10000000 { (compatible = "open-pic")
                ctx.row, ctx.col = row_col("tests/custom.dts:463:9")
                assert(dtls.in_an_open_pic_node(ctx))
            end)

            it("returns false if not in an open-pic node", function()
                -- inside pic@10000000, which has no compatible property
                ctx.row, ctx.col = row_col("tests/custom.dts:227:9")
                assert(not dtls.in_an_open_pic_node(ctx))
            end)
        end)

        describe("on_an_open_pic_node()", function()
            it("returns true if on an open-pic node", function()
                -- interrupt-controller@10000000's 'i'
                ctx.row, ctx.col = row_col("tests/custom.dts:462:5")
                assert(dtls.on_an_open_pic_node(ctx))

                -- interrupt-controller@10000000's '{'
                ctx.row, ctx.col = row_col("tests/custom.dts:462:35")
                assert(dtls.on_an_open_pic_node(ctx))

                -- interrupt-controller@10000000's '}'
                ctx.row, ctx.col = row_col("tests/custom.dts:468:5")
                assert(dtls.on_an_open_pic_node(ctx))

                -- interrupt-controller@10000000's ';'
                ctx.row, ctx.col = row_col("tests/custom.dts:468:6")
                assert(dtls.on_an_open_pic_node(ctx))

                -- interrupt-controller@10000000's '@'
                ctx.row, ctx.col = row_col("tests/custom.dts:462:25")
                assert(dtls.on_an_open_pic_node(ctx))

                -- interrupt-controller@10000000's '1'
                ctx.row, ctx.col = row_col("tests/custom.dts:462:26")
                assert(dtls.on_an_open_pic_node(ctx))
            end)

            it("returns false if not on an open-pic node", function()
                -- on pic@10000000's 'p' (no compatible property)
                ctx.row, ctx.col = row_col("tests/custom.dts:226:5")
                assert(not dtls.on_an_open_pic_node(ctx))

                -- inside interrupt-controller@10000000
                ctx.row, ctx.col = row_col("tests/custom.dts:463:9")
                assert(not dtls.on_an_open_pic_node(ctx))
            end)
        end)

        describe("in_a_simple_bus_node()", function()
            it("returns true if in a simple-bus node", function()
                -- inside the second soc { (compatible = "simple-bus")
                ctx.row, ctx.col = row_col("tests/custom.dts:471:9")
                assert(dtls.in_a_simple_bus_node(ctx))
            end)

            it("returns false if not in a simple-bus node", function()
                -- inside the first soc {, which has no compatible property
                ctx.row, ctx.col = row_col("tests/custom.dts:233:9")
                assert(not dtls.in_a_simple_bus_node(ctx))
            end)
        end)

        describe("on_a_simple_bus_node()", function()
            it("returns true if on a simple-bus node", function()
                -- soc's 's'
                ctx.row, ctx.col = row_col("tests/custom.dts:470:5")
                assert(dtls.on_a_simple_bus_node(ctx))

                -- soc's '{'
                ctx.row, ctx.col = row_col("tests/custom.dts:470:9")
                assert(dtls.on_a_simple_bus_node(ctx))

                -- soc's '}'
                ctx.row, ctx.col = row_col("tests/custom.dts:474:5")
                assert(dtls.on_a_simple_bus_node(ctx))

                -- soc's ';'
                ctx.row, ctx.col = row_col("tests/custom.dts:474:6")
                assert(dtls.on_a_simple_bus_node(ctx))
            end)

            it("returns false if not on a simple-bus node", function()
                -- on the first soc's 's' (no compatible property)
                ctx.row, ctx.col = row_col("tests/custom.dts:232:5")
                assert(not dtls.on_a_simple_bus_node(ctx))

                -- inside the second soc
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
    end)
end
