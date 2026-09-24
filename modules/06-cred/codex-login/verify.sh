#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"
usage() { printf '%s\n' 'Usage: ./verify.sh --target daily-host|agent-vm'; }
if cred_parse_target "$@"; then status=0; else status=$?; fi
if ((status == 10)); then usage; exit 0; fi
cred_handle_parse_result "$status" usage || exit "$?"
cred_require_target daily-host agent-vm || { usage >&2; exit 2; }
cred_require_user
cred_check 'Codex is on PATH' command -v codex
cred_check 'Codex is authenticated' codex login status
cred_finish_verify codex-login
