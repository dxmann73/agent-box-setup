#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"
usage() { printf '%s\n' 'Usage: ./verify.sh --target daily-host|agent-vm'; }
find_works() {
    local temporary
    local status
    temporary="$(mktemp -d)"
    if touch "$temporary/needle" && fdfind -a -p needle "$temporary" | grep -qx "$temporary/needle"; then
        status=0
    else
        status=1
    fi
    rm -rf -- "$temporary"
    return "$status"
}
if tool_parse_target "$@"; then status=0; else status=$?; fi
if ((status == 10)); then usage; exit 0; fi
tool_handle_parse_result "$status" usage || exit "$?"
tool_require_target || { usage >&2; exit 2; }
tool_check 'fd-find package installed' tool_package_installed fd-find
tool_check 'fdfind is on PATH' command -v fdfind
tool_check 'fdfind locates a file' find_works
tool_finish_verify fd-find
