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

        describe("/chosen", function()
            it("identifies if in a /chosen node", function()
                -- inside chosen {
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.in_a_chosen_node(ctx))
            end)

            it("identifies if not in a /chosen node", function()
                -- in root node but outside /chosen
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.in_a_chosen_node(ctx))

                -- in /child/chosen
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.in_a_chosen_node(ctx))
            end)

            it("indicates that it is in a root node even in a /chosen node", function()
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.in_a_root_node(ctx))
            end)

            it("identifies if on a /chosen node", function()
                -- /chosen's 'c'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_chosen_node(ctx))

                -- /chosen's '{'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_chosen_node(ctx))

                -- /chosen's '}'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_chosen_node(ctx))

                -- /chosen's ';'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_chosen_node(ctx))
            end)

            it("indicates if not on a /chosen node", function()
                -- on /memory's 'm'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.on_a_chosen_node(ctx))

                -- inside /chosen
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.on_a_chosen_node(ctx))

                -- on /aliases's 'a'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.on_a_chosen_node(ctx))

                -- on /child/chosen's 'c'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.on_a_chosen_node(ctx))
            end)
        end)

        describe("/cpus", function()
            it("identifies if in a /cpus node", function()
                -- inside /cpus {
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.in_a_cpus_node(ctx))
            end)

            it("identifies if not in a /cpus node", function()
                -- in root node but outside /cpus
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.in_a_cpus_node(ctx))

                -- in /child/cpus
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.in_a_cpus_node(ctx))
            end)

            it("indicates that it is in a root node even in a /cpus node", function()
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.in_a_root_node(ctx))
            end)

            it("identifies if on a /cpus node", function()
                -- /cpus' 'c'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_cpus_node(ctx))

                -- /cpus' '{'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_cpus_node(ctx))

                -- /cpus' '}'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_cpus_node(ctx))

                -- /cpus' ';'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_cpus_node(ctx))
            end)

            it("indicates if not on a /cpus node", function()
                -- inside /cpus
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.on_a_cpus_node(ctx))

                -- on /aliases's 'a'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.on_a_cpus_node(ctx))

                -- on /child/cpus's 'c'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.on_a_cpus_node(ctx))
            end)

            it("identifies if in a cpu node", function()
                -- inside cpu@0 {
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.in_a_cpu_node(ctx))
            end)

            it("identifies if not in a cpu node", function()
                -- in /cpus but outside any cpu@N
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.in_a_cpu_node(ctx))
            end)

            it("indicates that it is in a /cpus node and a root node even in a cpu node", function()
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.in_a_cpus_node(ctx))

                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.in_a_root_node(ctx))
            end)

            it("identifies if on a cpu node", function()
                -- cpu@0's 'c'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_cpu_node(ctx))

                -- cpu@0's '{'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_cpu_node(ctx))

                -- cpu@0's '}'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_cpu_node(ctx))

                -- cpu@0's ';'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_cpu_node(ctx))

                -- cpu@0's '@'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_cpu_node(ctx))

                -- cpu@0's '0'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_cpu_node(ctx))
            end)

            it("indicates if not on a cpu node", function()
                -- on /cpus' 'c'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.on_a_cpu_node(ctx))

                -- inside cpu@0
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.on_a_cpu_node(ctx))

                -- on /memory's 'm'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.on_a_cpu_node(ctx))
            end)

            it("identifies if in a cache node", function()
                -- inside l2-cache {
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.in_a_cache_node(ctx))

                -- inside nested l3-cache {
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.in_a_cache_node(ctx))
            end)

            it("identifies if not in a cache node", function()
                -- in cpu@0 but outside any cache node
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.in_a_cache_node(ctx))
            end)

            it("indicates that it is in a cpu, /cpus, and root node even in a cache node", function()
                -- inside l2-cache
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.in_a_cpu_node(ctx))
                assert(dtls.in_a_cpus_node(ctx))
                assert(dtls.in_a_root_node(ctx))

                -- inside nested l3-cache
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.in_a_cpu_node(ctx))
                assert(dtls.in_a_cpus_node(ctx))
                assert(dtls.in_a_root_node(ctx))
            end)

            it("identifies if on a cache node", function()
                -- l2-cache's 'l'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_cache_node(ctx))

                -- l2-cache's '{'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_cache_node(ctx))

                -- l2-cache's '}'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_cache_node(ctx))

                -- l2-cache's ';'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_cache_node(ctx))
            end)

            it("indicates if not on a cache node", function()
                -- on cpu@0's 'c'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.on_a_cache_node(ctx))

                -- inside l2-cache
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.on_a_cache_node(ctx))

                -- on /memory's 'm'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.on_a_cache_node(ctx))
            end)
        end)

        describe("/reserved-memory", function()
            it("identifies if in a /reserved-memory node", function()
                -- inside reserved-memory {
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.in_a_reserved_memory_node(ctx))
            end)

            it("identifies if not in a /reserved-memory node", function()
                -- in root node but outside /reserved-memory
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.in_a_reserved_memory_node(ctx))

                -- in /child/reserved-memory
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.in_a_reserved_memory_node(ctx))
            end)

            it("indicates that it is in a root node even in a /reserved-memory node", function()
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.in_a_root_node(ctx))
            end)

            it("identifies if on a /reserved-memory node", function()
                -- /reserved-memory's 'r'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_reserved_memory_node(ctx))

                -- /reserved-memory's '{'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_reserved_memory_node(ctx))

                -- /reserved-memory's '}'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_reserved_memory_node(ctx))

                -- /reserved-memory's ';'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_reserved_memory_node(ctx))
            end)

            it("indicates if not on a /reserved-memory node", function()
                -- on /memory's 'm'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.on_a_reserved_memory_node(ctx))

                -- inside /reserved-memory
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.on_a_reserved_memory_node(ctx))
            end)

            it("identifies if in a reserved-memory region node", function()
                -- inside linux,cma {
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.in_a_reserved_memory_region_node(ctx))

                -- inside framebuffer@78000000 {
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.in_a_reserved_memory_region_node(ctx))

                -- inside multimedia@77000000 {
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.in_a_reserved_memory_region_node(ctx))
            end)

            it("identifies if not in a reserved-memory region node", function()
                -- in /reserved-memory but outside any region node
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.in_a_reserved_memory_region_node(ctx))
            end)

            it("indicates that it is in a /reserved-memory node and a root node even in a region node", function()
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.in_a_reserved_memory_node(ctx))
                assert(dtls.in_a_root_node(ctx))
            end)

            it("identifies if on a reserved-memory region node", function()
                -- linux,cma's 'l'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_reserved_memory_region_node(ctx))

                -- linux,cma's '{'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_reserved_memory_region_node(ctx))

                -- linux,cma's '}'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_reserved_memory_region_node(ctx))

                -- linux,cma's ';'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_reserved_memory_region_node(ctx))

                -- framebuffer@78000000's '@'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_reserved_memory_region_node(ctx))

                -- framebuffer@78000000's '7'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_reserved_memory_region_node(ctx))
            end)

            it("indicates if not on a reserved-memory region node", function()
                -- on /reserved-memory's 'r'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.on_a_reserved_memory_region_node(ctx))

                -- inside linux,cma
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.on_a_reserved_memory_region_node(ctx))

                -- on /memory's 'm'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.on_a_reserved_memory_region_node(ctx))
            end)
        end)

        describe("serial device", function()
            it("identifies if in a serial device node", function()
                -- inside serial-device { (compatible = "ns8250")
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.in_a_serial_device_node(ctx))

                -- inside hdlc-device { (compatible = "arinc,x25-hdlc")
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.in_a_serial_device_node(ctx))
            end)

            it("identifies if not in a serial device node", function()
                -- inside serial@4500, which has no compatible property
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.in_a_serial_device_node(ctx))

                -- inside ethernet@0, unrelated device
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.in_a_serial_device_node(ctx))
            end)

            it("identifies if on a serial device node", function()
                -- serial-device's 's'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_serial_device_node(ctx))

                -- serial-device's '{'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_serial_device_node(ctx))

                -- serial-device's '}'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_serial_device_node(ctx))

                -- serial-device's ';'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_serial_device_node(ctx))
            end)

            it("indicates if not on a serial device node", function()
                -- on serial@4500's 's' (no compatible property)
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.on_a_serial_device_node(ctx))

                -- inside serial-device
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.on_a_serial_device_node(ctx))
            end)
        end)

        describe("ns16550", function()
            it("identifies if in a ns16550 node", function()
                -- inside uart@4600 { (compatible = "ns16550")
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.in_a_ns16550_node(ctx))
            end)

            it("identifies if not in a ns16550 node", function()
                -- inside serial-device (compatible = "ns8250", not ns16550)
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.in_a_ns16550_node(ctx))

                -- inside serial@4500, which has no compatible property
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.in_a_ns16550_node(ctx))
            end)

            it("identifies if on a ns16550 node", function()
                -- uart@4600's 'u'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_ns16550_node(ctx))

                -- uart@4600's '{'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_ns16550_node(ctx))

                -- uart@4600's '}'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_ns16550_node(ctx))

                -- uart@4600's ';'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_ns16550_node(ctx))

                -- uart@4600's '@'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_ns16550_node(ctx))

                -- uart@4600's '4'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_ns16550_node(ctx))
            end)

            it("indicates if not on a ns16550 node", function()
                -- on serial-device's 's' (compatible = "ns8250")
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.on_a_ns16550_node(ctx))

                -- inside uart@4600
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.on_a_ns16550_node(ctx))
            end)
        end)

        describe("network device", function()
            it("identifies if in a network device node", function()
                -- inside ethernet@0 { (has local-mac-address, mac-address, max-frame-size)
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.in_a_network_device_node(ctx))

                -- inside ethernet@1 { (still a network device even without those
                -- extra properties -- they extend, not gate, the classification)
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.in_a_network_device_node(ctx))
            end)

            it("identifies if not in a network device node", function()
                -- inside uart@4600, an unrelated device
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.in_a_network_device_node(ctx))
            end)

            it("identifies if on a network device node", function()
                -- ethernet@0's 'e'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_network_device_node(ctx))

                -- ethernet@0's '{'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_network_device_node(ctx))

                -- ethernet@0's '}'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_network_device_node(ctx))

                -- ethernet@0's ';'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_network_device_node(ctx))

                -- ethernet@0's '@'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_network_device_node(ctx))

                -- ethernet@0's '0'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_network_device_node(ctx))

                -- ethernet@1's 'e'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_network_device_node(ctx))
            end)

            it("indicates if not on a network device node", function()
                -- on uart@4600's 'u'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.on_a_network_device_node(ctx))

                -- inside ethernet@0
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.on_a_network_device_node(ctx))
            end)
        end)

        describe("open-pic", function()
            it("identifies if in an open-pic node", function()
                -- inside interrupt-controller@10000000 { (compatible = "open-pic")
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.in_an_open_pic_node(ctx))
            end)

            it("identifies if not in an open-pic node", function()
                -- inside pic@10000000, which has no compatible property
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.in_an_open_pic_node(ctx))
            end)

            it("identifies if on an open-pic node", function()
                -- interrupt-controller@10000000's 'i'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_an_open_pic_node(ctx))

                -- interrupt-controller@10000000's '{'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_an_open_pic_node(ctx))

                -- interrupt-controller@10000000's '}'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_an_open_pic_node(ctx))

                -- interrupt-controller@10000000's ';'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_an_open_pic_node(ctx))

                -- interrupt-controller@10000000's '@'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_an_open_pic_node(ctx))

                -- interrupt-controller@10000000's '1'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_an_open_pic_node(ctx))
            end)

            it("indicates if not on an open-pic node", function()
                -- on pic@10000000's 'p' (no compatible property)
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.on_an_open_pic_node(ctx))

                -- inside interrupt-controller@10000000
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.on_an_open_pic_node(ctx))
            end)
        end)

        describe("simple-bus", function()
            it("identifies if in a simple-bus node", function()
                -- inside the second soc { (compatible = "simple-bus")
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.in_a_simple_bus_node(ctx))
            end)

            it("identifies if not in a simple-bus node", function()
                -- inside the first soc {, which has no compatible property
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.in_a_simple_bus_node(ctx))
            end)

            it("identifies if on a simple-bus node", function()
                -- soc's 's'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_simple_bus_node(ctx))

                -- soc's '{'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_simple_bus_node(ctx))

                -- soc's '}'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_simple_bus_node(ctx))

                -- soc's ';'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_simple_bus_node(ctx))
            end)

            it("indicates if not on a simple-bus node", function()
                -- on the first soc's 's' (no compatible property)
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.on_a_simple_bus_node(ctx))

                -- inside the second soc
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.on_a_simple_bus_node(ctx))
            end)
        end)

        describe("top level", function()
            it("identifies if at the top level", function()
                -- before /dts-v1/;
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.in_top_level(ctx))

                -- after the root node's closing '};' and before '&adc1 {'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.in_top_level(ctx))

                -- between '&adc1 { ... };' and '&eqos { ... };'
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.in_top_level(ctx))
            end)

            it("identifies if not at the top level", function()
                -- inside the root node
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.in_top_level(ctx))

                -- inside a &label { ... } reference block
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.in_top_level(ctx))
            end)
        end)

        describe("labels", function()
            it("identifies if on a label definition", function()
                -- curr_sens: current-sense {
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_label_definition(ctx))

                -- display_reserved: framebuffer@78000000 {
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_label_definition(ctx))

                -- L2_0:l2-cache {
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_label_definition(ctx))
            end)

            it("indicates if not on a label definition", function()
                -- on the node name after the label, e.g. "current-sense"
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.on_a_label_definition(ctx))

                -- on a node with no label at all, e.g. "serial-device"
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.on_a_label_definition(ctx))

                -- on a label reference, e.g. "&eqos"
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.on_a_label_definition(ctx))
            end)

            it("identifies if on a label reference", function()
                -- ethernet1 = &eqos;
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_label_reference(ctx))

                -- io-channels = <&adc1 1>;
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_label_reference(ctx))

                -- interrupt-parent = <&pic>;
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_label_reference(ctx))

                -- &adc1 { ... }; top-level reference/override block
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(dtls.on_a_label_reference(ctx))
            end)

            it("indicates if not on a label reference", function()
                -- on a label definition, e.g. "curr_sens:"
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.on_a_label_reference(ctx))

                -- on a property name/value that isn't a label reference
                ctx.row, ctx.col = row_col("tests/custom.dts:")
                assert(not dtls.on_a_label_reference(ctx))
            end)
        end)
    end)
end
