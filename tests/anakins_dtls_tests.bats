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
# ---------------------------------------------------------------------------

@test "hover over compatible returns documentation" {
    lsts_hover \
        "fixtures/hover_core.dts:2:2" \
        "fixtures/hover_compatible.rpc.json"
}

@test "hover over model returns documentation" {
    lsts_hover \
        "fixtures/hover_core.dts:3:2" \
        "fixtures/hover_model.rpc.json"
}

@test "hover over device_type returns documentation" {
    lsts_hover \
        "fixtures/hover_core.dts:4:2" \
        "fixtures/hover_device_type.rpc.json"
}

@test "hover over status returns documentation" {
    lsts_hover \
        "fixtures/hover_core.dts:5:2" \
        "fixtures/hover_status.rpc.json"
}

@test "hover over phandle returns documentation" {
    lsts_hover \
        "fixtures/hover_core.dts:6:2" \
        "fixtures/hover_phandle.rpc.json"
}

@test "hover over linux,phandle returns documentation" {
    lsts_hover \
        "fixtures/hover_core.dts:7:2" \
        "fixtures/hover_linux_phandle.rpc.json"
}

@test "hover over label returns documentation" {
    lsts_hover \
        "fixtures/hover_core.dts:8:2" \
        "fixtures/hover_label.rpc.json"
}

# ---------------------------------------------------------------------------
# Addressing keywords
# ---------------------------------------------------------------------------

@test "hover over reg returns documentation" {
    lsts_hover \
        "fixtures/hover_addressing.dts:2:2" \
        "fixtures/hover_reg.rpc.json"
}

@test "hover over reg-names returns documentation" {
    lsts_hover \
        "fixtures/hover_addressing.dts:3:2" \
        "fixtures/hover_reg-names.rpc.json"
}

@test "hover over ranges returns documentation" {
    lsts_hover \
        "fixtures/hover_addressing.dts:4:2" \
        "fixtures/hover_ranges.rpc.json"
}

@test "hover over dma-ranges returns documentation" {
    lsts_hover \
        "fixtures/hover_addressing.dts:5:2" \
        "fixtures/hover_dma-ranges.rpc.json"
}

@test "hover over dma-coherent returns documentation" {
    lsts_hover \
        "fixtures/hover_addressing.dts:6:2" \
        "fixtures/hover_dma-coherent.rpc.json"
}

@test "hover over #address-cells returns documentation" {
    lsts_hover \
        "fixtures/hover_addressing.dts:7:2" \
        "fixtures/hover_address-cells.rpc.json"
}

@test "hover over #size-cells returns documentation" {
    lsts_hover \
        "fixtures/hover_addressing.dts:8:2" \
        "fixtures/hover_size-cells.rpc.json"
}

# ---------------------------------------------------------------------------
# Interrupt keywords
# ---------------------------------------------------------------------------

@test "hover over interrupts returns documentation" {
    lsts_hover \
        "fixtures/hover_interrupts.dts:2:2" \
        "fixtures/hover_interrupts.rpc.json"
}

@test "hover over interrupts-extended returns documentation" {
    lsts_hover \
        "fixtures/hover_interrupts.dts:3:2" \
        "fixtures/hover_interrupts-extended.rpc.json"
}

@test "hover over interrupt-parent returns documentation" {
    lsts_hover \
        "fixtures/hover_interrupts.dts:4:2" \
        "fixtures/hover_interrupt-parent.rpc.json"
}

@test "hover over #interrupt-cells returns documentation" {
    lsts_hover \
        "fixtures/hover_interrupts.dts:5:2" \
        "fixtures/hover_interrupt-cells.rpc.json"
}

@test "hover over interrupt-controller returns documentation" {
    lsts_hover \
        "fixtures/hover_interrupts.dts:6:2" \
        "fixtures/hover_interrupt-controller.rpc.json"
}

@test "hover over wakeup-source returns documentation" {
    lsts_hover \
        "fixtures/hover_interrupts.dts:7:2" \
        "fixtures/hover_wakeup-source.rpc.json"
}

# ---------------------------------------------------------------------------
# Clock keywords
# ---------------------------------------------------------------------------

@test "hover over clocks returns documentation" {
    lsts_hover \
        "fixtures/hover_clocks.dts:2:2" \
        "fixtures/hover_clocks.rpc.json"
}

@test "hover over clock-names returns documentation" {
    lsts_hover \
        "fixtures/hover_clocks.dts:3:2" \
        "fixtures/hover_clock-names.rpc.json"
}

@test "hover over #clock-cells returns documentation" {
    lsts_hover \
        "fixtures/hover_clocks.dts:4:2" \
        "fixtures/hover_clock-cells.rpc.json"
}

@test "hover over clock-frequency returns documentation" {
    lsts_hover \
        "fixtures/hover_clocks.dts:5:2" \
        "fixtures/hover_clock-frequency.rpc.json"
}

@test "hover over bus-frequency returns documentation" {
    lsts_hover \
        "fixtures/hover_clocks.dts:6:2" \
        "fixtures/hover_bus-frequency.rpc.json"
}

@test "hover over timebase-frequency returns documentation" {
    lsts_hover \
        "fixtures/hover_clocks.dts:7:2" \
        "fixtures/hover_timebase-frequency.rpc.json"
}

# ---------------------------------------------------------------------------
# Reset keywords
# ---------------------------------------------------------------------------

@test "hover over resets returns documentation" {
    lsts_hover \
        "fixtures/hover_resets.dts:2:2" \
        "fixtures/hover_resets.rpc.json"
}

@test "hover over reset-names returns documentation" {
    lsts_hover \
        "fixtures/hover_resets.dts:3:2" \
        "fixtures/hover_reset-names.rpc.json"
}

@test "hover over #reset-cells returns documentation" {
    lsts_hover \
        "fixtures/hover_resets.dts:4:2" \
        "fixtures/hover_reset-cells.rpc.json"
}

# ---------------------------------------------------------------------------
# GPIO keywords
# ---------------------------------------------------------------------------

@test "hover over gpios returns documentation" {
    lsts_hover \
        "fixtures/hover_gpios.dts:2:2" \
        "fixtures/hover_gpios.rpc.json"
}

@test "hover over gpio-controller returns documentation" {
    lsts_hover \
        "fixtures/hover_gpios.dts:3:2" \
        "fixtures/hover_gpio-controller.rpc.json"
}

@test "hover over #gpio-cells returns documentation" {
    lsts_hover \
        "fixtures/hover_gpios.dts:4:2" \
        "fixtures/hover_gpio-cells.rpc.json"
}

@test "hover over gpio-ranges returns documentation" {
    lsts_hover \
        "fixtures/hover_gpios.dts:5:2" \
        "fixtures/hover_gpio-ranges.rpc.json"
}

# ---------------------------------------------------------------------------
# Pinctrl keywords
# ---------------------------------------------------------------------------

@test "hover over pinctrl-names returns documentation" {
    lsts_hover \
        "fixtures/hover_pinctrl.dts:2:2" \
        "fixtures/hover_pinctrl-names.rpc.json"
}

@test "hover over pinctrl-0 returns documentation" {
    lsts_hover \
        "fixtures/hover_pinctrl.dts:3:2" \
        "fixtures/hover_pinctrl-0.rpc.json"
}

@test "hover over pinctrl-1 (pattern match) returns documentation" {
    lsts_hover \
        "fixtures/hover_pinctrl.dts:4:2" \
        "fixtures/hover_pinctrl-1.rpc.json"
}

# ---------------------------------------------------------------------------
# DMA keywords
# ---------------------------------------------------------------------------

@test "hover over dmas returns documentation" {
    lsts_hover \
        "fixtures/hover_dmas.dts:2:2" \
        "fixtures/hover_dmas.rpc.json"
}

@test "hover over dma-names returns documentation" {
    lsts_hover \
        "fixtures/hover_dmas.dts:3:2" \
        "fixtures/hover_dma-names.rpc.json"
}

@test "hover over #dma-cells returns documentation" {
    lsts_hover \
        "fixtures/hover_dmas.dts:4:2" \
        "fixtures/hover_dma-cells.rpc.json"
}

# ---------------------------------------------------------------------------
# Power / IOMMU keywords
# ---------------------------------------------------------------------------

@test "hover over power-domains returns documentation" {
    lsts_hover \
        "fixtures/hover_power.dts:2:2" \
        "fixtures/hover_power-domains.rpc.json"
}

@test "hover over iommus returns documentation" {
    lsts_hover \
        "fixtures/hover_power.dts:3:2" \
        "fixtures/hover_iommus.rpc.json"
}

@test "hover over msi-parent returns documentation" {
    lsts_hover \
        "fixtures/hover_power.dts:4:2" \
        "fixtures/hover_msi-parent.rpc.json"
}

@test "hover over #msi-cells returns documentation" {
    lsts_hover \
        "fixtures/hover_power.dts:5:2" \
        "fixtures/hover_msi-cells.rpc.json"
}

# ---------------------------------------------------------------------------
# Well-known node keywords
# ---------------------------------------------------------------------------

@test "hover over aliases node returns documentation" {
    lsts_hover \
        "fixtures/hover_nodes.dts:2:2" \
        "fixtures/hover_aliases.rpc.json"
}

@test "hover over chosen node returns documentation" {
    lsts_hover \
        "fixtures/hover_nodes.dts:3:2" \
        "fixtures/hover_chosen.rpc.json"
}

@test "hover over memory node returns documentation" {
    lsts_hover \
        "fixtures/hover_nodes.dts:4:2" \
        "fixtures/hover_memory.rpc.json"
}

@test "hover over reserved-memory node returns documentation" {
    lsts_hover \
        "fixtures/hover_nodes.dts:5:2" \
        "fixtures/hover_reserved-memory.rpc.json"
}

@test "hover over cpus node returns documentation" {
    lsts_hover \
        "fixtures/hover_nodes.dts:6:2" \
        "fixtures/hover_cpus.rpc.json"
}

# ---------------------------------------------------------------------------
# Chosen sub-properties
# ---------------------------------------------------------------------------

@test "hover over stdout-path returns documentation" {
    lsts_hover \
        "fixtures/hover_chosen.dts:3:3" \
        "fixtures/hover_stdout-path.rpc.json"
}

@test "hover over bootargs returns documentation" {
    lsts_hover \
        "fixtures/hover_chosen.dts:4:3" \
        "fixtures/hover_bootargs.rpc.json"
}

@test "hover over initrd-start returns documentation" {
    lsts_hover \
        "fixtures/hover_chosen.dts:5:3" \
        "fixtures/hover_initrd-start.rpc.json"
}

@test "hover over initrd-end returns documentation" {
    lsts_hover \
        "fixtures/hover_chosen.dts:6:3" \
        "fixtures/hover_initrd-end.rpc.json"
}

@test "hover over kaslr-seed returns documentation" {
    lsts_hover \
        "fixtures/hover_chosen.dts:7:3" \
        "fixtures/hover_kaslr-seed.rpc.json"
}

@test "hover over unknown token returns null" {
    lsts_hover \
        "fixtures/hover_core.dts:1:1" \
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
