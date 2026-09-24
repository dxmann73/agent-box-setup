#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"
dev_parse_target 'Usage: ./verify.sh --target daily-host' "$@"
dev_require_target daily-host
dev_require_user
grep -qxF 'URIs: https://packages.microsoft.com/repos/code' /etc/apt/sources.list.d/vscode.sources
dpkg-query -W -f='${Status}' code 2>/dev/null | grep -qx 'install ok installed'
command -v code >/dev/null && code --version >/dev/null
[[ -L $HOME/.config/Code/User/settings.json && $(readlink -f "$HOME/.config/Code/User/settings.json") == "$HOME/projects/agent-box-setup/user-home/vscode/settings.json" ]]
[[ -L $HOME/.config/Code/User/keybindings.json && $(readlink -f "$HOME/.config/Code/User/keybindings.json") == "$HOME/projects/agent-box-setup/user-home/vscode/keybindings.json" ]]
echo 'vscode verify passed'
