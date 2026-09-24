#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"
usage() { printf '%s\n' 'Usage: ./verify.sh --target daily-host|agent-vm'; }
if cred_parse_target "$@"; then status=0; else status=$?; fi
if ((status == 10)); then usage; exit 0; fi
cred_handle_parse_result "$status" usage || exit "$?"
cred_require_target daily-host agent-vm || { usage >&2; exit 2; }
cred_require_user
repo_root="$(cred_repo_root)"
secrets_file="$repo_root/user-home/.bash_secrets"
cred_check 'Firecrawl is on PATH' command -v firecrawl
cred_check 'Firecrawl is authenticated' bash -c 'firecrawl --status | grep -qi "Authenticated via"'
cred_check 'secrets file is linked into the home directory' bash -c '[[ -L "$1" && $(readlink -f -- "$1") == "$2" ]]' _ "$HOME/.bash_secrets" "$secrets_file"
cred_check 'secrets file has owner-only permissions' bash -c '[[ $(stat -c %a "$1") == 600 ]]' _ "$secrets_file"
cred_check 'FIRECRAWL_API_KEY is populated, not a placeholder' bash -c 'grep -Eq "^export FIRECRAWL_API_KEY=.+$" "$1" && ! grep -Fqx "export FIRECRAWL_API_KEY=fc-YOUR-API-KEY" "$1"' _ "$secrets_file"
cred_finish_verify firecrawl-login
