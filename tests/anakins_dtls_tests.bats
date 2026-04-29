#!/usr/bin/env bats

source ./tests/lsts/lsts

lsts_set_cmd "anakins-dtls"
lsts_set_root "$(dirname "$BATS_TEST_FILENAME")"
lsts_set_langId "dts"

setup() {
    lsts_start
}

teardown() {
    lsts_stop
}

@test "initializes successfully" {
    lsts_initialize
}

@test "initialize advertises hoverProvider" {
    lsts_initialize
    echo "$LSTS_RESPONSE" | jq -e '.result.capabilities.hoverProvider == true'
}

@test "initialize advertises openClose textDocumentSync" {
    lsts_initialize
    echo "$LSTS_RESPONSE" | jq -e '.result.capabilities.textDocumentSync.openClose == true'
}

@test "initialize advertises full textDocumentSync change" {
    lsts_initialize
    echo "$LSTS_RESPONSE" | jq -e '.result.capabilities.textDocumentSync.change == 1'
}

# ---------------------------------------------------------------------------
# Core structure keywords
# Real Linux source: arch/arm64/boot/dts/qcom/sm8550.dtsi
#   model: arch/arm64/boot/dts/qcom/sm8550-qrd.dts
#   phandle/linux,phandle: fixtures/hover_phandle.dts (not in Linux DTS source)
# ---------------------------------------------------------------------------

@test "hover over compatible returns documentation" {
    lsts_hover \
        "linux/arch/arm64/boot/dts/qcom/sm8550.dtsi:39:4" \
        "fixtures/hover_compatible.rpc.json"
}

@test "hover over model returns documentation" {
    lsts_hover \
        "linux/arch/arm64/boot/dts/qcom/sm8550-qrd.dts:22:2" \
        "fixtures/hover_model.rpc.json"
}

@test "hover over device_type returns documentation" {
    lsts_hover \
        "linux/arch/arm64/boot/dts/qcom/sm8550.dtsi:70:4" \
        "fixtures/hover_device_type.rpc.json"
}

@test "hover over status returns documentation" {
    lsts_hover \
        "linux/arch/arm64/boot/dts/qcom/sm8550.dtsi:871:4" \
        "fixtures/hover_status.rpc.json"
}

@test "hover over phandle returns documentation" {
    lsts_hover \
        "fixtures/hover_phandle.dts:3:2" \
        "fixtures/hover_phandle.rpc.json"
}

@test "hover over linux,phandle returns documentation" {
    lsts_hover \
        "fixtures/hover_phandle.dts:4:2" \
        "fixtures/hover_linux_phandle.rpc.json"
}

@test "hover over label returns documentation" {
    lsts_hover \
        "linux/arch/arm64/boot/dts/qcom/sm8550.dtsi:2764:5" \
        "fixtures/hover_label.rpc.json"
}

# ---------------------------------------------------------------------------
# Addressing keywords
# Real Linux source: arch/arm64/boot/dts/qcom/sm8550.dtsi
# ---------------------------------------------------------------------------

@test "hover over reg returns documentation" {
    lsts_hover \
        "linux/arch/arm64/boot/dts/qcom/sm8550.dtsi:72:4" \
        "fixtures/hover_reg.rpc.json"
}

@test "hover over reg-names returns documentation" {
    lsts_hover \
        "linux/arch/arm64/boot/dts/qcom/sm8550.dtsi:1968:4" \
        "fixtures/hover_reg-names.rpc.json"
}

@test "hover over ranges returns documentation" {
    lsts_hover \
        "linux/arch/arm64/boot/dts/qcom/sm8550.dtsi:481:3" \
        "fixtures/hover_ranges.rpc.json"
}

@test "hover over dma-ranges returns documentation" {
    lsts_hover \
        "linux/arch/arm64/boot/dts/qcom/sm8550.dtsi:821:3" \
        "fixtures/hover_dma-ranges.rpc.json"
}

@test "hover over dma-coherent returns documentation" {
    lsts_hover \
        "linux/arch/arm64/boot/dts/qcom/sm8550.dtsi:870:4" \
        "fixtures/hover_dma-coherent.rpc.json"
}

@test "hover over #address-cells returns documentation" {
    lsts_hover \
        "linux/arch/arm64/boot/dts/qcom/sm8550.dtsi:32:2" \
        "fixtures/hover_address-cells.rpc.json"
}

@test "hover over #size-cells returns documentation" {
    lsts_hover \
        "linux/arch/arm64/boot/dts/qcom/sm8550.dtsi:33:2" \
        "fixtures/hover_size-cells.rpc.json"
}

# ---------------------------------------------------------------------------
# Interrupt keywords
# Real Linux source: arch/arm64/boot/dts/qcom/sm8550.dtsi
#   wakeup-source: arch/arm64/boot/dts/freescale/imx8mn-var-som.dtsi
# ---------------------------------------------------------------------------

@test "hover over interrupts returns documentation" {
    lsts_hover \
        "linux/arch/arm64/boot/dts/qcom/sm8550.dtsi:402:3" \
        "fixtures/hover_interrupts.rpc.json"
}

@test "hover over interrupts-extended returns documentation" {
    lsts_hover \
        "linux/arch/arm64/boot/dts/qcom/sm8550.dtsi:738:3" \
        "fixtures/hover_interrupts-extended.rpc.json"
}

@test "hover over interrupt-parent returns documentation" {
    lsts_hover \
        "linux/arch/arm64/boot/dts/qcom/sm8550.dtsi:30:2" \
        "fixtures/hover_interrupt-parent.rpc.json"
}

@test "hover over #interrupt-cells returns documentation" {
    lsts_hover \
        "linux/arch/arm64/boot/dts/qcom/sm8550.dtsi:755:4" \
        "fixtures/hover_interrupt-cells.rpc.json"
}

@test "hover over interrupt-controller returns documentation" {
    lsts_hover \
        "linux/arch/arm64/boot/dts/qcom/sm8550.dtsi:754:4" \
        "fixtures/hover_interrupt-controller.rpc.json"
}

@test "hover over wakeup-source returns documentation" {
    lsts_hover \
        "linux/arch/arm64/boot/dts/freescale/imx8mn-var-som.dtsi:92:3" \
        "fixtures/hover_wakeup-source.rpc.json"
}

# ---------------------------------------------------------------------------
# Clock keywords
# Real Linux source: arch/arm64/boot/dts/qcom/sm8550.dtsi
#   bus-frequency: arch/arm64/boot/dts/freescale/fsl-ls1043a.dtsi
#   timebase-frequency: arch/powerpc/boot/dts/stxssa8555.dts
# ---------------------------------------------------------------------------

@test "hover over clocks returns documentation" {
    lsts_hover \
        "linux/arch/arm64/boot/dts/qcom/sm8550.dtsi:51:4" \
        "fixtures/hover_clocks.rpc.json"
}

@test "hover over clock-names returns documentation" {
    lsts_hover \
        "linux/arch/arm64/boot/dts/qcom/sm8550.dtsi:878:4" \
        "fixtures/hover_clock-names.rpc.json"
}

@test "hover over #clock-cells returns documentation" {
    lsts_hover \
        "linux/arch/arm64/boot/dts/qcom/sm8550.dtsi:40:4" \
        "fixtures/hover_clock-cells.rpc.json"
}

@test "hover over clock-frequency returns documentation" {
    lsts_hover \
        "linux/arch/arm64/boot/dts/qcom/sm8550.dtsi:3398:5" \
        "fixtures/hover_clock-frequency.rpc.json"
}

@test "hover over bus-frequency returns documentation" {
    lsts_hover \
        "linux/arch/arm64/boot/dts/freescale/fsl-ls1043a.dtsi:671:4" \
        "fixtures/hover_bus-frequency.rpc.json"
}

@test "hover over timebase-frequency returns documentation" {
    lsts_hover \
        "linux/arch/powerpc/boot/dts/stxssa8555.dts:39:4" \
        "fixtures/hover_timebase-frequency.rpc.json"
}

# ---------------------------------------------------------------------------
# Reset keywords
# Real Linux source: arch/arm64/boot/dts/qcom/sm8550.dtsi
# ---------------------------------------------------------------------------

@test "hover over resets returns documentation" {
    lsts_hover \
        "linux/arch/arm64/boot/dts/qcom/sm8550.dtsi:2031:4" \
        "fixtures/hover_resets.rpc.json"
}

@test "hover over reset-names returns documentation" {
    lsts_hover \
        "linux/arch/arm64/boot/dts/qcom/sm8550.dtsi:2032:4" \
        "fixtures/hover_reset-names.rpc.json"
}

@test "hover over #reset-cells returns documentation" {
    lsts_hover \
        "linux/arch/arm64/boot/dts/qcom/sm8550.dtsi:830:4" \
        "fixtures/hover_reset-cells.rpc.json"
}

# ---------------------------------------------------------------------------
# GPIO keywords
# Real Linux source: arch/arm64/boot/dts/qcom/sm8550.dtsi
#   gpios: arch/arm64/boot/dts/freescale/imx91-phycore-som.dtsi
# ---------------------------------------------------------------------------

@test "hover over gpios returns documentation" {
    lsts_hover \
        "linux/arch/arm64/boot/dts/freescale/imx91-phycore-som.dtsi:44:4" \
        "fixtures/hover_gpios.rpc.json"
}

@test "hover over gpio-controller returns documentation" {
    lsts_hover \
        "linux/arch/arm64/boot/dts/qcom/sm8550.dtsi:3095:4" \
        "fixtures/hover_gpio-controller.rpc.json"
}

@test "hover over #gpio-cells returns documentation" {
    lsts_hover \
        "linux/arch/arm64/boot/dts/qcom/sm8550.dtsi:3096:4" \
        "fixtures/hover_gpio-cells.rpc.json"
}

@test "hover over gpio-ranges returns documentation" {
    lsts_hover \
        "linux/arch/arm64/boot/dts/qcom/sm8550.dtsi:3097:4" \
        "fixtures/hover_gpio-ranges.rpc.json"
}

# ---------------------------------------------------------------------------
# Pinctrl keywords
# Real Linux source: arch/arm64/boot/dts/qcom/sm8550.dtsi
# ---------------------------------------------------------------------------

@test "hover over pinctrl-names returns documentation" {
    lsts_hover \
        "linux/arch/arm64/boot/dts/qcom/sm8550.dtsi:892:5" \
        "fixtures/hover_pinctrl-names.rpc.json"
}

@test "hover over pinctrl-0 returns documentation" {
    lsts_hover \
        "linux/arch/arm64/boot/dts/qcom/sm8550.dtsi:893:5" \
        "fixtures/hover_pinctrl-0.rpc.json"
}

@test "hover over pinctrl-1 (pattern match) returns documentation" {
    lsts_hover \
        "linux/arch/arm64/boot/dts/qcom/sm8550.dtsi:3390:4" \
        "fixtures/hover_pinctrl-1.rpc.json"
}

# ---------------------------------------------------------------------------
# DMA keywords
# Real Linux source: arch/arm64/boot/dts/qcom/sm8550.dtsi
# ---------------------------------------------------------------------------

@test "hover over dmas returns documentation" {
    lsts_hover \
        "linux/arch/arm64/boot/dts/qcom/sm8550.dtsi:904:5" \
        "fixtures/hover_dmas.rpc.json"
}

@test "hover over dma-names returns documentation" {
    lsts_hover \
        "linux/arch/arm64/boot/dts/qcom/sm8550.dtsi:906:5" \
        "fixtures/hover_dma-names.rpc.json"
}

@test "hover over #dma-cells returns documentation" {
    lsts_hover \
        "linux/arch/arm64/boot/dts/qcom/sm8550.dtsi:853:4" \
        "fixtures/hover_dma-cells.rpc.json"
}

# ---------------------------------------------------------------------------
# Power / IOMMU keywords
# Real Linux source: arch/arm64/boot/dts/qcom/sm8550.dtsi
#   msi-parent: arch/arm64/boot/dts/freescale/fsl-ls1043a.dtsi
# ---------------------------------------------------------------------------

@test "hover over power-domains returns documentation" {
    lsts_hover \
        "linux/arch/arm64/boot/dts/qcom/sm8550.dtsi:76:4" \
        "fixtures/hover_power-domains.rpc.json"
}

@test "hover over iommus returns documentation" {
    lsts_hover \
        "linux/arch/arm64/boot/dts/qcom/sm8550.dtsi:869:4" \
        "fixtures/hover_iommus.rpc.json"
}

@test "hover over msi-parent returns documentation" {
    lsts_hover \
        "linux/arch/arm64/boot/dts/freescale/fsl-ls1043a.dtsi:922:4" \
        "fixtures/hover_msi-parent.rpc.json"
}

@test "hover over #msi-cells returns documentation" {
    lsts_hover \
        "linux/arch/arm64/boot/dts/qcom/sm8550.dtsi:5324:5" \
        "fixtures/hover_msi-cells.rpc.json"
}

# ---------------------------------------------------------------------------
# Well-known node keywords
# Real Linux source: arch/arm64/boot/dts/qcom/sm8550.dtsi
#   aliases: arch/arm64/boot/dts/cavium/thunder-88xx.dts
#   reserved-memory: arch/xtensa/boot/dts/kc705.dts
# ---------------------------------------------------------------------------

@test "hover over aliases node returns documentation" {
    lsts_hover \
        "linux/arch/arm64/boot/dts/cavium/thunder-88xx.dts:58:2" \
        "fixtures/hover_aliases.rpc.json"
}

@test "hover over chosen node returns documentation" {
    lsts_hover \
        "linux/arch/arm64/boot/dts/qcom/sm8550.dtsi:35:2" \
        "fixtures/hover_chosen.rpc.json"
}

@test "hover over memory node returns documentation" {
    lsts_hover \
        "linux/arch/xtensa/boot/dts/lx60.dts:8:2" \
        "fixtures/hover_memory.rpc.json"
}

@test "hover over reserved-memory node returns documentation" {
    lsts_hover \
        "linux/arch/xtensa/boot/dts/kc705.dts:16:2" \
        "fixtures/hover_reserved-memory.rpc.json"
}

@test "hover over cpus node returns documentation" {
    lsts_hover \
        "linux/arch/arm64/boot/dts/qcom/sm8550.dtsi:65:2" \
        "fixtures/hover_cpus.rpc.json"
}

# ---------------------------------------------------------------------------
# Chosen sub-properties
# Real Linux source:
#   stdout-path: arch/arm64/boot/dts/freescale/imx8mp-venice-gw74xx.dts
#   bootargs: arch/xtensa/boot/dts/csp.dts
#   linux,initrd-start / linux,initrd-end: arch/arm64/boot/dts/altera/socfpga_stratix10_swvp.dts
#   kaslr-seed: fixtures/hover_kaslr.dts (not present in Linux kernel DTS source)
# ---------------------------------------------------------------------------

@test "hover over stdout-path returns documentation" {
    lsts_hover \
        "linux/arch/arm64/boot/dts/freescale/imx8mp-venice-gw74xx.dts:33:3" \
        "fixtures/hover_stdout-path.rpc.json"
}

@test "hover over bootargs returns documentation" {
    lsts_hover \
        "linux/arch/xtensa/boot/dts/csp.dts:11:3" \
        "fixtures/hover_bootargs.rpc.json"
}

@test "hover over initrd-start returns documentation" {
    lsts_hover \
        "linux/arch/arm64/boot/dts/altera/socfpga_stratix10_swvp.dts:28:3" \
        "fixtures/hover_initrd-start.rpc.json"
}

@test "hover over initrd-end returns documentation" {
    lsts_hover \
        "linux/arch/arm64/boot/dts/altera/socfpga_stratix10_swvp.dts:29:3" \
        "fixtures/hover_initrd-end.rpc.json"
}

@test "hover over kaslr-seed returns documentation" {
    lsts_hover \
        "fixtures/hover_kaslr.dts:4:3" \
        "fixtures/hover_kaslr-seed.rpc.json"
}

@test "hover over binding-only property returns binding description" {
    lsts_hover \
        "fixtures/hover_binding_interrupt_names.dts:9:3" \
        "fixtures/hover_binding_interrupt_names.rpc.json"
}

# ---------------------------------------------------------------------------
# Hover: pinctrl subnode properties (ancestor compatible walk + global fallback)
# Fixture: fixtures/hover_pinctrl_bias_pull_up.dts
#   bias-pull-up is in Documentation/devicetree/bindings/pinctrl/pincfg-node.yaml
#   The subnode has no compatible; ancestor walk finds sophgo,cv1800b-pinctrl
# ---------------------------------------------------------------------------

@test "hover over bias-pull-up returns binding doc" {
    lsts_hover \
        "fixtures/hover_pinctrl_bias_pull_up.dts:12:5" \
        "fixtures/hover_pinctrl_bias_pull_up.rpc.json"
}

@test "hover over groups returns binding doc" {
    lsts_hover \
        "fixtures/hover_pinctrl_groups.dts:11:5" \
        "fixtures/hover_pinctrl_groups.rpc.json"
}

@test "hover over function returns binding doc" {
    lsts_hover \
        "fixtures/hover_pinctrl_groups.dts:10:5" \
        "fixtures/hover_pinctrl_function.rpc.json"
}

@test "hover over unknown token returns null" {
    lsts_hover \
        "linux/arch/arm64/boot/dts/qcom/sm8550.dtsi:1:1" \
        "fixtures/hover_null.rpc.json"
}

@test "fails to start when jq is not installed" {
    local bash_dir server_src
    bash_dir="$(dirname "$(command -v bash)")"
    server_src="$(dirname "$BATS_TEST_FILENAME")/../anakins-dtls"
    run env -i PATH="$bash_dir" bash "$server_src"
    [[ "$status" -ne 0 ]]
}

@test "prints error to stderr when jq is not installed" {
    local bash_dir server_src
    bash_dir="$(dirname "$(command -v bash)")"
    server_src="$(dirname "$BATS_TEST_FILENAME")/../anakins-dtls"
    run env -i PATH="$bash_dir" bash "$server_src"
    [[ "$output" == *"jq"* ]]
}

# ---------------------------------------------------------------------------
# go-to-definition: capabilities
# ---------------------------------------------------------------------------

@test "initialize advertises definitionProvider" {
    lsts_initialize
    echo "$LSTS_RESPONSE" | jq -e '.result.capabilities.definitionProvider == true'
}

# ---------------------------------------------------------------------------
# go-to-definition: compatible value → binding YAML
# Real source: arch/arm64/boot/dts/qcom/sdm845.dtsi line 1319 col 18
#   compatible = "qcom,geni-uart";  cursor on "qcom,geni-uart"
# ---------------------------------------------------------------------------

@test "definition on compatible value navigates to binding YAML" {
    lsts_definition \
        "linux/arch/arm64/boot/dts/qcom/sdm845.dtsi:1319:18" \
        "fixtures/definition_compatible_value.rpc.json"
}

# ---------------------------------------------------------------------------
# go-to-definition: property name → binding property location
# Real source: arch/arm64/boot/dts/qcom/sdm845.dtsi line 1322 col 5
#   clocks = <&gcc ...>;  node has compatible = "qcom,geni-uart"
# ---------------------------------------------------------------------------

@test "definition on property navigates to binding property location" {
    lsts_definition \
        "linux/arch/arm64/boot/dts/qcom/sdm845.dtsi:1322:5" \
        "fixtures/definition_property_binding.rpc.json"
}

# ---------------------------------------------------------------------------
# go-to-definition: standard property name → spec RST
# Real source: arch/arm64/boot/dts/qcom/sm8550.dtsi line 39 col 5
#   compatible = ...  cursor on "compatible" keyword itself
# ---------------------------------------------------------------------------

@test "definition on standard property navigates to spec" {
    lsts_definition \
        "linux/arch/arm64/boot/dts/qcom/sm8550.dtsi:39:5" \
        "fixtures/definition_spec_property.rpc.json"
}

# ---------------------------------------------------------------------------
# go-to-definition: unknown token → null
# ---------------------------------------------------------------------------

@test "definition returns null for unknown" {
    lsts_definition \
        "linux/arch/arm64/boot/dts/qcom/sm8550.dtsi:1:1" \
        "fixtures/definition_null.rpc.json"
}

# ---------------------------------------------------------------------------
# go-to-definition: phandle reference → label definition
# Source: arch/xtensa/boot/dts/xtfpga.dtsi line 6 col 22
#   interrupt-parent = <&pic>;  cursor on &pic
#   pic: is defined at line 27 (0-indexed: 26)
# ---------------------------------------------------------------------------

@test "definition on phandle reference navigates to label" {
    lsts_definition \
        "linux/arch/xtensa/boot/dts/xtfpga.dtsi:6:23" \
        "fixtures/definition_phandle_ref.rpc.json"
}

# ---------------------------------------------------------------------------
# Hover: CPP macros
# Real source: arch/arm64/boot/dts/qcom/sm8550.dtsi line 845 col 18
#   interrupts = <GIC_SPI 229 ...>  cursor on GIC_SPI
# ---------------------------------------------------------------------------

@test "hover over GIC_SPI returns macro definition" {
    lsts_hover \
        "linux/arch/arm64/boot/dts/qcom/sm8550.dtsi:845:18" \
        "fixtures/hover_macro_GIC_SPI.rpc.json"
}

# ---------------------------------------------------------------------------
# Hover: CPP macros (GPIO)
# Real source: arch/arm64/boot/dts/qcom/sc7180-idp.dts line 319 col 35
#   reset-gpios = <&pm6150l_gpios 3 GPIO_ACTIVE_HIGH>;  cursor on GPIO_ACTIVE_HIGH
# ---------------------------------------------------------------------------

@test "hover over GPIO_ACTIVE_HIGH returns macro definition" {
    lsts_hover \
        "linux/arch/arm64/boot/dts/qcom/sc7180-idp.dts:319:35" \
        "fixtures/hover_macro_GPIO_ACTIVE_HIGH.rpc.json"
}

# ---------------------------------------------------------------------------
# go-to-definition: CPP macro → header file
# Real source: arch/arm64/boot/dts/qcom/sm8550.dtsi line 845 col 18
#   cursor on GIC_SPI → navigate to arm-gic.h #define line
# ---------------------------------------------------------------------------

@test "definition on GIC_SPI navigates to header file" {
    lsts_definition \
        "linux/arch/arm64/boot/dts/qcom/sm8550.dtsi:845:18" \
        "fixtures/definition_macro_GIC_SPI.rpc.json"
}

# ---------------------------------------------------------------------------
# Hover: compatible string value → binding description
# Real source: tests/linux/arch/arm64/boot/dts/freescale/imx91-phycore-som.dtsi
#   line 50: compatible = "regulator-fixed";  cursor on "regulator-fixed"
# ---------------------------------------------------------------------------

@test "hover over compatible string returns binding description" {
    lsts_hover \
        "linux/arch/arm64/boot/dts/freescale/imx91-phycore-som.dtsi:50:20" \
        "fixtures/hover_compatible_value_regulator_fixed.rpc.json"
}

# ---------------------------------------------------------------------------
# Hover: regulator-min-microvolt → found via $ref in regulator.yaml
# Real source: tests/linux/arch/arm64/boot/dts/freescale/imx91-phycore-som.dtsi
#   line 53: regulator-min-microvolt = <1800000>;
# ---------------------------------------------------------------------------

@test "hover over regulator-min-microvolt returns binding doc via \$ref" {
    lsts_hover \
        "linux/arch/arm64/boot/dts/freescale/imx91-phycore-som.dtsi:53:5" \
        "fixtures/hover_regulator_min_microvolt.rpc.json"
}

# ---------------------------------------------------------------------------
# go-to-definition: regulator-min-microvolt → navigates via $ref to regulator.yaml
# Real source: tests/linux/arch/arm64/boot/dts/freescale/imx91-phycore-som.dtsi
#   line 53: regulator-min-microvolt = <1800000>;
# ---------------------------------------------------------------------------

@test "definition on regulator-min-microvolt navigates via \$ref" {
    lsts_definition \
        "linux/arch/arm64/boot/dts/freescale/imx91-phycore-som.dtsi:53:5" \
        "fixtures/definition_regulator_min_microvolt.rpc.json"
}

# ---------------------------------------------------------------------------
# Definition: cross-file phandle
# Real source: arch/arm64/boot/dts/amlogic/meson-gxl-s905x-khadas-vim.dts line 41
#   gpios = <&gpio_ao GPIOAO_2 GPIO_ACTIVE_LOW>;  cursor on &gpio_ao
# gpio_ao: is defined in meson-gxl.dtsi line 152 (3 includes deep)
# ---------------------------------------------------------------------------

@test "definition on cross-file phandle navigates to included file" {
    lsts_definition \
        "linux/arch/arm64/boot/dts/amlogic/meson-gxl-s905x-khadas-vim.dts:41:13" \
        "fixtures/definition_cross_file_phandle.rpc.json"
}

# ---------------------------------------------------------------------------
# Definition: property name global binding search
# Real source: arch/arm64/boot/dts/freescale/imx91-phycore-som.dtsi line 111
#   buck1: BUCK1 { regulator-name = ... }  cursor on regulator-name
# No compatible on BUCK1 node; global binding search finds regulator.yaml
# ---------------------------------------------------------------------------

@test "definition on property name navigates to binding YAML" {
    lsts_definition \
        "linux/arch/arm64/boot/dts/freescale/imx91-phycore-som.dtsi:111:5" \
        "fixtures/definition_property_name_global.rpc.json"
}

# ---------------------------------------------------------------------------
# Diagnostics: missing semicolon
# Fixture: fixtures/diag_missing_semicolon.dts
#   line 8: compatible = "foo,bar"  -- missing semicolon
# ---------------------------------------------------------------------------

@test "diagnostics reports missing semicolon" {
    lsts_diagnostics "fixtures/diag_missing_semicolon.dts" \
        "fixtures/diag_missing_semicolon.rpc.json"
    echo "$LSTS_RESPONSE" | jq -e '
        .params.diagnostics |
        any(.severity == 1 and (.message | test("semicolon"; "i")))
    '
}

# ---------------------------------------------------------------------------
# Diagnostics: unbalanced braces
# Fixture: fixtures/diag_unbalanced_brace.dts
#   missing closing brace at EOF
# ---------------------------------------------------------------------------

@test "diagnostics reports unclosed brace" {
    lsts_diagnostics "fixtures/diag_unbalanced_brace.dts" \
        "fixtures/diag_unbalanced_brace.rpc.json"
    echo "$LSTS_RESPONSE" | jq -e '
        .params.diagnostics |
        any(.severity == 1 and (.message | test("brace"; "i")))
    '
}

# ---------------------------------------------------------------------------
# Diagnostics: missing required property
# Fixture: fixtures/diag_missing_required.dts
#   node with compatible = "qcom,geni-uart" missing 'clocks'
# ---------------------------------------------------------------------------

@test "diagnostics reports missing required property" {
    lsts_diagnostics "fixtures/diag_missing_required.dts" \
        "fixtures/diag_missing_required.rpc.json"
    echo "$LSTS_RESPONSE" | jq -e '
        .params.diagnostics |
        any(.severity == 2 and (.message | test("clocks"; "i")))
    '
}

# ---------------------------------------------------------------------------
# Diagnostics: undocumented property
# Fixture: fixtures/diag_undocumented_prop.dts
#   node with compatible = "qcom,geni-uart" with a fake property
# ---------------------------------------------------------------------------

@test "diagnostics reports undocumented property" {
    lsts_diagnostics "fixtures/diag_undocumented_prop.dts" \
        "fixtures/diag_undocumented_prop.rpc.json"
    echo "$LSTS_RESPONSE" | jq -e '
        .params.diagnostics |
        any(.severity == 2 and (.message | test("my-fake-property"; "i")))
    '
}

# ---------------------------------------------------------------------------
# Diagnostics: valid document reports no errors
# Source: tests/linux/arch/xtensa/boot/dts/csp.dts (small, clean DTS)
# ---------------------------------------------------------------------------

@test "diagnostics on valid document reports no errors" {
    lsts_initialize
    lsts_open "fixtures/diag_valid.dts"

    local uri="file://$LSTS_ROOT/fixtures/diag_valid.dts"
    local _deadline=$(( SECONDS + ${LSTS_TIMEOUT:-10} ))
    while (( SECONDS < _deadline )); do
        lsts_recv || return 1
        _lsts_reply_to_request && continue
        printf '%s' "$LSTS_RESPONSE" | jq -e \
            --arg m "textDocument/publishDiagnostics" --arg uri "$uri" \
            '.method == $m and .params.uri == $uri' >/dev/null 2>&1 && break
    done

    printf '%s' "$LSTS_RESPONSE" | jq -e '.params.diagnostics | length == 0'
}

# ---------------------------------------------------------------------------
# Diagnostics: duplicate property in same node
# ---------------------------------------------------------------------------

@test "diagnostics reports duplicate property in node" {
    lsts_diagnostics "fixtures/diag_duplicate_prop.dts" \
        "fixtures/diag_duplicate_prop.rpc.json"
    echo "$LSTS_RESPONSE" | jq -e '
        .params.diagnostics |
        any(.severity == 2 and (.message | test("Duplicate property"; "i")))
    '
}

# ---------------------------------------------------------------------------
# Diagnostics: invalid status value
# ---------------------------------------------------------------------------

@test "diagnostics reports invalid status value" {
    lsts_diagnostics "fixtures/diag_invalid_status.dts" \
        "fixtures/diag_invalid_status.rpc.json"
    echo "$LSTS_RESPONSE" | jq -e '
        .params.diagnostics |
        any(.severity == 1 and (.message | test("Invalid status value"; "i")))
    '
}

# ---------------------------------------------------------------------------
# Diagnostics: reg cell count mismatch
# ---------------------------------------------------------------------------

@test "diagnostics reports reg cell count mismatch" {
    lsts_diagnostics "fixtures/diag_reg_cells.dts" \
        "fixtures/diag_reg_cells.rpc.json"
    echo "$LSTS_RESPONSE" | jq -e '
        .params.diagnostics |
        any(.severity == 2 and (.message | test("reg cell count"; "i")))
    '
}

# ---------------------------------------------------------------------------
# Diagnostics: deprecated linux,phandle
# ---------------------------------------------------------------------------

@test "diagnostics reports deprecated linux,phandle" {
    lsts_diagnostics "fixtures/diag_linux_phandle.dts" \
        "fixtures/diag_linux_phandle.rpc.json"
    echo "$LSTS_RESPONSE" | jq -e '
        .params.diagnostics |
        any(.severity == 4 and (.message | test("linux,phandle is deprecated"; "i")))
    '
}

# ---------------------------------------------------------------------------
# Diagnostics: node unit-address mismatch
# ---------------------------------------------------------------------------

@test "diagnostics reports node unit-address mismatch" {
    lsts_diagnostics "fixtures/diag_unit_addr.dts" \
        "fixtures/diag_unit_addr.rpc.json"
    echo "$LSTS_RESPONSE" | jq -e '
        .params.diagnostics |
        any(.severity == 2 and (.message | test("unit-address"; "i")))
    '
}

# ---------------------------------------------------------------------------
# Diagnostics: duplicate node label
# ---------------------------------------------------------------------------

@test "diagnostics reports duplicate node label" {
    lsts_diagnostics "fixtures/diag_duplicate_label.dts" \
        "fixtures/diag_duplicate_label.rpc.json"
    echo "$LSTS_RESPONSE" | jq -e '
        .params.diagnostics |
        any(.severity == 2 and (.message | test("Duplicate node label"; "i")))
    '
}

# ---------------------------------------------------------------------------
# Diagnostics: compatible format
# ---------------------------------------------------------------------------

@test "diagnostics reports invalid compatible format" {
    lsts_diagnostics "fixtures/diag_compat_format.dts" \
        "fixtures/diag_compat_format.rpc.json"
    echo "$LSTS_RESPONSE" | jq -e '
        .params.diagnostics |
        any(.severity == 2 and (.message | test("compatible string"; "i")))
    '
}

# ---------------------------------------------------------------------------
# Hover: phandle reference → shows referenced node's compatible binding docs
# Source: arch/xtensa/boot/dts/xtfpga.dtsi line 6 col 23 (1-based)
#   interrupt-parent = <&pic>;  cursor on &pic
#   pic: has compatible = "cdns,xtensa-pic"
# ---------------------------------------------------------------------------

@test "hover over phandle reference shows referenced node compatible docs" {
    lsts_hover \
        "linux/arch/xtensa/boot/dts/xtfpga.dtsi:6:23" \
        "fixtures/hover_phandle_ref.rpc.json"
    echo "$LSTS_RESPONSE" | jq -e '
        .result.contents.value | test("xtensa"; "i")
    '
}

# ---------------------------------------------------------------------------
# References
# ---------------------------------------------------------------------------

@test "references for node label finds phandle usages" {
    # pic: label defined at line 27 col 2 (1-based) in xtfpga.dtsi
    # &pic is used in the same file at line 6
    lsts_references \
        "linux/arch/xtensa/boot/dts/xtfpga.dtsi:27:2"
    echo "$LSTS_RESPONSE" | jq -e '
        .result | type == "array" and length > 0
    '
    echo "$LSTS_RESPONSE" | jq -e '
        .result | map(.uri) | any(test("xtfpga|csp|virt|openrisc"; "i"))
    '
}

@test "references for compatible string finds usages" {
    # cursor on "cdns,xtensa-pic" at line 28 col 17 (1-based) in xtfpga.dtsi
    lsts_references \
        "linux/arch/xtensa/boot/dts/xtfpga.dtsi:28:17"
    echo "$LSTS_RESPONSE" | jq -e '
        .result | type == "array" and length > 0
    '
    echo "$LSTS_RESPONSE" | jq -e '
        .result | map(.uri) | any(test("\\.dts|\\.dtsi"; "i"))
    '
}

# ---------------------------------------------------------------------------
# Completion
# ---------------------------------------------------------------------------

@test "completion in a node offers standard DT properties" {
    lsts_completion \
        "fixtures/completion_uart.dts:7:3"
    echo "$LSTS_RESPONSE" | jq -e '
        .result.items | map(.label) | (contains(["compatible"]) and contains(["reg"]))
    '
}

@test "completion in a node with compatible offers binding properties" {
    lsts_completion \
        "fixtures/completion_uart.dts:7:3"
    echo "$LSTS_RESPONSE" | jq -e '
        .result.items | map(.label) | (contains(["clocks"]) and contains(["clock-names"]))
    '
}
