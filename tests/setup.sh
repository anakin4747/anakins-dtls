#!/usr/bin/env bash
set -euo pipefail
TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"

sparse_clone() {
    local url="$1" dest="$2" commit="$3"
    shift 3
    local paths=("$@")
    if [[ -d "$dest/.git" ]]; then
        echo "setup: $dest already exists, skipping"
        return 0
    fi
    git clone --filter=blob:none --sparse --depth=1 --no-checkout "$url" "$dest"
    git -C "$dest" sparse-checkout set "${paths[@]}"
    git -C "$dest" checkout "$commit" 2>/dev/null || git -C "$dest" checkout HEAD
}

# Linux kernel — only the DTS paths used in tests + bindings + includes
sparse_clone \
    https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git \
    "$TESTS_DIR/linux" \
    "stable" \
    arch/arc/boot/dts \
    arch/arm/boot/dts/samsung \
    arch/arm64/boot/dts/altera \
    arch/arm64/boot/dts/amlogic \
    arch/arm64/boot/dts/broadcom \
    arch/arm64/boot/dts/broadcom/northstar2 \
    arch/arm64/boot/dts/cavium \
    arch/arm64/boot/dts/freescale \
    arch/arm64/boot/dts/qcom \
    arch/arm64/boot/dts/renesas \
    arch/powerpc/boot/dts \
    arch/xtensa/boot/dts \
    Documentation/devicetree/bindings \
    include/dt-bindings

# Device Tree Specification
sparse_clone \
    https://github.com/devicetree-org/devicetree-specification.git \
    "$TESTS_DIR/devicetree-specification" \
    "main" \
    source

# lsts
sparse_clone \
    https://github.com/anakin4747/lsts.git \
    "$TESTS_DIR/lsts" \
    "master" \
    .

# U-Boot — only arm/dts
sparse_clone \
    https://github.com/u-boot/u-boot.git \
    "$TESTS_DIR/u-boot" \
    "master" \
    arch/arm/dts

# Zephyr — only the board used in tests
sparse_clone \
    https://github.com/zephyrproject-rtos/zephyr.git \
    "$TESTS_DIR/zephyr" \
    "main" \
    boards/ronoth/lodev
