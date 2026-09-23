#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

usage() { printf '%s\n' 'Usage: ./verify.sh --target daily-host|agent-vm'; }
if lang_parse_target "$@"; then status=0; else status=$?; fi
if ((status == 10)); then usage; exit 0; fi
lang_handle_parse_result "$status" usage || exit "$?"
lang_require_target || { usage >&2; exit 2; }
lang_require_user

nodesource_source_configured() {
    grep -Eq '^deb \[arch=[^ ]+ signed-by=/etc/apt/keyrings/nodesource\.gpg\] https://deb\.nodesource\.com/node_24\.x nodistro main$' \
        /etc/apt/sources.list.d/nodesource.list
}
lang_check 'nodejs package installed' lang_package_installed nodejs
lang_check 'node is on PATH' command -v node
lang_check 'npm is on PATH' command -v npm
lang_check 'Node.js 24 active' bash -c 'node --version | grep -Eq "^v24\\."'
lang_check 'NodeSource apt source configured' nodesource_source_configured
lang_check 'npm global prefix is user-owned' lang_npm_prefix_is_user_owned
lang_check 'npm global root is user-owned' bash -c '[[ "$(npm root -g)" == "$HOME"/* ]]'
lang_finish_verify node-24
