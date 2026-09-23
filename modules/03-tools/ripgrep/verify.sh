#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"
usage() { printf '%s\n' 'Usage: ./verify.sh --target daily-host|agent-vm'; }
search_works() { printf '%s\n' needle | rg -qx needle; }
if tool_parse_target "$@"; then status=0; else status=$?; fi
if ((status == 10)); then usage; exit 0; fi
tool_handle_parse_result "$status" usage || exit "$?"
tool_require_target || { usage >&2; exit 2; }
tool_check 'ripgrep package installed' tool_package_installed ripgrep
tool_check 'rg is on PATH' command -v rg
tool_check 'rg searches input' search_works
tool_finish_verify ripgrep
