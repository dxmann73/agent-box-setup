#!/usr/bin/env bash
set -Eeuo pipefail
trap 'printf "ERROR: typescript apply failed at line %s\n" "$LINENO" >&2' ERR
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

usage() { printf '%s\n' 'Usage: ./apply.sh --target daily-host|agent-vm'; }
if lang_parse_target "$@"; then status=0; else status=$?; fi
if ((status == 10)); then usage; exit 0; fi
lang_handle_parse_result "$status" usage || exit "$?"
lang_require_target || { usage >&2; exit 2; }
lang_require_user
lang_npm_prefix_is_user_owned || {
    printf '%s\n' 'npm global prefix is not under $HOME. Apply node-24 first.' >&2
    exit 1
}
npm install -g typescript ts-node
printf 'typescript applied for %s.\n' "$lang_target"
