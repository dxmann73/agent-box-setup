#!/usr/bin/env bash
set -Eeuo pipefail
trap 'printf "ERROR: jq apply failed at line %s\n" "$LINENO" >&2' ERR
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"
usage() { printf '%s\n' 'Usage: sudo ./apply.sh --target daily-host|agent-vm'; }
if tool_parse_target "$@"; then status=0; else status=$?; fi
if ((status == 10)); then usage; exit 0; fi
tool_handle_parse_result "$status" usage || exit "$?"
tool_require_target || { usage >&2; exit 2; }
tool_require_root
tool_install_package jq
printf 'jq applied for %s.\n' "$tool_target"
