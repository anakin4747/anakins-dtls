#!/usr/bin/env bash
# Generate a hover fixture by querying the language server.
# Usage: gen_fixture.sh <dts-file-relative-to-tests/> <line:col> <output-relative-to-tests/>
set -o errexit
set -o nounset
set -o pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TESTS="$ROOT/tests"
SERVER="$ROOT/anakins-dtls"

FILE="$1"
LINECOLON="$2"
OUT="$TESTS/$3"

RAW_LINE="${LINECOLON%%:*}"
RAW_COL="${LINECOLON##*:}"
LSP_LINE=$(( RAW_LINE - 1 ))
LSP_COL=$(( RAW_COL - 1 ))

URI="file://$TESTS/$FILE"
TEXT_JSON="$(jq -Rs . < "$TESTS/$FILE")"

send2() {
    local body="$1" len
    len="$(printf '%s' "$body" | wc -c)"
    printf "Content-Length: %d\r\n\r\n%s" "$len" "$body" >&"$WRITE_FD"
}

recv2() {
    local line cl=0
    while IFS= read -r -t 5 line <&"$READ_FD"; do
        line="${line%$'\r'}"
        [[ -z "$line" ]] && break
        [[ "$line" =~ ^Content-Length:\ ([0-9]+)$ ]] && cl="${BASH_REMATCH[1]}"
    done
    [[ "$cl" -eq 0 ]] && return 1
    IFS= read -r -N "$cl" -t 5 BODY <&"$READ_FD"
}

# recv_response: skip notifications (messages with "method" but no "id"),
# keep reading until we get a response (has "id", no "method").
recv_response() {
    local deadline=$(( SECONDS + 10 ))
    while (( SECONDS < deadline )); do
        recv2 || return 1
        # Skip if it looks like a notification (has "method" key)
        if printf '%s' "$BODY" | jq -e 'has("method")' >/dev/null 2>&1; then
            continue
        fi
        return 0
    done
    echo 'recv_response: timed out' >&2
    return 1
}

coproc SRV { "$SERVER"; }
exec {WRITE_FD}>&"${SRV[1]}"
exec {READ_FD}<&"${SRV[0]}"

send2 "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"initialize\",\"params\":{\"processId\":null,\"rootUri\":\"file://$TESTS\",\"capabilities\":{}}}"
recv2

send2 "{\"jsonrpc\":\"2.0\",\"method\":\"initialized\",\"params\":{}}"

send2 "{\"jsonrpc\":\"2.0\",\"method\":\"textDocument/didOpen\",\"params\":{\"textDocument\":{\"uri\":\"${URI}\",\"languageId\":\"dts\",\"version\":1,\"text\":${TEXT_JSON}}}}"

send2 "{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"textDocument/hover\",\"params\":{\"textDocument\":{\"uri\":\"${URI}\"},\"position\":{\"line\":${LSP_LINE},\"character\":${LSP_COL}}}}"
recv_response

printf '%s' "$BODY" | jq -c . > "$OUT"

send2 "{\"jsonrpc\":\"2.0\",\"method\":\"exit\",\"params\":null}"
kill "${SRV_PID:-}" 2>/dev/null || true
