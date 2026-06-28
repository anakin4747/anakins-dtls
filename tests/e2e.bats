#!/usr/bin/env bats

source ./tests/lsts

lsts_set_cmd "anakins-dtls"
lsts_set_root "$(dirname "$BATS_TEST_FILENAME")"
lsts_set_langId "dts"

setup() {
    lsts_start
}

teardown() {
    lsts_stop
}

teardown_file() {
    lsts_check_no_snapshots
}

@test "initializes successfully" {
    lsts_initialize
}

@test "initialize advertises openClose textDocumentSync" {
    lsts_initialize_capability "textDocumentSync.openClose == true"
}

@test "initialize advertises full textDocumentSync change" {
    lsts_initialize_capability "textDocumentSync.change == 1"
}

@test "initialize advertises hoverProvider" {
    lsts_initialize_capability "hoverProvider == true"
}

@test "hover over compatible returns documentation" {
    lsts_hover \
        "linux/arch/arm64/boot/dts/qcom/sm8550.dtsi:39:4" \
        "fixtures/hover_compatible.rpc.json"
}

@test "hover over GIC_SPI returns macro definition" {
    lsts_hover \
        "linux/arch/arm64/boot/dts/qcom/sm8550.dtsi:845:18" \
        "fixtures/hover_macro_GIC_SPI.rpc.json"
}

@test "server survives unknown notification" {
    lsts_notify "textDocument/unknownMethod" '{"textDocument":{"uri":"file:///bad.dts"}}'
    lsts_hover \
        "linux/arch/arm64/boot/dts/qcom/sm8550.dtsi:39:4" \
        "fixtures/hover_compatible.rpc.json"
}

@test "server survives hover on unopened file" {
    lsts_hover \
        "linux/arch/arm64/boot/dts/qcom/sm8550.dtsi:39:4" \
        "fixtures/hover_compatible.rpc.json"
}

@test "server survives didOpen before hover" {
    lsts_open "fixtures/diag_valid.dts"
    lsts_hover \
        "linux/arch/arm64/boot/dts/qcom/sm8550.dtsi:39:4" \
        "fixtures/hover_compatible.rpc.json"
}

@test "initialize advertises definitionProvider" {
    lsts_initialize_capability "definitionProvider == true"
}

@test "definition on compatible value navigates to binding YAML" {
    lsts_definition \
        "linux/arch/arm64/boot/dts/qcom/sdm845.dtsi:1319:18" \
        "fixtures/definition_compatible_value.rpc.json"
}

@test "initialize advertises diagnosticProvider" {
    lsts_initialize_capability "diagnosticProvider == true"
}

@test "diagnostics reports missing semicolon" {
    lsts_diagnostics "fixtures/diag_missing_semicolon.dts" \
        "fixtures/diag_missing_semicolon.rpc.json"
}

@test "diagnostics on valid document reports no errors" {
    lsts_diagnostics_none "fixtures/diag_valid.dts"
}

@test "initialize advertises referencesProvider" {
    lsts_initialize_capability "referencesProvider == true"
}

@test "references for node label finds phandle usages" {
    lsts_references \
        "linux/arch/xtensa/boot/dts/xtfpga.dtsi:27:2" \
        true \
        "fixtures/references_label.rpc.json"
}

@test "completion in a node offers standard DT properties" {
    lsts_completion \
        "linux/arch/arm64/boot/dts/qcom/ipq5424.dtsi:520:5" \
        "fixtures/completion_uart.rpc.json"
}

@test "initialize advertises completionProvider" {
    lsts_initialize_capability "completionProvider == true"
}

@test "completion in a node with compatible offers binding properties" {
    lsts_completion \
        "linux/arch/arm64/boot/dts/qcom/ipq5424.dtsi:520:5" \
        "fixtures/completion_uart.rpc.json"
}

@test "initialize advertises documentSymbolProvider" {
    lsts_initialize_capability "documentSymbolProvider == true"
}

@test "document symbols returns node symbols" {
    lsts_document_symbols \
        "fixtures/symbols_basic.dts" \
        "fixtures/symbols_basic.rpc.json"
}

@test "document symbols includes labels" {
    lsts_document_symbols \
        "fixtures/symbols_labels.dts" \
        "fixtures/symbols_labels.rpc.json"
}

@test "initialize advertises renameProvider" {
    lsts_initialize_capability "renameProvider == true"
}

@test "rename label renames definition and references" {
    lsts_rename \
        "fixtures/rename_label.dts:4:2" \
        "irq_ctrl" \
        "fixtures/rename_label.rpc.json"
}

@test "initialize advertises implementationProvider" {
    lsts_initialize_capability "implementationProvider == true"
}

@test "implementation on compatible jumps to driver source" {
    lsts_implementation \
        "linux/arch/arm64/boot/dts/qcom/sm8550.dtsi:1188:18" \
        "fixtures/implementation_compatible.rpc.json"
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

@test "server responds when launched with set -e -u -o pipefail like writeShellApplication wrapper" {
    local server_src="$BATS_TEST_DIRNAME/../anakins-dtls"
    lsts_set_cmd "bash -c 'set -e -u -o pipefail; exec \"$server_src\"'"
    lsts_hover \
        "linux/arch/arm64/boot/dts/qcom/sm8550.dtsi:39:4" \
        "fixtures/hover_compatible.rpc.json"
    lsts_set_cmd "anakins-dtls"
}

@test "server exits cleanly with code 0 when stdin closes" {
    local server_src="$BATS_TEST_DIRNAME/../anakins-dtls"
    run bash -c "echo '' | bash '$server_src'; echo exit:\$?"
    [[ "$output" == *"exit:0"* ]]
}
