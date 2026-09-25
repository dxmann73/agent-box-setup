#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"
usage() { printf '%s\n' 'Usage: ./verify.sh --target daily-host|agent-vm'; }
if cred_parse_target "$@"; then status=0; else status=$?; fi
if ((status == 10)); then usage; exit 0; fi
cred_handle_parse_result "$status" usage || exit "$?"
cred_require_target daily-host agent-vm || { usage >&2; exit 2; }
cred_require_user
firecrawl_status_authenticated() {
    firecrawl --status 2>&1 |
        sed -E $'s/\x1B\\[[0-9;]*[[:alpha:]]//g' |
        grep -Eqi 'Authenticated[[:space:]]+via'
}

cred_check 'Firecrawl is on PATH' command -v firecrawl
cred_check 'Firecrawl home credentials authenticate the CLI' firecrawl_status_authenticated
cred_finish_verify firecrawl-login
