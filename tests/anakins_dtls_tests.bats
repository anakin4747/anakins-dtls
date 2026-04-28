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
    lsts_initialize_capability '.result.capabilities.hoverProvider == true'
}

@test "initialize advertises openClose textDocumentSync" {
    lsts_initialize_capability '.result.capabilities.textDocumentSync.openClose == true'
}

@test "initialize advertises full textDocumentSync change" {
    lsts_initialize_capability '.result.capabilities.textDocumentSync.change == 1'
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
        "linux/arch/arm64/boot/dts/qcom/sm8550.dtsi:394:2" \
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
