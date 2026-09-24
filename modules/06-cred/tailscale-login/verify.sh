#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"
usage() { printf '%s\n' 'Usage: ./verify.sh --target daily-host|agent-vm'; }
if cred_parse_target "$@"; then status=0; else status=$?; fi
if ((status == 10)); then usage; exit 0; fi
cred_handle_parse_result "$status" usage || exit "$?"
cred_require_target daily-host agent-vm || { usage >&2; exit 2; }
cred_require_user
cred_check 'Tailscale is on PATH' command -v tailscale
cred_check 'Tailscale is connected to a tailnet' bash -c 'tailscale status --json | tr -d "[:space:]" | grep -q "\"BackendState\":\"Running\""'
cred_finish_verify tailscale-login
