#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"
dev_parse_target 'Usage: sudo ./apply.sh --target daily-host' "$@"
dev_require_target daily-host
dev_require_sudo_user
home_dir=$(getent passwd "$SUDO_USER" | awk -F: 'NR == 1 { print $6 }')
[[ -n $home_dir && -d $home_dir ]] || { echo 'Could not resolve invoking user home.' >&2; exit 1; }
install -d -m 0755 /etc/apt/keyrings /etc/apt/sources.list.d
apt-get update && apt-get install -y wget gpg
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor --yes --output /etc/apt/keyrings/microsoft.gpg
printf '%s\n' 'Types: deb' 'URIs: https://packages.microsoft.com/repos/code' 'Suites: stable' 'Components: main' 'Architectures: amd64,arm64,armhf' 'Signed-By: /etc/apt/keyrings/microsoft.gpg' >/etc/apt/sources.list.d/vscode.sources
apt-get update && apt-get install -y code
install -d -o "$SUDO_USER" -g "$(id -gn "$SUDO_USER")" "$home_dir/.config/Code/User"
ln -sfn "$home_dir/projects/agent-box-setup/user-home/vscode/settings.json" "$home_dir/.config/Code/User/settings.json"
ln -sfn "$home_dir/projects/agent-box-setup/user-home/vscode/keybindings.json" "$home_dir/.config/Code/User/keybindings.json"
