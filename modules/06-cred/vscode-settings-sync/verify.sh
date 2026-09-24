#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"
usage() { printf '%s\n' 'Usage: ./verify.sh --target daily-host --confirmed'; }
if cred_parse_target "$@"; then status=0; else status=$?; fi
if ((status == 10)); then usage; exit 0; fi
cred_handle_parse_result "$status" usage || exit "$?"
cred_require_target daily-host || { usage >&2; exit 2; }
cred_require_user
cred_check 'VS Code is on PATH' command -v code
cred_check 'managed VS Code settings are linked' bash -c '[[ -L "$1" && $(readlink -f -- "$1") == "$2" ]]' _ "$HOME/.config/Code/User/settings.json" "$HOME/projects/agent-box-setup/user-home/vscode/settings.json"
cred_check 'managed VS Code keybindings are linked' bash -c '[[ -L "$1" && $(readlink -f -- "$1") == "$2" ]]' _ "$HOME/.config/Code/User/keybindings.json" "$HOME/projects/agent-box-setup/user-home/vscode/keybindings.json"
cred_require_confirmation 'Settings Sync is on and the expected profile data has arrived'
cred_finish_verify vscode-settings-sync
