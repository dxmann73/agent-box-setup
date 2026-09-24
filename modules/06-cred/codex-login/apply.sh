#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"
usage() { printf '%s\n' 'Usage: ./apply.sh --target daily-host|agent-vm [--device-auth]'; }
device_auth=0
args=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --device-auth)
            ((device_auth == 0)) || { printf '%s\n' 'Use --device-auth at most once.' >&2; exit 2; }
            device_auth=1
            shift
            ;;
        *)
            args+=("$1")
            shift
            ;;
    esac
done
if cred_parse_target "${args[@]}"; then status=0; else status=$?; fi
if ((status == 10)); then usage; exit 0; fi
cred_handle_parse_result "$status" usage || exit "$?"
cred_require_target daily-host agent-vm || { usage >&2; exit 2; }
cred_require_user
if ((device_auth == 1)); then exec codex login --device-auth; fi
exec codex login
