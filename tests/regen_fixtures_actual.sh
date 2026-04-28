#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TESTS="$ROOT/tests"
GEN="$TESTS/gen_fixture.sh"

gen() { bash "$GEN" "$@"; }

gen linux/arch/arm64/boot/dts/qcom/sm8550.dtsi       39:4  fixtures/hover_compatible.rpc.json
gen linux/arch/arm64/boot/dts/qcom/sm8550-qrd.dts    22:2  fixtures/hover_model.rpc.json
gen linux/arch/arm64/boot/dts/qcom/sm8550.dtsi        70:4  fixtures/hover_device_type.rpc.json
gen linux/arch/arm64/boot/dts/qcom/sm8550.dtsi       871:4  fixtures/hover_status.rpc.json
gen fixtures/hover_phandle.dts                         3:2  fixtures/hover_phandle.rpc.json
gen fixtures/hover_phandle.dts                         4:2  fixtures/hover_linux_phandle.rpc.json
gen linux/arch/arm64/boot/dts/qcom/sm8550.dtsi      2764:5  fixtures/hover_label.rpc.json
gen linux/arch/arm64/boot/dts/qcom/sm8550.dtsi        72:4  fixtures/hover_reg.rpc.json
gen linux/arch/arm64/boot/dts/qcom/sm8550.dtsi      1968:4  fixtures/hover_reg-names.rpc.json
gen linux/arch/arm64/boot/dts/qcom/sm8550.dtsi       481:3  fixtures/hover_ranges.rpc.json
gen linux/arch/arm64/boot/dts/qcom/sm8550.dtsi       821:3  fixtures/hover_dma-ranges.rpc.json
gen linux/arch/arm64/boot/dts/qcom/sm8550.dtsi       870:4  fixtures/hover_dma-coherent.rpc.json
gen linux/arch/arm64/boot/dts/qcom/sm8550.dtsi        32:2  fixtures/hover_address-cells.rpc.json
gen linux/arch/arm64/boot/dts/qcom/sm8550.dtsi        33:2  fixtures/hover_size-cells.rpc.json
gen linux/arch/arm64/boot/dts/qcom/sm8550.dtsi       402:3  fixtures/hover_interrupts.rpc.json
gen linux/arch/arm64/boot/dts/qcom/sm8550.dtsi       738:3  fixtures/hover_interrupts-extended.rpc.json
gen linux/arch/arm64/boot/dts/qcom/sm8550.dtsi        30:2  fixtures/hover_interrupt-parent.rpc.json
gen linux/arch/arm64/boot/dts/qcom/sm8550.dtsi       755:4  fixtures/hover_interrupt-cells.rpc.json
gen linux/arch/arm64/boot/dts/qcom/sm8550.dtsi       754:4  fixtures/hover_interrupt-controller.rpc.json
gen linux/arch/arm64/boot/dts/freescale/imx8mn-var-som.dtsi 92:3 fixtures/hover_wakeup-source.rpc.json
gen linux/arch/arm64/boot/dts/qcom/sm8550.dtsi        51:4  fixtures/hover_clocks.rpc.json
gen linux/arch/arm64/boot/dts/qcom/sm8550.dtsi       878:4  fixtures/hover_clock-names.rpc.json
gen linux/arch/arm64/boot/dts/qcom/sm8550.dtsi        40:4  fixtures/hover_clock-cells.rpc.json
gen linux/arch/arm64/boot/dts/qcom/sm8550.dtsi      3398:5  fixtures/hover_clock-frequency.rpc.json
gen linux/arch/arm64/boot/dts/freescale/fsl-ls1043a.dtsi 671:4 fixtures/hover_bus-frequency.rpc.json
gen linux/arch/powerpc/boot/dts/stxssa8555.dts        39:4  fixtures/hover_timebase-frequency.rpc.json
gen linux/arch/arm64/boot/dts/qcom/sm8550.dtsi      2031:4  fixtures/hover_resets.rpc.json
gen linux/arch/arm64/boot/dts/qcom/sm8550.dtsi      2032:4  fixtures/hover_reset-names.rpc.json
gen linux/arch/arm64/boot/dts/qcom/sm8550.dtsi       830:4  fixtures/hover_reset-cells.rpc.json
gen linux/arch/arm64/boot/dts/freescale/imx91-phycore-som.dtsi 44:4 fixtures/hover_gpios.rpc.json
gen linux/arch/arm64/boot/dts/qcom/sm8550.dtsi      3095:4  fixtures/hover_gpio-controller.rpc.json
gen linux/arch/arm64/boot/dts/qcom/sm8550.dtsi      3096:4  fixtures/hover_gpio-cells.rpc.json
gen linux/arch/arm64/boot/dts/qcom/sm8550.dtsi      3097:4  fixtures/hover_gpio-ranges.rpc.json
gen linux/arch/arm64/boot/dts/qcom/sm8550.dtsi       892:5  fixtures/hover_pinctrl-names.rpc.json
gen linux/arch/arm64/boot/dts/qcom/sm8550.dtsi       893:5  fixtures/hover_pinctrl-0.rpc.json
gen linux/arch/arm64/boot/dts/qcom/sm8550.dtsi      3390:4  fixtures/hover_pinctrl-1.rpc.json
gen linux/arch/arm64/boot/dts/qcom/sm8550.dtsi       904:5  fixtures/hover_dmas.rpc.json
gen linux/arch/arm64/boot/dts/qcom/sm8550.dtsi       906:5  fixtures/hover_dma-names.rpc.json
gen linux/arch/arm64/boot/dts/qcom/sm8550.dtsi       853:4  fixtures/hover_dma-cells.rpc.json
gen linux/arch/arm64/boot/dts/qcom/sm8550.dtsi        76:4  fixtures/hover_power-domains.rpc.json
gen linux/arch/arm64/boot/dts/qcom/sm8550.dtsi       869:4  fixtures/hover_iommus.rpc.json
gen linux/arch/arm64/boot/dts/freescale/fsl-ls1043a.dtsi 922:4 fixtures/hover_msi-parent.rpc.json
gen linux/arch/arm64/boot/dts/qcom/sm8550.dtsi      5324:5  fixtures/hover_msi-cells.rpc.json
gen linux/arch/arm64/boot/dts/cavium/thunder-88xx.dts 58:2  fixtures/hover_aliases.rpc.json
gen linux/arch/arm64/boot/dts/qcom/sm8550.dtsi        35:2  fixtures/hover_chosen.rpc.json
gen linux/arch/arm64/boot/dts/qcom/sm8550.dtsi       394:2  fixtures/hover_memory.rpc.json
gen linux/arch/xtensa/boot/dts/kc705.dts              16:2  fixtures/hover_reserved-memory.rpc.json
gen linux/arch/arm64/boot/dts/qcom/sm8550.dtsi        65:2  fixtures/hover_cpus.rpc.json
gen linux/arch/arm64/boot/dts/freescale/imx8mp-venice-gw74xx.dts 33:3 fixtures/hover_stdout-path.rpc.json
gen linux/arch/xtensa/boot/dts/csp.dts                11:3  fixtures/hover_bootargs.rpc.json
gen linux/arch/arm64/boot/dts/altera/socfpga_stratix10_swvp.dts 28:3 fixtures/hover_initrd-start.rpc.json
gen linux/arch/arm64/boot/dts/altera/socfpga_stratix10_swvp.dts 29:3 fixtures/hover_initrd-end.rpc.json
gen fixtures/hover_kaslr.dts                           4:3  fixtures/hover_kaslr-seed.rpc.json
gen linux/arch/arm64/boot/dts/qcom/sm8550.dtsi         1:1  fixtures/hover_null.rpc.json

echo "All fixtures regenerated."
