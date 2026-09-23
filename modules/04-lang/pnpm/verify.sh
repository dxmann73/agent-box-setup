#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

usage() { printf '%s\n' 'Usage: ./verify.sh --target daily-host|agent-vm'; }
if lang_parse_target "$@"; then status=0; else status=$?; fi
if ((status == 10)); then usage; exit 0; fi
lang_handle_parse_result "$status" usage || exit "$?"
lang_require_target || { usage >&2; exit 2; }
lang_require_user
lang_check 'pnpm is on PATH' command -v pnpm
lang_check 'pnpm reports its version' pnpm --version
lang_check 'pnpm is globally installed' npm ls -g --depth=0 pnpm
lang_finish_verify pnpm
