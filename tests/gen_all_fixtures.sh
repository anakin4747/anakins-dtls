#!/usr/bin/env bash
# Batch generate all hover fixtures.
set -o errexit
set -o nounset
set -o pipefail

cd "$(dirname "$0")/.."
ROOT="$PWD"
TESTS="$ROOT/tests"
GEN="$TESTS/gen_fixture.sh"

gen() { bash "$GEN" "$@"; }

# core.dts: line 2=compatible,3=model,4=device_type,5=status,6=phandle,7=linux,phandle,8=label
gen fixtures/hover_core.dts 2:2 fixtures/hover_compatible.rpc.json
gen fixtures/hover_core.dts 3:2 fixtures/hover_model.rpc.json
gen fixtures/hover_core.dts 4:2 fixtures/hover_device_type.rpc.json
gen fixtures/hover_core.dts 5:2 fixtures/hover_status.rpc.json
gen fixtures/hover_core.dts 6:2 fixtures/hover_phandle.rpc.json
gen fixtures/hover_core.dts 7:2 fixtures/hover_linux_phandle.rpc.json
gen fixtures/hover_core.dts 8:2 fixtures/hover_label.rpc.json

# addressing.dts: 2=reg,3=reg-names,4=ranges,5=dma-ranges,6=dma-coherent,7=#address-cells,8=#size-cells
gen fixtures/hover_addressing.dts 2:2 fixtures/hover_reg.rpc.json
gen fixtures/hover_addressing.dts 3:2 fixtures/hover_reg-names.rpc.json
gen fixtures/hover_addressing.dts 4:2 fixtures/hover_ranges.rpc.json
gen fixtures/hover_addressing.dts 5:2 fixtures/hover_dma-ranges.rpc.json
gen fixtures/hover_addressing.dts 6:2 fixtures/hover_dma-coherent.rpc.json
gen fixtures/hover_addressing.dts 7:2 fixtures/hover_address-cells.rpc.json
gen fixtures/hover_addressing.dts 8:2 fixtures/hover_size-cells.rpc.json

# interrupts.dts: 2=interrupts,3=interrupts-extended,4=interrupt-parent,5=#interrupt-cells,6=interrupt-controller,7=wakeup-source
gen fixtures/hover_interrupts.dts 2:2 fixtures/hover_interrupts.rpc.json
gen fixtures/hover_interrupts.dts 3:2 fixtures/hover_interrupts-extended.rpc.json
gen fixtures/hover_interrupts.dts 4:2 fixtures/hover_interrupt-parent.rpc.json
gen fixtures/hover_interrupts.dts 5:2 fixtures/hover_interrupt-cells.rpc.json
gen fixtures/hover_interrupts.dts 6:2 fixtures/hover_interrupt-controller.rpc.json
gen fixtures/hover_interrupts.dts 7:2 fixtures/hover_wakeup-source.rpc.json

# clocks.dts: 2=clocks,3=clock-names,4=#clock-cells,5=clock-frequency,6=bus-frequency,7=timebase-frequency
gen fixtures/hover_clocks.dts 2:2 fixtures/hover_clocks.rpc.json
gen fixtures/hover_clocks.dts 3:2 fixtures/hover_clock-names.rpc.json
gen fixtures/hover_clocks.dts 4:2 fixtures/hover_clock-cells.rpc.json
gen fixtures/hover_clocks.dts 5:2 fixtures/hover_clock-frequency.rpc.json
gen fixtures/hover_clocks.dts 6:2 fixtures/hover_bus-frequency.rpc.json
gen fixtures/hover_clocks.dts 7:2 fixtures/hover_timebase-frequency.rpc.json

# resets.dts: 2=resets,3=reset-names,4=#reset-cells
gen fixtures/hover_resets.dts 2:2 fixtures/hover_resets.rpc.json
gen fixtures/hover_resets.dts 3:2 fixtures/hover_reset-names.rpc.json
gen fixtures/hover_resets.dts 4:2 fixtures/hover_reset-cells.rpc.json

# gpios.dts: 2=gpios,3=gpio-controller,4=#gpio-cells,5=gpio-ranges
gen fixtures/hover_gpios.dts 2:2 fixtures/hover_gpios.rpc.json
gen fixtures/hover_gpios.dts 3:2 fixtures/hover_gpio-controller.rpc.json
gen fixtures/hover_gpios.dts 4:2 fixtures/hover_gpio-cells.rpc.json
gen fixtures/hover_gpios.dts 5:2 fixtures/hover_gpio-ranges.rpc.json

# pinctrl.dts: 2=pinctrl-names,3=pinctrl-0,4=pinctrl-1
gen fixtures/hover_pinctrl.dts 2:2 fixtures/hover_pinctrl-names.rpc.json
gen fixtures/hover_pinctrl.dts 3:2 fixtures/hover_pinctrl-0.rpc.json
gen fixtures/hover_pinctrl.dts 4:2 fixtures/hover_pinctrl-1.rpc.json

# dmas.dts: 2=dmas,3=dma-names,4=#dma-cells
gen fixtures/hover_dmas.dts 2:2 fixtures/hover_dmas.rpc.json
gen fixtures/hover_dmas.dts 3:2 fixtures/hover_dma-names.rpc.json
gen fixtures/hover_dmas.dts 4:2 fixtures/hover_dma-cells.rpc.json

# power.dts: 2=power-domains,3=iommus,4=msi-parent,5=#msi-cells
gen fixtures/hover_power.dts 2:2 fixtures/hover_power-domains.rpc.json
gen fixtures/hover_power.dts 3:2 fixtures/hover_iommus.rpc.json
gen fixtures/hover_power.dts 4:2 fixtures/hover_msi-parent.rpc.json
gen fixtures/hover_power.dts 5:2 fixtures/hover_msi-cells.rpc.json

# nodes.dts: lines contain node names as first token
# line 2=aliases{, 3=chosen{, 4=memory@0, 5=reserved-memory{, 6=cpus
gen fixtures/hover_nodes.dts 2:2 fixtures/hover_aliases.rpc.json
gen fixtures/hover_nodes.dts 3:2 fixtures/hover_chosen.rpc.json
gen fixtures/hover_nodes.dts 4:2 fixtures/hover_memory.rpc.json
gen fixtures/hover_nodes.dts 5:2 fixtures/hover_reserved-memory.rpc.json
gen fixtures/hover_nodes.dts 6:2 fixtures/hover_cpus.rpc.json

# chosen.dts: 3=stdout-path,4=bootargs,5=initrd-start,6=initrd-end,7=kaslr-seed
gen fixtures/hover_chosen.dts 3:3 fixtures/hover_stdout-path.rpc.json
gen fixtures/hover_chosen.dts 4:3 fixtures/hover_bootargs.rpc.json
gen fixtures/hover_chosen.dts 5:3 fixtures/hover_initrd-start.rpc.json
gen fixtures/hover_chosen.dts 6:3 fixtures/hover_initrd-end.rpc.json
gen fixtures/hover_chosen.dts 7:3 fixtures/hover_kaslr-seed.rpc.json

echo "All fixtures generated."
