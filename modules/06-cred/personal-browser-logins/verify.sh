#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"
browser_command() { command -v google-chrome-stable || command -v google-chrome; }
usage() { printf '%s\n' 'Usage: ./verify.sh --target chrome-vm --confirmed'; }
if cred_parse_target "$@"; then status=0; else status=$?; fi
if ((status == 10)); then usage; exit 0; fi
cred_handle_parse_result "$status" usage || exit "$?"
cred_require_target chrome-vm || { usage >&2; exit 2; }
cred_require_user
cred_check 'Google Chrome is on PATH' browser_command
cred_check 'Chrome profile directory exists' test -d "$HOME/.config/google-chrome"
cred_require_confirmation 'the overlay account list has usable browser sessions'
cred_finish_verify personal-browser-logins
