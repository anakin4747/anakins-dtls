Goals:
- parameterize tests to run for both in-tree and out-of-tree to avoid duplicate
  tests

Use the same fixture file for in-tree and out-of-tree

And then for the in-tree tests insert the fixture in the tree while for the out
of tree situations



have the fixture file be based on this file `imx93-phyboard-nash.dts` but call
it custom.dts or something and then have arch/arm64/boot/dts/freescale/custom.dts be a symlink to




arch/arm64/boot/dts/freescale/imx93-phyboard-nash.dts which pulls in:
    include/dt-bindings/net/ti-dp83867.h
    arch/arm64/boot/dts/freescale/imx93-phycore-som.dtsi which pulls in:
        include/dt-bindings/leds/common.h
        arch/arm64/boot/dts/freescale/imx93.dtsi which pulls in:
            arch/arm64/boot/dts/freescale/imx91_93_common.dtsi which pulls in:
                include/dt-bindings/clock/imx93-clock.h
                include/dt-bindings/dma/fsl-edma.h
                include/dt-bindings/gpio/gpio.h
                include/dt-bindings/input/input.h
                include/dt-bindings/interrupt-controller/arm-gic.h
                include/dt-bindings/power/fsl,imx93-power.h
                include/dt-bindings/thermal/thermal.h
                arch/arm64/boot/dts/freescale/imx93-pinfunc.h



fixture structure:

custom.dts - copy of imx93-phyboard-nash.dts but will contain additions for false positive tests
in-tree/
  arch/ - for dts and dtsi
  arch/arm64/boot/dts/freescale/custom.dts - symlink pointing to custom.dts
  include/ - for header files
  Documentation/ - for yaml and txt bindings
out-of-tree/
  custom.dts - symlink pointing to custom.dts
  .anakins-dtls - points S to ./linux/
  linux/
    arch/ - for dts and dtsi
    include/ - for header files
    Documentation/ - for yaml and txt bindings

So for parameterizing the in-tree vs out-of-tree

```lua
describe("Test Suite", function()
    local dts_locations = {
        { name = "in-tree", path = "in-tree/arch/arm64/boot/dts/freescale/custom.dts" },
        { name = "out-of-tree", path = "out-of-tree/custom.dts" }
    }

    for _, location in ipairs(dts_locations) do
        it("should run tests for " .. location.name, function()
            -- Load the fixture file
            local fixture_path = case.path
            -- Insert the fixture into the tree or out-of-tree as needed
            if case.name == "in-tree" then
                -- Insert fixture into the in-tree structure
                -- (e.g., copy or symlink to arch/arm64/boot/dts/freescale/custom.dts)
            else
                -- Insert fixture into the out-of-tree structure
                -- (e.g., symlink to out-of-tree/custom.dts)
            end

            -- Run the tests using the fixture
            -- (e.g., compile, validate, etc.)
        end)
    end
end)
```


