#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"
usage() { printf '%s\n' 'Usage: ./verify.sh --target daily-host|agent-vm'; }
yaml_query_works() { printf '%s\n' 'answer: 42' | yq -r '.answer' | grep -qx 42; }
if tool_parse_target "$@"; then status=0; else status=$?; fi
if ((status == 10)); then usage; exit 0; fi
tool_handle_parse_result "$status" usage || exit "$?"
tool_require_target || { usage >&2; exit 2; }
tool_check 'yq package installed' tool_package_installed yq
tool_check 'yq is on PATH' command -v yq
tool_check 'yq transforms YAML' yaml_query_works
tool_finish_verify yq
