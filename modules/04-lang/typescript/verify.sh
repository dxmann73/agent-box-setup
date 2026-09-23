#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

usage() { printf '%s\n' 'Usage: ./verify.sh --target daily-host|agent-vm'; }
if lang_parse_target "$@"; then status=0; else status=$?; fi
if ((status == 10)); then usage; exit 0; fi
lang_handle_parse_result "$status" usage || exit "$?"
lang_require_target || { usage >&2; exit 2; }
lang_require_user
lang_check 'tsc is on PATH' command -v tsc
lang_check 'ts-node is on PATH' command -v ts-node
lang_check 'TypeScript reports its version' tsc --version
lang_check 'ts-node reports its version' ts-node --version
lang_check 'TypeScript packages are globally installed' npm ls -g --depth=0 typescript ts-node
lang_finish_verify typescript
